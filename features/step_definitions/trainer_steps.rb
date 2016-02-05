# encoding: utf-8

def trainer_init(name)
	visit '/trainers/new'
	fill_in 'trainer_name', :with => name
end
def trainer_save
	click_button 'Guardar'
end

Given(/^I create a kleerer named "(.*?)"$/) do |name|
	trainer_init(name)
	check 'trainer_is_kleerer'
	trainer_save
end

When /^I create a valid trainer named "([^\"]*)"$/ do |name|
	trainer_init(name)
	trainer_save
end

When /^I create a valid trainer named "([^"]*)" and with bio "([^"]*)"$/ do |name, bio|
	trainer_init(name)
	fill_in 'trainer_bio', :with => bio
	trainer_save
end

When(/^I create a valid trainer named "(.*?)" and with EN bio "(.*?)"$/) do |name, bio|
	trainer_init(name)
  fill_in 'trainer_bio', :with => "sp bio"
  fill_in 'trainer_bio_en', :with => bio
	trainer_save
end

Then /^I should be on the trainers listing page$/ do
  current_path.should == trainers_path
end

When /^I view the trainer "([^\"]*)"$/ do |trainer_name|
	click_link trainer_name
end
