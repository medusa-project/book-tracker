class TasksController < ApplicationController

  TEMP_DIR = Rails.root.join('tmp')

  before_action :signed_in_user
  before_action :service_check_in_progress, except: :index

  ##
  # Responds to POST /check-google
  #
  def check_google
    uploaded_io = params[:file]
    if uploaded_io.respond_to?(:original_filename)
      # Store the uploaded file in an S3 bucket.
      config = ::Configuration.instance
      opts = {
          region: config.aws_region,
          force_path_style: true,
          credentials: Aws::Credentials.new(config.aws_access_key_id,
                                            config.aws_secret_access_key)
      }
      opts[:endpoint] = config.s3_endpoint if config.s3_endpoint.present?

      client = Aws::S3::Client.new(opts)
      s3 = Aws::S3::Resource.new(client: client)
      key = sprintf('google_inventory_%d.txt', Time.now.to_i)
      obj = s3.bucket(config.temp_bucket).object(key)
      obj.put(body: uploaded_io)

      task = Task.create!(name: 'Preparing to check Google',
                          service: Service::GOOGLE,
                          status: Status::WAITING)
      Google.new(key).check_async(task)
      flash['success'] = 'Google check will begin momentarily.'
    else
      flash['error'] = 'No file provided.'
    end
  rescue => e
    handle_error(e)
  ensure
    redirect_back fallback_location: tasks_path
  end

  ##
  # Responds to POST /check-hathitrust
  #
  def check_hathitrust
    task = Task.create!(name: 'Preparing to check HathiTrust',
                        service: Service::HATHITRUST,
                        status: Status::WAITING)
    Hathitrust.new.check_async(task)
  rescue => e
    handle_error(e)
  else
    flash['success'] = 'HathiTrust check will begin momentarily.'
  ensure
    redirect_back fallback_location: tasks_path
  end

  ##
  # Responds to POST /check-internet-archive
  #
  def check_internet_archive
    task = Task.create!(name: 'Preparing to check Internet Archive',
                        service: Service::INTERNET_ARCHIVE,
                        status: Status::WAITING)
    InternetArchive.new.check_async(task)
  rescue => e
    handle_error(e)
  else
    flash['success'] = 'Internet Archive check will begin momentarily.'
  ensure
    redirect_back fallback_location: tasks_path
  end

  ##
  # Responds to POST /import
  #
  def import
    task = Task.create!(name: 'Preparing to import MARCXML records',
                        service: Service::LOCAL_STORAGE,
                        status: Status::WAITING)
    RecordSource.new.import_async(task)
  rescue => e
    handle_error(e)
  else
    flash['success'] = 'Import will begin momentarily.'
  ensure
    redirect_back fallback_location: tasks_path
  end

  ##
  # Responds to GET /tasks
  #
  def index
    @tasks = Task.order(created_at: :desc).limit(100)

    @last_fs_import = Task.where(service: Service::LOCAL_STORAGE).
        where('completed_at IS NOT NULL').
        order(completed_at: :desc).limit(1).first
    @last_ht_check = Task.where(service: Service::HATHITRUST).
        where('completed_at IS NOT NULL').
        order(completed_at: :desc).limit(1).first
    @last_ia_check = Task.where(service: Service::INTERNET_ARCHIVE).
        where('completed_at IS NOT NULL').
        order(completed_at: :desc).limit(1).first
    @last_gb_check = Task.where(service: Service::GOOGLE).
        where('completed_at IS NOT NULL').
        order(completed_at: :desc).limit(1).first

    render partial: 'tasks' if request.xhr?
  end

  private

  def service_check_in_progress
    if Service::check_in_progress?
      flash['error'] = 'Cannot import or check multiple services concurrently.'
      redirect_back fallback_location: tasks_path
    end
  end

end
