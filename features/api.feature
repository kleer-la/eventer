Feature: Inicio

  @selenium
	Scenario: API para consultar los cursos visibles y públicos con XML
    Given there is one event
    When I request the event list in "XML" format
    Then it should be an XML
    And it should have an event

  @selenium
	Scenario: API para consultar cursos debe devolver un script extra
    Given there is one event
    When I request the event list in "XML" format
    Then it should have extra script in the event

  @selenium
	Scenario: API para consultar cursos debe devolver subtitulo
    Given there is one event
    When I request the event list in "XML" format
    Then it should have "subtitle" in the event type

  @selenium
  Scenario: API for query kleerers
    Given Im a logged in user
    And I create a kleerer named "Carlos Peix"
    When I request the kleerer list in "XML" format
    Then it should be an XML
    And it should have "//trainers/trainer"

    @selenium
    Scenario: API for query categories
      Given Im a logged in user
      And I create a new category
      And I fill the category fields
      And I fill the category "en" fields "en1,en2,en3"
      And the category is visible
      And I save the category
      When I request the category list in "XML" format
      Then it should be an XML
      And it should have "//categories/category"


#     API_ROOT + "/event_types/#{event_type_id}.xml"
#  API_COMMUNITY_EVENTS_PATH = "/community_events.xml"
# /events/_trainers_select
# /events/_trainers_2select