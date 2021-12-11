require 'rails_helper'

describe ArticlesController do
    describe "GET 'show' (/article/1.<format>)" do
        it "fetch a article" do
            article = FactoryBot.create(:article)
            get :show, params: {:id => article.to_param, :format => "json"}
            expect(assigns(:article)).to eq article
        end
    end
end