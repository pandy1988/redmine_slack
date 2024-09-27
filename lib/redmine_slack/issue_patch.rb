module RedmineSlack
  module IssuePatch
    def self.included(klass)
      klass.send(:extend, ClassMethods)
      klass.send(:include, InstanceMethods)

      klass.class_eval do
        unloadable
        after_create_commit :create_issue
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def create_issue
        Redmine::Hook.call_hook(:redmine_slack_create_issue, {:issue => self})
      end
    end
  end
end

Issue.send(:include, RedmineSlack::IssuePatch)
