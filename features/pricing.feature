Feature: Dashboard

    @selenium
    Scenario: Pricing without filtering
      Given there is one event
      When I visit Pricing
      Then I should see a non empty pricing event list

    @selenium
    Scenario: Pricing with filtering one event is shown
      Given there is one event
      When I visit pricing of "AR"
      Then I should see a non empty pricing event list

    @selenium
    Scenario: Pricing with filtering and no event shown
      Given there is one event
      When I visit pricing of "AL"
      Then I should see an empty dashboard event list
