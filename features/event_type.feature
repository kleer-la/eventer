Feature: Administración de Tipos Eventos

  @selenium
	Scenario: Subtitulo de tipos de eventos
		Given Im a logged in user
		When I create a event type with subtitle "New subtitle"
		Then I should see "New subtitle"

  @selenium
  Scenario: Modificar un Tipo de Evento
    Given Im a logged in user
    And I create a event type with subtitle "to be modified"
    When I modify the just created event type with subtitle "modified subtitle"
    Then I should see "modified subtitle"
