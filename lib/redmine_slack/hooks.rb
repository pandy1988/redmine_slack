require 'slack-notifier'

module RedmineSlack
  class Hooks < Redmine::Hook::Listener
    def redmine_slack_create_issue(context={})
      issue = context[:issue]
      enabled = enabled_inform issue.project

      return unless enabled
      return if issue.is_private?

      issue_url = Rails.application.routes.url_for(issue.event_url({
        :host => Setting.host_name,
        :protocol => Setting.protocol
      }))

      payload = {
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "New Ticket:\n<#{issue_url}|#{issue}>"
            }
          },
          {
            "type": "section",
            "fields": [
              {
                "type": "mrkdwn",
                "text": "#{I18n.t('field_project')}\n`#{issue.project}`"
              },
              {
                "type": "mrkdwn",
                "text": "#{I18n.t('field_priority')}\n`#{issue.priority}`"
              },
              {
                "type": "mrkdwn",
                "text": "#{I18n.t('field_tracker')}\n`#{issue.tracker}`"
              },
              {
                "type": "mrkdwn",
                "text": "#{I18n.t('field_start_date')}\n`#{issue.start_date}`"
              },
              {
                "type": "mrkdwn",
                "text": "#{I18n.t('field_status')}\n`#{issue.status}`"
              },
              {
                "type": "mrkdwn",
                "text": "#{I18n.t('field_due_date')}\n`#{issue.due_date || '-'}`"
              }
            ]
          },
          {
            "type": "rich_text",
            "elements": [
              {
                "type": "rich_text_preformatted",
                "elements": [
                  {
                    "type": "text",
                    "text": issue.description
                  }
                ]
              }
            ]
          }
        ]
      }

      notify payload
    end

    def redmine_slack_create_journal(context={})
      journal = context[:journal]
      enabled = enabled_inform journal.project

      changed_status = journal.new_status.present?
      changed_assigned_to = journal.detail_for_attribute('assigned_to_id').present?
      changed_priority = journal.new_value_for('priority_id').present?
      changed_notes = (not journal.private_notes? and journal.notes.present?)

      return unless enabled and journal.issue
      return unless changed_status or changed_assigned_to or changed_priority or changed_notes

      journal_url = Rails.application.routes.url_for(journal.event_url({
        :host => Setting.host_name,
        :protocol => Setting.protocol
      }))

      payload = {
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "New Journal:\n<#{journal_url}|#{journal.issue}>"
            }
          },
          {
            "type": "rich_text",
            "elements": [
              {
                "type": "rich_text_list",
                "style": "bullet",
                "elements": [
                  changed_status ? {
                    "type": "rich_text_section",
                    "elements": [
                      {
                        "type": "text",
                        "text": "#{I18n.t('field_status')}: "
                      },
                      {
                        "type": "text",
                        "text": "#{journal.issue.status}",
                        "style": {
                          "code": true
                        }
                      }
                    ]
                  } : nil,
                  changed_assigned_to ? {
                    "type": "rich_text_section",
                    "elements": [
                      {
                        "type": "text",
                        "text": "#{I18n.t('field_assigned_to')}: "
                      },
                      {
                        "type": "text",
                        "text": "#{journal.issue.assigned_to || '-'}",
                        "style": {
                          "code": true
                        }
                      }
                    ]
                  } : nil,
                  changed_priority ? {
                    "type": "rich_text_section",
                    "elements": [
                      {
                        "type": "text",
                        "text": "#{I18n.t('field_priority')}: "
                      },
                      {
                        "type": "text",
                        "text": "#{journal.issue.priority}",
                        "style": {
                          "code": true
                        }
                      }
                    ]
                  } : nil
                ].select{|x| not x.nil?}
              },
              changed_notes ? {
                "type": "rich_text_preformatted",
                "elements": [
                  {
                    "type": "text",
                    "text": "#{journal.notes}"
                  }
                ]
              } : nil
            ].select{|x| not x.nil?}
          }
        ]
      }

      notify payload
    end

    private

    def notify(payload)
      incoming_webhook_url = Setting.plugin_redmine_slack['incoming_webhook_url']

      return unless incoming_webhook_url

      begin
        notifier = Slack::Notifier.new incoming_webhook_url
        notifier.post payload
      rescue Exception => e
        Rails.logger.warn(e)
      end
    end

    def enabled_inform(project)
      inform_projects = Setting.plugin_redmine_slack['inform_projects']

      return unless inform_projects
      return inform_projects.include?(project.id.to_s)
    end
  end
end
