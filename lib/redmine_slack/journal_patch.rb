module RedmineSlack
  module JournalPatch
    def self.included(klass)
      klass.send(:extend, ClassMethods)
      klass.send(:include, InstanceMethods)

      klass.class_eval do
        unloadable
        after_create_commit :create_journal
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def create_journal
        Redmine::Hook.call_hook(:redmine_slack_create_journal, {:journal => self})
      end
    end
  end
end

Journal.send(:include, RedmineSlack::JournalPatch)
