Feature: Dashboard

    @selenium
    Scenario: Dashboard without filtering
      Given there is one event
      When I visit the dashboard
      Then I should a non empty dashboard event list

    @selenium
    Scenario: Dashboard with filtering and event shown
      Given there is one event
      When I visit the dashboard of "AR"
      Then I should a non empty dashboard event list

    @selenium
    Scenario: Dashboard with filtering and no event shown
      Given there is one event
      When I visit the dashboard of "AL"
      Then I should an empty dashboard event list 
