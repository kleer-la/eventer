ActiveAdmin.register Log do
  menu label: 'Logs', priority: 1005

  filter :area
  filter :level
  filter :message
  filter :details
  filter :created_at

  actions :index, :show
end
