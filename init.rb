require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Disqus CI plugin for Redmine'

# Redmine simple CI plugin
Redmine::Plugin.register :disqus_ci do
  name 'Disqus CI'
  author 'Disqus.com'
  description 'Integrates Disqus\' testing platform with Redmine.'
  version '1.0'
  
  # The tessie_url_custom_field setting is used to hold the id of the project custom field
  # that stores the CI feed url for each project
  settings :default => {'tessie_url_custom_field' => 0}, :partial => 'settings/disqus_ci_settings'

  # This plugin adds a project module
  # It can be enabled/disabled at project level (Project settings -> Modules)
  project_module :continuous_integration do
    # This permission has to be explicitly given
    # It will be listed on the permissions screen
    permission :view_ci_report, {:disqus_ci => :show}
  end

  # A new item is added to the project menu
  menu :project_menu, :disqus_ci, { :controller => 'disqus_ci', :action => 'show' }, :caption => 'Integration'
end
