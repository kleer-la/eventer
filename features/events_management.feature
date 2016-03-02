Feature: Administración de Eventos

	Scenario: Ver listado de Eventos Confirmados
		Given Im a logged in user
		When I visit the events page
		Then I should see "Eventos futuros"
		And I should see "Fecha"
		And I should see "Tipo de Evento"
		And I should see "Detalles"
		And I should see "Nuevo Evento"

	@selenium
	Scenario: Alta de Evento Válido
		Given Im a logged in user
		When I create a valid event of type "Tipo de Evento de Prueba"
		Then I should be on the events listing page
		And I should see "Evento creado exitosamente"
		And I should see "Tipo de Evento de Prueba"

	Scenario: Validación de Capacidad
		Given Im a logged in user
		When I create an invalid event with "0" as "event_capacity"
		Then I should see "el evento no puede tener una capacidad de 0 personas"

	@selenium
	Scenario: Precio EB debe ser menor a Precio de Lista
		Given Im a logged in user
		When I create an invalid event with "1000" as "event_eb_price"
		Then I should see "el Precio Early Bird no puede ser mayor al Precio de Lista"

	@selenium
	Scenario: Fecha EB debe ser menor a la Fecha del Evento
		Given Im a logged in user
		When I create an invalid event with "31-01-3000" as "event_eb_end_date"
		Then I should see "la fecha de Early Bird no puede ser mayor a la Fecha del Evento"

	@selenium
	Scenario: No se puede crear un evento vacío
		Given Im a logged in user
		When I create an empty event
		Then I should see "no puede estar en blanco"

	@selenium
	Scenario: Se deben ocultar los descuentos y precios EB y SEB si es un evento privado
		Given Im a logged in user
		When I choose to create a Private event
		Then public prices should be disabled

	@selenium
	Scenario: Se deben mostrar los descuentos y precios EB y SEB si es un evento público
	  Given Im a logged in user
		When I choose to create a Public event
		Then I should see public prices

	@selenium
	Scenario: Se debe mostrar timezone y ciudad=Webinar si es el evento es un webinar
	  Given Im a logged in user
		When I choose to create a Webinar event
		Then I should see the webinar setup

	@selenium
	Scenario: SEB=30 días antes de la fecha del evento y EB=10 días antes de la fecha del evento
	  Given Im a logged in user
		When I create a public event on "15-01-2015"
		Then EB date should be "05-01-2015"

	@selenium
	Scenario: Modificación de Evento Válido
		Given Im a logged in user
		And there is a event type "Modificar"
		When I create a valid event of type "Modificar"
		And I modify the last event
		Then I should be on the events listing page
		And I should see "Evento modificado exitosamente"

	@selenium
	Scenario: Cancelación de Evento
		Given Im a logged in user
		When I create a valid event of type "Tipo de Evento de Prueba"
		And I cancel the event "Tipo de Evento de Prueba"
		Then I should be on the events listing page
		And I should see "Evento cancelado exitosamente"

	@selenium
	Scenario: Ingresar un script extra
		Given Im a logged in user
		When I create an event with extra script "<my extra script/>"
		And go to the last course created
		Then the extra script should be "<my extra script/>"

    @selenium
  	Scenario: Three trainers
  		Given Im a logged in user
  		When I create an event with trainers "John Doe,Jeff Baurer,Michael Donovan"
  		And go to the last course created
      Then I should see "John Doe"
      And I should see "Jeff Baurer"
      And I should see "Michael Donovan"
