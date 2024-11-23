ActiveAdmin.setup do |config|
  config.namespace :admin do |admin|
    admin.build_menu do |menu|
      menu.add label: 'Courses Mgnt', priority: 2
      menu.add label: 'Services Mgnt', priority: 4
      menu.add label: 'We Publish', priority: 8
      menu.add label: 'Others', priority: 10
      menu.add label: 'Old Version', url: '/dashboard', priority: 100
    end
  end
end
