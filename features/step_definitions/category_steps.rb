Given(/^I create a new category$/) do
  visit '/categories/new'
end

When(/^I fill the category fields$/) do
  fill_in 'category_name', :with => "a"
  fill_in 'category_codename', :with => "a"
  fill_in 'category_tagline', :with => "a"
  fill_in 'category_description', :with => "a"
end

When(/^I fill the category "(.*?)" fields "(.*?)"$/) do |lang, fields|
    values= fields.split(',')
  fill_in 'category_name_en', :with => values[0]
  fill_in 'category_tagline_en', :with => values[1]
  fill_in 'category_description_en', :with => values[2]

  click_button_and_wait 'Guardar'
end
