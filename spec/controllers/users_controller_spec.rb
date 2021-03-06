# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe UsersController do

  describe "without an admin" do
    it "should require a login" do
      get 'index'

      response.should redirect_to( new_user_session_path )
    end
  end

  describe "with an admin" do
    before(:each) do
      @admin = Factory(:admin)
      sign_in( @admin )
    end

    it "should show a list of current users" do
      get 'index'

      response.should render_template( 'users/index')
      assigns(:users).should_not be_empty
    end

    it 'should load a users details' do
      get 'show', :id => @admin.id

      response.should render_template( 'users/show' )
      assigns(:user).should_not be_nil
    end

    it 'should have a form for creating a new user' do
      get 'new'

      response.should render_template( 'users/new' )
      assigns(:user).should_not be_nil
    end

    it "should create a new administrator" do
      post :create, :user => {
          :login => 'someone',
          :email => 'someone@example.com',
          :password => 'secret',
          :password_confirmation => 'secret',
          :admin => 'true'
        }

      assigns(:user).should be_an_admin

      response.should be_redirect
      response.should redirect_to( user_path( assigns(:user) ) )
    end

    it 'should create a new administrator with token privs' do
      post :create, :user => {
          :login => 'someone',
          :email => 'someone@example.com',
          :password => 'secret',
          :password_confirmation => 'secret',
          :admin => '1',
          :auth_tokens => '1'
        }

      assigns(:user).admin?.should be_true
      assigns(:user).auth_tokens?.should be_true

      response.should be_redirect
      response.should redirect_to( user_path( assigns(:user) ) )
    end

    it "should create a new owner" do
      post :create, :user => {
          :login => 'someone',
          :email => 'someone@example.com',
          :password => 'secret',
          :password_confirmation => 'secret',
        }

      assigns(:user).should_not be_an_admin

      response.should be_redirect
      response.should redirect_to( user_path( assigns(:user) ) )
    end

    it 'should create a new owner ignoring token privs' do
      post :create, :user => {
          :login => 'someone',
          :email => 'someone@example.com',
          :password => 'secret',
          :password_confirmation => 'secret',
          :auth_tokens => '1'
        }

      assigns(:user).should_not be_an_admin
      assigns(:user).auth_tokens?.should be_false

      response.should be_redirect
      response.should redirect_to( user_path( assigns(:user) ) )
    end

    it 'should update a user without password changes' do
      user = Factory(:quentin)

      lambda {
        post :update, :id => user.id, :user => {
            :email => 'new@example.com',
            :password => '',
            :password_confirmation => ''
          }
        user.reload
      }.should change( user, :email )

      response.should be_redirect
      response.should redirect_to( user_path( user ) )
    end

    it 'should be able to suspend users' do
      @user = Factory(:quentin)
      put 'suspend', :id => @user.id

      response.should be_redirect
      response.should redirect_to( users_path )
    end
  end
end
