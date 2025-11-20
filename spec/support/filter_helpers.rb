module FilterHelpers
  def expect_filter_count(html, name, count)
    doc = Nokogiri::HTML(html)
    label = doc.at("label:contains('#{name}')")
    expect(label).not_to be_nil
    count_span = label.css("span.text-xs").text
    expect(count_span).to eq(count.to_s)
  end
end

RSpec.configure do |config|
  config.include FilterHelpers, type: :request
end
