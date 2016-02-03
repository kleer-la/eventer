Feature: Search a student

    Scenario: Search a name that doesn't exist
        Given Im a logged in user
        When I search for "Ramayama"
        Then I should see "No encontré 'Ramayama'"
