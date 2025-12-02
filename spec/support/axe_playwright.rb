require 'json'

module AxePlaywright
  AXE_SCRIPT = begin
    gem_path = Gem.loaded_specs['axe-core-api']&.full_gem_path
    if gem_path
      File.read(File.join(gem_path, 'node_modules', 'axe-core', 'axe.min.js'))
    else
      raise "axe-core-api gem not found"
    end
  end

  module_function

  def run_axe(capybara_page, options = {})
    capybara_page.driver.with_playwright_page do |playwright_page|
      playwright_page.evaluate(AXE_SCRIPT)

      script =
        if options.empty?
          "axe.run()"
        else
          "axe.run(document, #{options.to_json})"
        end

      results = playwright_page.evaluate(script)
      return results['violations'] || []
    end
  end

  def build_failure_message(violations)
    return "No accessibility violations found." if violations.nil? || violations.empty?

    lines = [ "Found #{violations.length} accessibility violation(s):" ]

    violations.each_with_index do |violation, index|
      lines << ""
      lines << "#{index + 1}. #{violation['help']} (#{violation['id']})"
      lines << "   Impact: #{violation['impact']}"
      lines << "   Description: #{violation['description']}"
      lines << "   Help: #{violation['helpUrl']}" if violation['helpUrl']
      lines << "   Affected nodes: #{violation['nodes'].length}"

      violation['nodes'].each do |node|
        target = Array(node['target']).first
        lines << "   - Target: #{target}" if target
        lines << "     HTML: #{node['html']}" if node['html']
      end
    end

    lines.join("\n")
  end
end

RSpec::Matchers.define :be_axe_clean do
  match do |page|
    @violations = AxePlaywright.run_axe(page, @axe_options || {})
    @violations.empty?
  end

  chain :with_axe_options do |options|
    @axe_options = options
  end

  failure_message do
    AxePlaywright.build_failure_message(@violations)
  end
end
