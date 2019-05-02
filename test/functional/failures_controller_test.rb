require 'test_helper'

module ResqueWeb
  class FailuresControllerTest < ActionController::TestCase
    include ControllerTestHelpers

    setup do
      @routes = Engine.routes
    end

    describe "GET /failures" do
      it "renders the index page" do
        visit(:index)
        assert_template :index
      end
    end

    describe "DELETE /failures/:id" do
      it "deletes the failure" do
        Resque::Failure.expects(:remove).with('123')
        visit(:destroy, {:id => 123}, :method => :delete)
        assert_redirected_to failures_path
      end
    end

    describe "DELETE /failures/destroy_all" do
      it "deletes all failures" do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.expects(:remove).with(0)
        Resque::Failure.expects(:remove).with(1)
        visit(:destroy_all, {}, :method => :delete)
        assert_redirected_to failures_path
      end

      it 'deletes all failures with the job class specified' do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:all).with(0).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass1'] },
            'exception' => 'Exception'
          }
        )
        Resque::Failure.stubs(:all).with(1).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass2'] },
            'exception' => 'Exception'
          }
        )
        Resque::Failure.expects(:remove).with(0)
        Resque::Failure.expects(:remove).with(1).never
        visit(:destroy_all, { job_class: 'JobClass1' }, :method => :delete)
        assert_redirected_to failures_path
      end

      it 'deletes all failures with the job exception specified' do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:all).with(0).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass1'] },
            'exception' => 'Exception1'
          }
        )
        Resque::Failure.stubs(:all).with(1).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass2'] },
            'exception' => 'Exception2'
          }
        )
        Resque::Failure.expects(:remove).with(0).never
        Resque::Failure.expects(:remove).with(1)
        visit(:destroy_all, { job_exception: 'Exception2' }, :method => :delete)
        assert_redirected_to failures_path
      end
    end

    describe "PUT /failures/:id/retry" do
      it "retries the failure and remove the original message" do
        Resque::Failure.expects(:requeue_and_remove).with('123')
        visit(:retry, {:id => 123}, :method => :put)
        assert_redirected_to failures_path
      end
      it "retries should work also in case of pre 2.0 Resque" do
        Resque::Failure.expects(:requeue).with('123')
        Resque::Failure.expects(:remove).with('123')
        visit(:retry, {:id => 123}, :method => :put)
        assert_redirected_to failures_path
      end
    end

    describe "PUT /failures/retry_all" do
      it "retries all failures using requeue if no queue specified" do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:requeue_and_remove).returns(true)
        Resque::Failure.expects(:requeue_and_remove).with(0)
        Resque::Failure.expects(:requeue_and_remove).with(1)
        visit(:retry_all, {}, :method => :put)
        assert_redirected_to failures_path
      end
      it "retries all failures should also work case of pre 2.0 Resque" do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:requeue).returns(true)
        Resque::Failure.expects(:requeue).with(0)
        Resque::Failure.expects(:remove).with(0)
        Resque::Failure.expects(:requeue).with(1)
        Resque::Failure.expects(:remove).with(1)
        visit(:retry_all, {}, :method => :put)
        assert_redirected_to failures_path
      end
      it "retries all failures using requeue_queue if queue specified" do
        Resque::Failure.expects(:requeue_queue).with('myqueue')
        visit(:retry_all, {:queue=>"myqueue"}, :method => :put)
        assert_redirected_to failures_path(:queue=>'myqueue')
      end

      it 'retries all failures with the job class specified' do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:all).with(0).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass1'] },
            'exception' => 'Exception'
          }
        )
        Resque::Failure.stubs(:all).with(1).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass2'] },
            'exception' => 'Exception'
          }
        )
        Resque::Failure.expects(:requeue).with(0)
        Resque::Failure.expects(:remove).with(0)
        Resque::Failure.expects(:requeue).with(1).never
        Resque::Failure.expects(:remove).with(1).never
        visit(:retry_all, { job_class: 'JobClass1' }, :method => :put)
        assert_redirected_to failures_path
      end

      it 'retries all failures with the job exception specified' do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:all).with(0).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass1'] },
            'exception' => 'Exception1'
          }
        )
        Resque::Failure.stubs(:all).with(1).returns(
          {
            'payload' => { 'args' => ['job_class' => 'JobClass2'] },
            'exception' => 'Exception2'
          }
        )
        Resque::Failure.expects(:requeue).with(0).never
        Resque::Failure.expects(:remove).with(0).never
        Resque::Failure.expects(:requeue).with(1)
        Resque::Failure.expects(:remove).with(1)
        visit(:retry_all, { job_exception: 'Exception2' }, :method => :put)
        assert_redirected_to failures_path
      end
    end
  end
end
