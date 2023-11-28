require_relative './hathitrust.rb'

class Task < ApplicationRecord
  ##
  # An enum-like class.
  #
  class Status

    SUBMITTED = 0
    RUNNING = 1
    PAUSED = 2
    SUCCEEDED = 3
    FAILED = 4

    ##
    # @param status [Integer] One of the Status constant values.
    # @return [String] Human-readable status.
    #
    def self.to_s(status)
      case status
      when Status::SUBMITTED
        'Submitted'
      when Status::RUNNING
        'Running'
      when Status::PAUSED
        'Paused'
      when Status::SUCCEEDED
        'Succeeded'
      when Status::FAILED
        'Failed'
      end
    end

  end


  after_initialize :init
  before_save :constrain_progress, :auto_complete
  after_save :trigger_hathitrust_check, if: :import_task_completed?

  def init
    self.status ||= Status::RUNNING
  end

  def status=(status)
    write_attribute(:status, status)
    if status == Status::SUCCEEDED
      self.percent_complete = 1
      self.completed_at = Time.current
    end
  end

  def import_task_completed?
    if Rails.env.development?
      status == Status::FAILED and service == Service::LOCAL_STORAGE
    else 
      status == Status::SUUCEEDED and service == Service::LOCAL_STORAGE
    end
  end

  def trigger_hathitrust_check
    hathi_trust = Hathitrust.new 
    task = Task.create!(name: 'Preparing to check HathiTrust', 
                        service: Service::HATHITRUST,
                        status: Status::SUBMITTED)
    hathi_trust.check_async(task)
  end


  private

  def auto_complete
    if (1 - self.percent_complete).abs <= 0.0000001
      self.status = Status::SUCCEEDED
      self.completed_at = Time.current
    end
  end

  def constrain_progress
    self.percent_complete = self.percent_complete < 0 ? 0 : self.percent_complete
    self.percent_complete = self.percent_complete > 1 ? 1 : self.percent_complete
  end

end
