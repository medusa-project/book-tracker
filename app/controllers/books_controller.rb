class BooksController < ApplicationController

  RESULTS_LIMIT = 100

  protect_from_forgery except: :index

  before_action :setup

  def setup
    @allowed_params = params.permit(:action, :controller, :format, :harvest,
                                    :ht, :ia, :id, :last_modified_after,
                                    :last_modified_before, :page, :q,
                                    in: [], ni: [])
  end

  ##
  # Responds to both GET /books (and also POST due to search form's ability to
  # accept long lists of bib IDs).
  #
  def index
    @books = Book.all
    @missing_ids = []

    @dates = {
        local_storage: Task.where(service: Service::LOCAL_STORAGE).
            where(status: Status::SUCCEEDED).last,
        hathitrust: Task.where(service: Service::HATHITRUST).
            where(status: Status::SUCCEEDED).last,
        internet_archive: Task.where(service: Service::INTERNET_ARCHIVE).
            where(status: Status::SUCCEEDED).last,
        google: Task.where(service: Service::GOOGLE).
            where(status: Status::SUCCEEDED).last
    }
    @dates.each{ |k, v| @dates[k] = v ? v.completed_at.strftime('%Y-%m-%d') : 'Never' }

    # query (q=)
    query = @allowed_params[:q]
    if query.present?
      lines = query.strip.split("\n")
      # If >1 line, assume a list of bib and/or object IDs.
      if lines.length > 1
        bib_ids = lines.select{ |id| id.length < 8 }.map{ |x| x.strip }
        object_ids = lines.select{ |id| id.length > 8 }.map{ |x| x.strip[0..20] }

        @books = @books.where('bib_id::char IN (?) OR obj_id IN (?)',
                              bib_ids, object_ids)
        # Compile a list of entered IDs for which books were not found.
        if bib_ids.any?
          sql = "SELECT * FROM "\
            "(values #{bib_ids.map{ |id| "('#{id}')" }.join(',')}) as T(ID) "\
            "EXCEPT "\
            "SELECT bib_id::char "\
            "FROM books;"
          @missing_ids += ActiveRecord::Base.connection.execute(sql).map{ |r| r['id'] }
        end
        if object_ids.any?
          sql = "SELECT * FROM "\
            "(values #{object_ids.map{ |id| "('#{id}')" }.join(',')}) as T(ID) "\
            "EXCEPT "\
            "SELECT obj_id "\
            "FROM books;"
          @missing_ids += ActiveRecord::Base.connection.execute(sql).map{ |r| r['id'] }
        end
      else
        q = "%#{query.strip}%"
        @books = @books.where('CAST(bib_id AS VARCHAR(10)) LIKE ? '\
        'OR oclc_number LIKE ? OR obj_id LIKE ? OR LOWER(title) LIKE LOWER(?) '\
        'OR LOWER(author) LIKE LOWER(?) OR LOWER(ia_identifier) LIKE LOWER(?)' \
        'OR LOWER(date) LIKE LOWER(?)', q, q, q, q, q, q, q)
      end
    end

    # in/not-in service (in[]=, ni[]=)
    # These are used by checkboxes in the books UI.
    if @allowed_params[:in].respond_to?(:each) and
        @allowed_params[:ni].respond_to?(:each) and
        (@allowed_params[:in] & @allowed_params[:ni]).length > 0
      flash['error'] = 'Cannot search for books that are both in and not in '\
          'the same service.'
    else
      if @allowed_params[:in].respond_to?(:each)
        @allowed_params[:in].each do |service|
          case service
            when 'ht'
              @books = @books.where(exists_in_hathitrust: true)
            when 'ia'
              @books = @books.where(exists_in_internet_archive: true)
            when 'gb'
              @books = @books.where(exists_in_google: true)
          end
        end
      end
      if @allowed_params[:ni].respond_to?(:each)
        @allowed_params[:ni].each do |service|
          case service
            when 'ht'
              @books = @books.where(exists_in_hathitrust: false)
            when 'ia'
              @books = @books.where(exists_in_internet_archive: false)
            when 'gb'
              @books = @books.where(exists_in_google: false)
          end
        end
      end

      @books = @books.order(:title)
    end

    # Harvest mode (harvest=true) uses a query that the web UI can't generate.
    if @allowed_params[:harvest] == 'true'
      # Exclude Hathitrust-restricted books (DLDS-70)
      @books = @books.where('hathitrust_access != ?', 'deny')

      # Include only books that don't solely exist, or don't exist at all,
      # in Google, due to difficulty in linking to them.
      @books = @books.where('exists_in_google = ? OR exists_in_hathitrust = ? OR exists_in_internet_archive = ?',
                            false, true, true)

      if @allowed_params[:last_modified_after].present? # epoch seconds
        @books = @books.where('updated_at >= ?',
                              Time.at(@allowed_params[:last_modified_after].to_i))
      end
      if @allowed_params[:last_modified_before].present? # epoch seconds
        @books = @books.where('updated_at <= ?',
                              Time.at(@allowed_params[:last_modified_before].to_i))
      end
    end

    page = @allowed_params[:page].to_i
    page = 1 if page < 1
    next_page = page + 1
    # TODO: set this to nil if there is no next page
    @allowed_params.permit!
    @next_page_url = books_path(@allowed_params.merge(page: next_page))

    if request.xhr?
      @books = @books.paginate(page: page, per_page: RESULTS_LIMIT)
      render partial: 'book_rows', locals: { books: @books,
                                             next_page_url: @next_page_url }
    else
      respond_to do |format|
        format.html do
          @books = @books.paginate(page: page, per_page: RESULTS_LIMIT)
        end
        format.json do
          @books = @books.paginate(page: page, per_page: RESULTS_LIMIT)
          @books.each{ |book| book.url = url_for(book) }
          render json: {
              numResults: @books.total_entries,
              windowSize: RESULTS_LIMIT,
              windowOffset: (page - 1) * RESULTS_LIMIT,
              results: @books
          }, except: :raw_marcxml
        end
        format.csv do
          # Use Enumerator in conjunction with some custom headers to
          # stream the results, as an alternative to send_data
          # which would require them to be loaded into memory first.
          enumerator = Enumerator.new do |y|
            y << Book::CSV_HEADER.to_csv
            # Book.uncached disables ActiveRecord caching that would prevent
            # previous find_each batches from being garbage-collected.
            Book.uncached { @books.find_each { |book| y << book.to_csv } }
          end
          stream(enumerator, 'items.csv', 'text/csv')
        end
        format.xml do
          enumerator = Enumerator.new do |y|
            y << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<export>\n"
            Book.uncached do
              @books.find_each { |book| y << book.raw_marcxml + "\n" }
            end
            y << '</export>'
          end
          stream(enumerator, 'items.xml', 'application/xml')
        end
      end
    end
  end

  def show
    @book = Book.find(params[:id])
    @book.url = url_for(@book)
    respond_to do |format|
      format.html
      format.json { render json: @book }
    end
  end

  private

  ##
  # Sends an Enumerable in chunks as an attachment. Streaming requires a
  # web server capable of it (not WEBrick or Thin).
  #
  def stream(enumerable, filename, content_type)
    self.response.headers['X-Accel-Buffering'] = 'no'
    self.response.headers['Cache-Control'] ||= 'no-cache'
    self.response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
    self.response.headers['Content-Type'] = content_type
    self.response.headers.delete('Content-Length')
    self.response_body = enumerable
  end

end
