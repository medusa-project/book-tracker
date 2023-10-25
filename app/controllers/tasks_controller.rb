class TasksController < ApplicationController

  TEMP_DIR = Rails.root.join('tmp')

  before_action :signed_in_user
  before_action :authorize_google_check, only: :check_google
  before_action :authorize_hathitrust_check, only: :check_hathitrust
  before_action :authorize_internet_archive_check, only: :check_internet_archive
  before_action :check_production, except: :index

  ##
  # Responds to POST /check-google
  #
  def check_google
    uploaded_io = params[:file]
    if uploaded_io.respond_to?(:original_filename)
      # Store the uploaded file in an S3 bucket.
      config = ::Configuration.instance
      key    = sprintf('google_inventory_%d.txt', Time.now.to_i)
      store  = TempStore.instance
      store.put_object(bucket: config.storage.dig(:temp, :bucket),
                       key:    key,
                       body:   uploaded_io)

      task = Task.create!(name: 'Preparing to check Google',
                          service: Service::GOOGLE,
                          status: Task::Status::SUBMITTED)
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
                        status: Task::Status::SUBMITTED)
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
                        status: Task::Status::SUBMITTED)
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
                        status: Task::Status::SUBMITTED)
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
    @tasks = Task.order(created_at: :desc).limit(50)

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

  def authorize_google_check
    unless Google.check_authorized?
      flash['error'] = 'Cannot check Google concurrently with an import or '\
          'other Google check.'
      redirect_back fallback_location: tasks_path
    end
  end

  def authorize_hathitrust_check
    unless Hathitrust.check_authorized?
      flash['error'] = 'Cannot check HathiTrust concurrently with an import '\
          'or other HathiTrust check.'
      redirect_back fallback_location: tasks_path
    end
  end

  def authorize_import
    unless RecordSource.import_authorized?
      flash['error'] = 'Cannot import records concurrently with another import.'
      redirect_back fallback_location: tasks_path
    end
  end

  def authorize_internet_archive_check
    unless InternetArchive.check_authorized?
      flash['error'] = 'Cannot check Internet Archive concurrently with an '\
          'import or other Internet Archive check.'
      redirect_back fallback_location: tasks_path
    end
  end

  def check_production
    unless Rails.env.production? or Rails.env.demo?
      flash['error'] = 'This feature only works in production. Elsewhere, '\
          'use a rake task instead.'
      redirect_back fallback_location: tasks_path
    end
  end

end
