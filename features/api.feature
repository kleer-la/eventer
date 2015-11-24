Feature: Inicio

  @selenium
	Scenario: API para consultar los cursos visibles y públicos con XML
    Given there is one event
    When Im a request the events list in "XML"
    Then it should be an XML
    And it should have an event
