RSpec::Matchers.define :have_been_loaded do |expected|
  match do |page|
    @expected = expected
    @actual = extract_load_count(page)
    values_match?(@expected, @actual)
  end

  chain :times do
    # Enables readable syntax: expect(page).to have_been_loaded(1).times
  end

  failure_message do |_page|
    "expected sessionStorage.fullReloadCount to equal #{@expected}, but was #{@actual}"
  end

  failure_message_when_negated do |_page|
    "expected sessionStorage.fullReloadCount not to equal #{@expected}"
  end

  description do
    "have sessionStorage.fullReloadCount equal to #{@expected}"
  end

  def extract_load_count(page)
    page.evaluate_script("Number(sessionStorage.fullReloadCount || 0)")
  end
end
