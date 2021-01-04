module ControllerMacros
  def login_admin
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:administrator]
      sign_in FactoryBot.create(:administrator) # Using factory bot as an example
    end
  end

  def login_comercial
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:comercial]
      user = FactoryBot.create(:comercial)
      sign_in user
    end
  end
end