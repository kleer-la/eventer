Feature: Administración de Tipos Eventos

  @selenium
	Scenario: Subtitulo de tipos de eventos
		Given Im a logged in user
		When I create a event type with subtitle "New subtitle"
		Then I should see "New subtitle"
