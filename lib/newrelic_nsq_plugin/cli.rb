require 'newrelic_plugin'

module NewrelicNsqPlugin::CLI
  def self.start
    #puts NewRelic::Plugin::Setup.installed_agents
    NewRelic::Plugin::Run.setup_and_run
  end
end
