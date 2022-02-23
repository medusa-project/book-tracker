class Book < ApplicationRecord

  COLUMNS = %w(author bib_id created_at date exists_in_hathitrust
               exists_in_internet_archive exists_in_google hathitrust_access
               ia_identifier hathitrust_rights language obj_id oclc_number
               raw_marcxml source_path subject title updated_at volume)
  CSV_HEADER = ['Bib ID', 'Medusa ID', 'OCLC Number', 'Object ID', 'Title',
                'Author', 'Volume', 'Date', 'IA Identifier',
                'HathiTrust Handle', 'Exists in HathiTrust', 'Exists in IA',
                'Exists in Google']
  MAX_STRING_LENGTH = 256
  SUBJECT_DELIMITER = '||'

  attr_accessor :url
  before_save :truncate_values

  ##
  # Sends a VACUUM ANALYZE command to the books table, helpful for keeping
  # queries responsive after a lot of UPDATEs.
  #
  def self.analyze_table
    ActiveRecord::Base.connection.execute('VACUUM ANALYZE books;')
  end

  ##
  # Returns an estimated count of all rows in the books table. Much faster than
  # a COUNT query with no WHERE clause.
  #
  # @return [Integer]
  #
  def self.approximate_count
    Book.connection.exec_query('SELECT reltuples::bigint AS count '\
                               'FROM pg_class '\
                               'WHERE relname = \'books\';')[0]['count']
  end

  ##
  # Updates a batch of books in one SQL statement. This may be faster (due to
  # the table indexes) than loading and saving a bunch of Book objects.
  #
  # @param batch [Set<Object>] Set of strings or integers.
  # @param column [String] Column to update.
  # @param new_value [Object] Value to set the column to.
  # @param where_column [String] WHERE column.
  # @return [void]
  #
  def self.bulk_update(batch, column, new_value, where_column)
    length = batch.length
    return unless length > 0

    sql = StringIO.new
    sql << sprintf('UPDATE books SET %s = %s WHERE %s IN (',
                   column, new_value, where_column)
    length.times do |index|
      sql << "$#{index + 1}"
      if index < length - 1
        sql << ', '
      end
    end
    sql << ');'

    binds = batch

    Rails.logger.debug("Book.bulk_update(): updating #{batch.length} records")
    ActiveRecord::Base.connection.exec_query(sql.string, 'SQL', binds, prepare: true)
  rescue => e
    Rails.logger.error("Book.bulk_update(): #{e}\nSQL: #{sql.string}")
    raise e
  end

  ##
  # Inserts or updates a batch of books in one SQL statement. This may be
  # faster (due to the table indexes) than using one statement per book.
  #
  # @param rows [Enumerable<Hash<Symbol,Object>>] Enumerable of hashes with book
  #             table column names as keys.
  # @return [void]
  #
  def self.bulk_upsert(rows)
    # Duplicate object IDs will be refused due to the unique index on obj_id.
    rows.uniq!{ |r| r[:obj_id] }
    return if rows.empty?

    sql = StringIO.new

    sql << 'INSERT INTO books('
    sql << COLUMNS.join(', ')
    sql << ') VALUES '

    value_index = 0
    rows.length.times do |index|
      sql << "\n\t("
      sql << COLUMNS.map{ |c| "$#{value_index += 1}" }.join(', ')
      sql << ')'
      sql << ',' if index < rows.length - 1
    end

    not_null_bool_cols = %w(exists_in_google
        exists_in_hathitrust exists_in_internet_archive)

    binds = []
    rows.each do |row|
      row[:created_at] = 'NOW()'
      row[:updated_at] = 'NOW()'
      COLUMNS.each do |col|
        value = row[col.to_sym]
        if value.blank?
          value = not_null_bool_cols.include?(col) ? false : nil
        end
        binds << value
      end
    end

    sql << "\nON CONFLICT (obj_id) DO\n"
    sql << "UPDATE SET\n\t"
    cols = COLUMNS.reject{ |c| %w(created_at exists_in_hathitrust
        exists_in_internet_archive exists_in_google hathitrust_access).include?(c) }
    cols.each_with_index do |col, index|
      sql << col
      sql << ' = EXCLUDED.'
      sql << col
      sql << ', ' if index < cols.length - 1
    end
    sql << ';'
    begin
      ActiveRecord::Base.connection.exec_query(sql.string, 'SQL', binds, prepare: true)
    rescue => e
      Rails.logger.error("Book.bulk_upsert(): #{e}\nSQL: #{sql.string}")
      raise e
    end
  end

  ##
  # @param record Nokogiri element corresponding to a /collection/record
  #               element in a MARCXML file.
  # @param key [String] Object key of the MARCXML file.
  # @return [Hash] Params hash for a Book.
  #
  def self.params_from_marcxml_record(key, record)
    namespaces = { 'marc' => 'http://www.loc.gov/MARC21/slim' }
    book_params = {
        source_path: key
    }

    # raw MARCXML
    book_params[:raw_marcxml] = record.to_xml(indent: 4)

    # extract bib ID
    nodes = record.xpath('marc:controlfield[@tag = 001]', namespaces)
    book_params[:bib_id] = nodes.first.content.gsub(/[^0-9]/, '') if nodes.any?

    # extract OCLC no. from 035 subfield a
    nodes = record.
        xpath('marc:datafield[@tag = 035][1]/marc:subfield[@code = \'a\']', namespaces)
    book_params[:oclc_number] = nodes.first.content.gsub(/[^0-9]/, '') if nodes.any?

    # extract author & title from 100 & 245 subfields a & b
    book_params[:author] = record.
        xpath('marc:datafield[@tag = 100][1]/marc:subfield', namespaces).
        map(&:content).join(' ').strip
    book_params[:title] = record.
        xpath('marc:datafield[@tag = 245][1]/marc:subfield[@code = \'a\' or @code = \'b\']', namespaces).
        map(&:content).join(' ').strip

    # extract language from 008
    nodes = record.xpath('marc:controlfield[@tag = 008][1]', namespaces)
    book_params[:language] = nodes.first.content[35..37] if nodes.any?

    # extract subject from 650 subfield a
    # N.B.: books may have more than one subject; in this case the subjects
    # are combined into one value separated by SUBJECT_DELIMITER, to avoid
    # the unnecessary complexity of another table.
    nodes = record.xpath('marc:datafield[@tag = 650]/marc:subfield[@code = \'a\']', namespaces)
    book_params[:subject] = nodes.map(&:content).join(SUBJECT_DELIMITER)

    # extract volume from 955 subfield v
    nodes = record.xpath('marc:datafield[@tag = 955][1]/marc:subfield[@code = \'v\']', namespaces)
    book_params[:volume] = nodes.first.content.strip if nodes.any?

    # extract date from 260 subfield c
    nodes = record.
        xpath('marc:datafield[@tag = 260][1]/marc:subfield[@code = \'c\']', namespaces)
    book_params[:date] = nodes.first.content.strip if nodes.any?

    # extract object ID from 955 subfield b
    # For Google digitized volumes, this will be the barcode.
    # For Internet Archive digitized volumes, this will be the Ark ID.
    # For locally digitized volumes, this will be the bib ID (and other extensions)
    nodes = record.
        xpath('marc:datafield[@tag = 955]/marc:subfield[@code = \'b\']', namespaces)
    # strip leading "uiuc."
    book_params[:obj_id] = nodes.first.content.gsub(/^uiuc./, '').strip if nodes.any?

    # extract IA identifier from 955 subfield q
    nodes = record.
        xpath('marc:datafield[@tag = 955]/marc:subfield[@code = \'q\']', namespaces)
    book_params[:ia_identifier] = nodes.first.content.strip if nodes.any?

    book_params
  end

  def as_json(options = { })
    {
        id: self.id,
        bib_id: self.bib_id,
        oclc_number: self.oclc_number,
        obj_id: self.obj_id,
        title: self.title,
        volume: self.volume,
        author: self.author,
        language: self.language,
        subjects: self.subject&.split(SUBJECT_DELIMITER),
        date: self.date,
        url: self.url,
        catalog_url: self.uiuc_catalog_url,
        hathitrust_url: self.exists_in_hathitrust ?
                            self.hathitrust_handle : nil,
        hathitrust_rights: self.hathitrust_rights,
        hathitrust_access: self.hathitrust_access,
        internet_archive_identifier: self.ia_identifier,
        internet_archive_url: self.exists_in_internet_archive ?
                                  self.internet_archive_url : nil,
        created_at: self.created_at,
        updated_at: self.updated_at
    }
  end

  ##
  # @return [String] If self.exists_in_hathitrust is true, the expected
  #                  HathiTrust handle of the book. Otherwise, an empty
  #                  string.
  #
  def hathitrust_handle
    handle = ''
    if self.exists_in_hathitrust
      case self.service
      when Service::INTERNET_ARCHIVE
        handle = "https://hdl.handle.net/2027/uiuo.#{self.obj_id}"
      when Service::GOOGLE
        handle = "https://hdl.handle.net/2027/uiug.#{self.obj_id}"
      else # digitized locally or by vendors
        handle = "https://hdl.handle.net/2027/uiuc.#{self.obj_id}"
      end
    end
    handle
  end

  ##
  # @return [String] The expected Internet Archive URL of the book. The URL
  #                  should resolve if self.exists_in_internet_archive is
  #                  true; otherwise it will be broken.
  #
  def internet_archive_url
    "https://archive.org/details/#{self.ia_identifier}"
  end

  def service
    if self.obj_id.start_with?('ark:/')
      Service::INTERNET_ARCHIVE
    elsif self.obj_id.length == 14 and self.obj_id[0] == '3'
      # If the object ID is a barcode, it's a Google record. Barcodes are 14
      # digits and start with number 3.
      Service::GOOGLE
    end
  end

  def to_csv(options = {})
    CSV.generate(options) do |csv|
      # N.B.: columns must be kept in sync with CSV_HEADER
      csv << [ self.bib_id, self.id, self.oclc_number, self.obj_id,
               self.title, self.author, self.volume, self.date,
               self.ia_identifier, self.hathitrust_handle,
               self.exists_in_hathitrust, self.exists_in_internet_archive,
               self.exists_in_google]
    end
  end

  ##
  # @return [String, nil] URL of the instance in the library's OPAC. Will be
  #                       nil if the instance's bib ID is nil.
  #
  def uiuc_catalog_url
    # See https://bugs.library.illinois.edu/browse/DLD-342
    #
    # N.B.: "The bib IDs currently in the digital library will have to have 99
    # added to the beginning and 12205899 added to the end to create the mms
    # id, however it's likely that eventually new items will have the mms id
    # instead of a bib id from voyager, so to get around that you could first
    # check to see if the bib ID has 99 at the beginning and 5899 at the end of
    # the id."
    #
    # N.B. 2: this method is cribbed from Kumquat's Item.catalog_record_url()
    # method, and their behaviors should be kept in sync.
    bibid = self.bib_id.to_s
    if bibid.present?
      base_url = 'https://i-share-uiu.primo.exlibrisgroup.com/permalink/01CARLI_UIU/gpjosq/alma'
      prefix   = '99'
      suffix   = '12205899'
      return [base_url,
              bibid.start_with?(prefix) ? '' : prefix,
              bibid,
              bibid.end_with?(suffix) ? '' : suffix].join
    end
    nil
  end


  private

  def truncate_values
    self.author = self.author[0..MAX_STRING_LENGTH] if self.author.present?
    self.date = self.date[0..MAX_STRING_LENGTH] if self.date.present?
    self.title = self.title[0..MAX_STRING_LENGTH] if self.title.present?
    self.volume = self.volume[0..MAX_STRING_LENGTH] if self.volume.present?
  end

end
