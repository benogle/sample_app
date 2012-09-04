require 'spec_helper'

describe Api::V1::BaseController do
  context 'in development' do
    controller(Api::V1::BaseController) do
      def index
      end
    end

    it 'handles validation errors with a 400 status' do
      controller.should_receive(:index).and_raise(ActiveRecord::RecordInvalid.new(User.new))
      get :index

      response.status.should eq 400

      parsed = JSON.parse(response.body)
      parsed['errors'].size.should eq 0
    end

    it 'handles application errors with a 400 status' do
      controller.should_receive(:index).and_raise(Errors::App.new('fail', 'app_field'))
      get :index

      response.status.should eq 400

      parsed = JSON.parse(response.body)
      parsed['errors'].size.should eq 1
      parsed['errors'][0]['field'].should eq 'app_field'
    end

    it 'handles authentication errors with a 403 status' do
      controller.should_receive(:index).and_raise(Errors::Authentication.new('Wrong username or maybe password'))
      get :index

      response.status.should eq 403

      parsed = JSON.parse(response.body)
      parsed['errors'].size.should eq 1
    end

    it 'handles authorization errors with a 403 status' do
      controller.should_receive(:index).and_raise(Errors::Authorization.new('No access'))
      get :index

      response.status.should eq 403

      parsed = JSON.parse(response.body)
      parsed['errors'].size.should eq 1
    end

    it 'handles not found errors with a 404 status' do
      controller.should_receive(:index).and_raise(Errors::NotFound.new('Nope'))
      get :index

      response.status.should eq 404

      parsed = JSON.parse(response.body)
      parsed['errors'].size.should eq 1
    end

    it 'handles unexpected errors with a 500 status and debug information' do
      controller.should_receive(:index).and_raise(RuntimeError.new('fail'))
      get :index

      response.status.should eq 500

      parsed = JSON.parse(response.body)
      parsed['errors'].size.should eq 1
      parsed.keys.should include('debug')
    end
  end

  context 'in production' do
    controller(Api::V1::BaseController) do
      rescue_from Exception, :with => :internal_error

      def index
      end
    end
    it 'handles unexpected errors with a 500 status and no debug information' do
      controller.should_receive(:index).and_raise(RuntimeError.new('fail'))
      get :index

      response.status.should eq 500

      parsed = JSON.parse(response.body)
      parsed['errors'].size.should eq 1
      parsed.keys.should_not include('debug')
    end
  end
end
