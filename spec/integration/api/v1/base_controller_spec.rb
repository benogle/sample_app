require 'spec_helper'

describe Api::V1::BaseController do
  fixtures :users

  context 'expects' do
    before(:all) do
      # Make expects public
      class Api::V1::BaseController
        public :expects
      end
    end

    before(:each) do
      @obj = Object.new
      @controller = Api::V1::BaseController.new
      @opts = { :controller => @obj }
      @user = users(:user)
      @admin = users(:admin)
    end

    it 'works with :key => :class' do
      @opts[:params] = { :id => @user.eid }

      @controller.expects :all, { :id => :user }, @opts

      @obj.instance_variables.should include :@user
      @obj.instance_variable_get(:@user).should eq @user
    end

    it 'works with :key => SomeClass' do
      @opts[:params] = { :contributor => @user.eid }

      @controller.expects :all, { :contributor => User }, @opts

      @obj.instance_variables.should include :@contributor
      @obj.instance_variable_get(:@contributor).should eq @user
    end

    it 'properly handles :all' do
      @opts[:params] = { :id => @user.eid, :admin => @admin.eid }
      @controller.expects :all, { :id => User, :admin => User }, @opts
      @obj.instance_variables.should include :@id
      @obj.instance_variables.should include :@admin

      @opts[:params][:admin] = @admin.id # not eid
      expect { @controller.expects :all, { :id => User, :admin => User }, @opts }.to raise_error(Errors::NotFound)

      @opts[:params] = {}
      expect { @controller.expects :all, { :id => User, :admin => User }, @opts }.to raise_error(Errors::NotFound)
    end

    it 'properly handles :any' do
      @opts[:params] = { :id => @user.eid }
      @controller.expects :any, { :id => User, :admin => User }, @opts
      @obj.instance_variables.should include :@id
      @obj.instance_variables.should include :@admin
      @obj.instance_variable_get(:@admin).should eq nil

      @opts[:params] = {}
      expect { @controller.expects :any, { :id => User, :admin => User }, @opts }.to raise_error(Errors::NotFound)
    end

    it 'works with [:class]' do
      @opts[:params] = { :user => @user.eid }

      @controller.expects :all, [:user], @opts

      @obj.instance_variables.should include :@user
      @obj.instance_variable_get(:@user).should eq @user
    end
  end
end
