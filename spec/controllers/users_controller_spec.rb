require 'rails_helper'
require_relative "../support/devise"


describe UsersController do

    context "If user is not administrator" do
      login_comercial

      describe "GET index" do
        it "should raise CanCan::AccessDenied" do
          expect{ get :index }.to raise_error CanCan::AccessDenied
        end
      end

      describe "GET show" do
       it "should raise CanCan::AccessDenied" do
         expect{ get :show, {:id => 1}}.to raise_error CanCan::AccessDenied
       end
      end

      describe "GET new" do
        it "should raise CanCan::AccessDenied" do
          expect{ get :new }.to raise_error CanCan::AccessDenied

        end
      end

      describe "GET edit" do
       it "should raise CanCan::AccessDenied" do
         expect{ get :edit, {:id => 1} }.to raise_error CanCan::AccessDenied
       end
      end

    end

end
