Feature: Administración de Eventos

	@javascript
	Scenario: Ver listado de Eventos Confirmados
		Given Im a logged in user
		When I visit the events page
		Then I should see "Eventos futuros"
		And I should see "Fecha"
		And I should see "Tipo de Evento"
		And I should see "Detalles"
		And I should see "Nuevo Evento"
	
	@javascript
	Scenario: Alta de Evento Válido
		Given Im a logged in user
		When I create a valid event of type "Tipo de Evento de Prueba"
		Then I should be on the events listing page
		And I should see "Evento creado exitosamente"
		And I should see "Tipo de Evento de Prueba"
		
	@javascript
	Scenario: Validación de Fecha Pasada
		Given Im a logged in user
		When I create an invalid event with "23-01-2001" as "event_date"
		Then I should see "el evento debe tener una fecha futura"
	
	@javascript
	Scenario: Validación de Capacidad
		Given Im a logged in user
		When I create an invalid event with "0" as "event_capacity"
		Then I should see "el evento no puede tener una capacidad de 0 personas"
		
	@javascript
	Scenario: Precio EB debe ser menor a Precio de Lista
		Given Im a logged in user
		When I create an invalid event with "1000" as "event_eb_price"
		Then I should see "el Precio Early Bird no puede ser mayor al Precio de Lista"
		
	@javascript
	Scenario: Fecha EB debe ser menor a la Fecha del Evento
		Given Im a logged in user
		When I create an invalid event with "31-01-3000" as "event_eb_end_date"
		Then I should see "la fecha de Early Bird no puede ser mayor a la Fecha del Evento"
	
	@javascript	
	Scenario: No se puede crear un evento vacío
		Given Im a logged in user
		When I create an empty event
		Then I should see "no puede estar en blanco"
		
	@javascript	
	Scenario: Se deben ocutar los descuentos y precios EB y SEB si es un evento privado
		Given Im a logged in user
		When I choose to create a Private event
		Then public prices should be disabled

	@javascript
	Scenario: Se deben mostrar los descuentos y precios EB y SEB si es un evento público
	  Given Im a logged in user
		When I choose to create a Public event
		Then I should see public prices
	
	@javascript
	Scenario: Se debe mostrar timezone y ciudad=Webinar si es el evento es un webinar
	  Given Im a logged in user
		When I choose to create a Webinar event
		Then I should see the webinar setup

	@javascript	
	Scenario: SEB=30 días antes de la fecha del evento y EB=10 días antes de la fecha del evento
	  Given Im a logged in user
		When I create a public event on "15-01-2015"
		Then EB date should be "05-01-2015"
	
	@javascript	
	Scenario: Modificación de Evento Válido
		Given Im a logged in user
		And there is a event type "Modificar"
		When I create a valid event of type "Modificar"
		And I modify the event "Modificar"
		Then I should be on the events listing page
		And I should see "Evento modificado exitosamente"
	
	@javascript
	Scenario: Cancelación de Evento
		Given Im a logged in user
		When I create a valid event of type "Tipo de Evento de Prueba"
		And I cancel the event "Tipo de Evento de Prueba"
		Then I should be on the events listing page
		And I should see "Evento cancelado exitosamente"	
		
