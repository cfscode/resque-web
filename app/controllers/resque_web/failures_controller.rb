module ResqueWeb
  class FailuresController < ResqueWeb::ApplicationController

    # Display all jobs in the failure queue
    #
    # @param [Hash] params
    # @option params [String] :class filters failures shown by class
    # @option params [String] :queue filters failures shown by failure queue name
    def index
    end

    # remove an individual job from the failure queue
    def destroy
      Resque::Failure.remove(params[:id])
      redirect_to failures_path(redirect_params)
    end

    # destroy all jobs from the failure queue
    def destroy_all
      queue = params[:queue] || 'failed'

      (Resque::Failure.count - 1).downto(0).each do |i|
        Resque::Failure.remove(i) if must_execute_action_for(i)
      end

      redirect_to failures_path(redirect_params)
    end

    # retry an individual job from the failure queue
    def retry
      reque_single_job(params[:id])
      redirect_to failures_path(redirect_params)
    end

    # retry all jobs from the failure queue
    def retry_all
      if params[:queue].present? && params[:queue] != 'failed'
        Resque::Failure.requeue_queue(params[:queue])
      else
        (Resque::Failure.count - 1).downto(0).each do |i|
          reque_single_job(i) if must_execute_action_for(i)
        end
      end

      redirect_to failures_path(redirect_params)
    end

    private

    #API agnostic for Resque 2 with duck typing on requeue_and_remove
    def reque_single_job(id)
      if Resque::Failure.respond_to?(:requeue_and_remove)
        Resque::Failure.requeue_and_remove(id)
      else
        Resque::Failure.requeue(id)
        Resque::Failure.remove(id)
      end
    end

    def redirect_params
      {}.tap do |p|
        if params[:queue].present?
          p[:queue] = params[:queue]
        end
      end
    end

    def must_execute_action_for(i)
      (params[:job_class].blank? || params[:job_class] == job_class_for(i)) &&
      (params[:job_exception].blank? || params[:job_exception] == job_exception_for(i))
    end

    def job_class_for(i)
      Resque::Failure.all(i)['payload']['args'].first['job_class']
    end

    def job_exception_for(i)
      Resque::Failure.all(i)['exception']
    end
  end
end
