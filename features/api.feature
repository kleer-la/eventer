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
  Scenario: API for query for kleerers
    Given Im a logged in user
    And I create a kleerer named "Carlos Peix"
    When I request the kleerer list in "XML" format
    Then it should be an XML
    And it should have "//trainers/trainer"
