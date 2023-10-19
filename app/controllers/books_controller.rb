class BooksController < ApplicationController

  WINDOW_SIZE = 500

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
        local_storage:    Task.where(service: Service::LOCAL_STORAGE)
                              .where(status: Task::Status::SUCCEEDED).last,
        hathitrust:       Task.where(service: Service::HATHITRUST)
                              .where(status: Task::Status::SUCCEEDED).last,
        internet_archive: Task.where(service: Service::INTERNET_ARCHIVE)
                              .where(status: Task::Status::SUCCEEDED).last,
        google:           Task.where(service: Service::GOOGLE)
                              .where(status: Task::Status::SUCCEEDED).last
    }
    @dates.each{ |k, v| @dates[k] = v&.completed_at }

    any_filters = false

    # query (q=)
    query = @allowed_params[:q]
    if query.present?
      any_filters = true
      lines = query.strip.split("\n")
      # If >1 line, assume a list of bib and/or object IDs.
      if lines.length > 1
        bib_ids    = lines.map(&:strip).select{ |id| id.length < 8 }
        object_ids = lines.map{ |x| x.strip[0..20] }.select{ |id| id.length > 8 }

        @books = @books.where('bib_id IN (?) OR obj_id IN (?)',
                              bib_ids, object_ids)
        # Compile a list of entered IDs for which books were not found.
        if bib_ids.any?
          sql = "SELECT * FROM "\
            "(values #{bib_ids.map{ |id| "(#{id})" }.join(',')}) as T(ID) "\
            "EXCEPT "\
            "SELECT bib_id "\
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
        q = query.strip
        qi = q.to_i
        if q == qi.to_s and qi < 2**31 # if the query is an integer
          @books = @books.where('bib_id = ? OR obj_id = ?', q, q)
        elsif q == qi.to_s # if the query is a non-integer number
          @books = @books.where('obj_id = ?', q)
        else
          q = "%#{query.strip}%"
          @books = @books.where('CAST(bib_id AS VARCHAR(10)) LIKE ? '\
          'OR oclc_number LIKE ? OR obj_id LIKE ? OR LOWER(title) LIKE LOWER(?) '\
          'OR LOWER(author) LIKE LOWER(?) OR LOWER(ia_identifier) LIKE LOWER(?)' \
          'OR LOWER(date) LIKE LOWER(?)', q, q, q, q, q, q, q)
        end
      end
    end

    # in/not-in service (in[]=, ni[]=)
    # These are used by checkboxes in the books UI.
    if @allowed_params[:in].respond_to?(:each) and
        @allowed_params[:ni].respond_to?(:each) and
        (@allowed_params[:in] & @allowed_params[:ni]).any?
      flash['error'] = 'Cannot search for books that are both in and not in '\
          'the same service.'
    else
      # N.B.: the order of these WHERE conditions are aligned with the compound
      # index on these three columns in the database.
      if @allowed_params[:in].respond_to?(:each)
        any_filters = true
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
        any_filters = true
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

    # Harvest mode (?harvest=true) is used by the harvester
    # (https://github.com/medusa-project/metaslurper).
    # It uses a query that the web UI can't generate.
    if @allowed_params[:harvest] == 'true'
      any_filters = true
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

    # We have had an issue with slow COUNT queries in AWS RDS. If there are no
    # filters, we can use PG's estimated count instead.
    if any_filters
      @count = @books.count
      @count_is_approximate = false
    else
      @count = Book.approximate_count
      @count_is_approximate = true
    end

    offset = (page - 1) * WINDOW_SIZE

    if request.xhr?
      @books = @books.offset(offset).limit(WINDOW_SIZE)
      render partial: 'book_rows', locals: { books: @books,
                                             next_page_url: @next_page_url }
    else
      respond_to do |format|
        format.html do
          @books = @books.offset(offset).limit(WINDOW_SIZE)
        end
        format.json do
          @books = @books.offset(offset).limit(WINDOW_SIZE)
          @books.each{ |book| book.url = url_for(book) }
          render json: {
              numResults: @count,
              windowOffset: offset,
              windowSize: WINDOW_SIZE,
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
          # Using Enumerator as a response body makes Rails expect the object to respond to .each and for some reason it wasn't doing that
          # so instead use traditional response headers so Rails can directly stream the response
          response.headers['Content-Type'] = 'application/xml'
          response.headers['Content-Disposition'] = 'attachment; filename=items.xml'

          xml_data = ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<export>"]

          Book.uncached do
            @books.find_each { |book| xml_data << book.raw_marcxml }
          end
          
          xml_data << '</export>'

          render xml: xml_data.join("\n")
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

end
