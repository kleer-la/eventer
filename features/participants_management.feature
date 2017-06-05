Feature: Administración de Participantes

	Scenario: Form de registro
		Given Im a logged in user
		And theres an event
		Then It should have a registration page
	
	Scenario: Nueva inscripción Exitosa
		Given Im a logged in user
		And theres an event
		When I register for that event
		Then I should see a confirmation message

	@selenium
	Scenario: Inscripción sin mail de bienvenida
		Given Im a logged in user
		And theres an event without welcome email
		When I register for that event
		Then I should see a message that someone will get in touch shortly

	@selenium
	Scenario: inscripción en Blanco
		Given Im a logged in user
		And theres an event
		And theres an influence zone
		When I make a blank registration for that event
		Then I should see an alert "Todos los campos son requeridos"

#	Scenario: Certificado asistencia
#		Given Im a logged in user
#		And theres an event
#        And I register for that event
#		When I visit the certificate page
#		Then I should receive a PDF file
		
#		Then I should see "Certificado de Asistencia"
#        And  I should see "Tipo de Evento de Prueba"
#        And  I should see "Juan Callidoro"
#        And  I should see "31 de enero de 2030"
#        And  I should see "Buenos Aires"

			


