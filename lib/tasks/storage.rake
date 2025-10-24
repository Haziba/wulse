namespace :storage do
  desc "Backfill document_size for all OERs and recalculate institution storage_used"
  task backfill: :environment do
    puts "Backfilling document sizes for OERs..."

    Oer.find_each do |oer|
      if oer.document.attached?
        size = oer.document.byte_size
        oer.update_column(:document_size, size)
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
      calculated = institution.oers.sum(:document_size)
      stored = institution.storage_used

      if calculated == stored
        puts "✓ #{institution.name}: #{ActiveSupport::NumberHelper.number_to_human_size(stored)}"
      else
        puts "✗ #{institution.name}: Mismatch! Calculated: #{ActiveSupport::NumberHelper.number_to_human_size(calculated)}, Stored: #{ActiveSupport::NumberHelper.number_to_human_size(stored)}"
      end
    end
  end
end
