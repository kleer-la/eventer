# frozen_string_literal: true

require 'capybara/selenium/driver'
require 'capybara/selenium/driver_specializations/chrome_driver'

# Capybara 3.40 (the latest release, Jan 2024) resets Chrome between examples
# with the CDP call Storage.clearDataForOrigin(origin: '*'). Chrome 158 no longer
# takes '*' as an origin ("invalid argument: * is not a valid URL"), so every
# headless-Chrome system spec errored in teardown. Same clean-up without the
# wildcard: every cookie, and the local storage of the app under test, which is
# the only origin these specs visit.
#
# Remove once Capybara ships its own fix (it calls clearDataForOrigin in
# Capybara::Selenium::Driver::ChromeDriver#reset!).
module CapybaraChromeResetWithoutWildcard
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == 'Storage.clearDataForOrigin' && params[:origin] == '*'

    super('Network.clearBrowserCookies')
    origin = Capybara.current_session.server&.base_url
    super(cmd, params.merge(origin: origin)) if origin && params[:storageTypes].to_s.include?('local_storage')
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeResetWithoutWildcard)
