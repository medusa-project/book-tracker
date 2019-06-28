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
      FileUtils.makedirs(TEMP_DIR)
      pathname = File.join(TEMP_DIR, "google_books_#{SecureRandom.uuid}.txt")

      File.open(pathname, 'wb') do |file|
        file.write(uploaded_io.read)
      end

      Google.new(pathname).check_async
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
    Hathitrust.new.check_async
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
    InternetArchive.new.check_async
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
    RecordSource.new.import_async
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
