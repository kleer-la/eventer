Feature: Inicio

  @selenium
	Scenario: API para consultar los cursos visibles y públicos con XML
    Given there is one event
    When I request the event list in "XML"
    Then it should be an XML
    And it should have an event

  @selenium
	Scenario: API para consultar cursos debe devolver un script extra
    Given there is one event
    When I request the event list in "XML"
    Then it should have extra script in the event
