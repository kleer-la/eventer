Feature: Administración de Participantes

	Scenario: Form de registro
		Given Im a logged in user
		And theres an event
		Then It should have a registration page
	
	Scenario: Nueva inscripción Exitosa
		Given Im a logged in user
		And theres an event
#		And theres an influence zone
		When I register for that event
		Then I should see a confirmation message
		
	@selenium
	Scenario: inscripción en Blanco
		Given Im a logged in user
		And theres an event
		And theres an influence zone
		When I make a blank registration for that event
		Then I should see an alert "Todos los campos son requeridos"

	@selenium
	Scenario: Creacion de E-mail Personalizado de Notificacion de Registro
		Given Im a logged in user
		And an event of type "Tipo de Evento de Prueba" with "lorem" as email content
		When I register a new participant for the "Custom Event"
		Then the Paricipant should recieve an email with "lorem"
		