Feature: Administración de Instructores

	Scenario: Alta de Instructor
		Given Im a logged in user
		When I create a valid trainer named "Carlos Peix"
		Then I should be on the trainers listing page
#		And I should see "Entrenador creado exitosamente"
		And I should see "Carlos Peix"


	Scenario: Alta de Instructor con mini Bio
		Given Im a logged in user
		When I create a valid trainer named "Carlos Peix2" and with bio "Gran instructor!"
		Then I view the trainer "Carlos Peix2"
		And I should see "Gran instructor!"

	Scenario: Instructor as English mini Bio
		Given Im a logged in user
		When I create a valid trainer named "Carlos Saul Peix" and with EN bio "Eats too much chicken with hormones!"
		Then I view the trainer "Carlos Saul Peix"
		And I should see "chicken with hormones"
