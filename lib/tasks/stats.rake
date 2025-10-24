namespace :stats do
  desc "Record daily stats for all institutions"
  task record_daily: :environment do
    puts "Recording stats for today..."

    Institution.find_each do |institution|
      stat = InstitutionStat.record_daily(institution)
      puts "#{institution.name}: #{stat.total_documents} docs, #{stat.active_staff} staff, #{ActiveSupport::NumberHelper.number_to_human_size(stat.storage_used)}"
    end

    puts "\nDone!"
  end
end