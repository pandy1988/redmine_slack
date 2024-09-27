require_relative 'lib/redmine_slack/hooks'
require_relative 'lib/redmine_slack/issue_patch'
require_relative 'lib/redmine_slack/journal_patch'

Redmine::Plugin.register :redmine_slack do
  name 'Redmine Slack'
  author 'Pan'
  description 'Slack chat plugin for Redmine'
  version '0.0.0'
  url 'https://github.com/pandy1988/redmine_slack'
  author_url 'https://github.com/pandy1988'

  requires_redmine :version_or_higher => '5.0'
  settings :default => {
    'incoming_webhook_url' => '',
    'inform_projects' => []
  }, :partial => 'settings/slack_settings'
end
