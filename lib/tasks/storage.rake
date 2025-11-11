namespace :storage do
  desc "Backfill file_size for all Documents and recalculate institution storage_used"
  task backfill: :environment do
    puts "Backfilling document sizes for Documents..."

    Document.find_each do |document|
      if document.file.attached?
        size = document.file.byte_size
        document.update_column(:file_size, size)
        print "."
      end
    end

    puts "\nRecalculating storage_used for all institutions..."

    Institution.find_each do |institution|
      old_storage = institution.storage_used
      new_storage = institution.recalculate_storage!
      puts "#{institution.name}: #{ActiveSupport::NumberHelper.number_to_human_size(old_storage)} -> #{ActiveSupport::NumberHelper.number_to_human_size(new_storage)}"
    end

    puts "\nDone!"
  end

  desc "Verify storage calculations are correct"
  task verify: :environment do
    Institution.find_each do |institution|
      calculated = institution.documents.sum(:file_size)
      stored = institution.storage_used

      if calculated == stored
        puts "✓ #{institution.name}: #{ActiveSupport::NumberHelper.number_to_human_size(stored)}"
      else
        puts "✗ #{institution.name}: Mismatch! Calculated: #{ActiveSupport::NumberHelper.number_to_human_size(calculated)}, Stored: #{ActiveSupport::NumberHelper.number_to_human_size(stored)}"
      end
    end
  end
end
