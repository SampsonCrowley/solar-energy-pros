# encoding: utf-8
# frozen_string_literal: true

namespace :db do
  desc 'Drop All Attachments'
  task drop_attachments: :environment do
    ActiveStorage::Blob.delete_all
    ActiveStorage::Attachment.delete_all
  end

  desc 'Wait for any current migrations to complete before migrating'
  task migrate_when_open: :load_config do
    puts Rails.env
    retries = 0
    begin
      Rake::Task['db:migrate'].invoke
    rescue ActiveRecord::ConcurrentMigrationError
      unless (retries > 14) || (ActiveRecord::ConcurrentMigrationError::RELEASE_LOCK_FAILED_MESSAGE == $!.message)
        puts $!.message,
             "waiting: #{sleep_for = (retries * (retries += 1) / 2)} seconds"

        sleep sleep_for

        [
          'db:migrate',
        ].map {|t| Rake::Task[t].reenable}

        retry
      else
        raise
      end
    end
  end
end
