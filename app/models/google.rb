##
# Checks Google Books for bibliographic data using Google GRIN, and updates the
# corresponding local books with its findings.
#
# Access to GRIN is restricted to particular Google accounts. If a request to
# https://books.google.com/libraries/UIUC/ returns HTTP 403, contact Jon
# Gorman (jtgorman@illinois.edu) in Library IT to request access.
#
class Google
  include Syncable

  TASK_UPDATE_INTERVAL = 1000
  UPDATE_BATCH_SIZE    = 1000

  ##
  # @return [Boolean] Whether an invocation of check() is authorized.
  #
  def self.check_authorized?
    Task.where(service: Service::GOOGLE).
        where('status IN (?)', [Task::Status::RUNNING]).count == 0
  end

  ##
  # @param inventory_key [String] Object key of a Google Books inventory file
  #                               in S3.
  #
  def initialize(inventory_key)
    @inventory_key = inventory_key
  end

  ##
  # @param task [Task] Optional. If not provided, one will be created.
  #
  def check(task = nil)
    raise 'Another Google check is in progress.' unless self.class.check_authorized?

    task_args = {
        name: 'Checking Google',
        service: Service::GOOGLE,
        status: Task::Status::RUNNING
    }
    if task
      Rails.logger.info('Google.check(): updating provided Task')
      task.update!(task_args)
    else
      Rails.logger.info('Google.check(): creating new Task')
      task = Task.create!(task_args)
    end

    config       = Configuration.instance
    store        = TempStore.instance
    bucket       = config.storage.dig(:temp, :bucket)
    obj_id_batch = []

    begin
      # Count the number of lines in the file in order to display progress.
      # This requires an extra download from S3, but that should only take a
      # few extra seconds.
      task.update(name: 'Checking Google: counting the inventory...')
      num_lines = 0
      response  = store.get_object(bucket: bucket, key: @inventory_key)
      response.body.each_line { num_lines += 1 }

      # Iterate through the lines.
      response = store.get_object(bucket: bucket, key: @inventory_key)
      response.body.each_line.with_index do |line, index|
        # Columns:
        # [0] barcode
        # [1] scanned date
        # [2] processed date
        # [3] analyzed date
        # [4] converted date
        # [5] downloaded date
        # Date format: yyyy-mm-dd hh:mm
        parts = CSV.parse_line(line, col_sep: "\t")
        if parts.any?
          obj_id_batch << parts.first.strip
          set_existing_if_necessary(obj_id_batch)
        end
        if index % TASK_UPDATE_INTERVAL == 0
          task.update(name: "Checking Google: scanned #{index} records",
                      percent_complete: (index + 1) / num_lines.to_f)
        end
      end
    rescue SystemExit, Interrupt => e
      task.update!(name: "Google check failed: #{e}",
                   status: Task::Status::FAILED)
      puts task.name
      raise e
    rescue => e
      Rails.logger.error("Google.check(): #{e}")
      task.update!(name: "Google check failed: #{e}",
                   status: Task::Status::FAILED)
      raise e
    else
      task.update!(name: "Checking Google: updated database with #{num_lines} "\
                         "found items.",
                   status: Task::Status::SUCCEEDED)
      puts task.name
    ensure
      set_existing(obj_id_batch)
      store.delete_object(bucket: bucket, key: @inventory_key)
    end
  end
  ##
  # calls on Syncable module run_task() method to invoke rake task
  #
  def check_async(task)
    run_task(:google, task)
  end

  private

  ##
  # @param batch [Array<String>] Batch of object IDs.
  # @return [void]
  #
  def set_existing(batch)
    Book.bulk_update(batch, 'exists_in_google', 'true', 'obj_id')
    Book.analyze_table
  ensure
    batch.clear
  end

  def set_existing_if_necessary(batch)
    set_existing(batch) if batch.length >= UPDATE_BATCH_SIZE
  end

end
