require "rails_helper"
require "fileutils"

RSpec.describe "Stimulus controller hotswap on Turbo navigation", type: :system, js: true do
  before { reset_javascript_files! }
  after { reset_javascript_files! }

  it "baseline sanity check" do
    visit "/"

    expect(page).to have_content("Page One")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")
    click_link "Go to Two with Turbo"

    expect(page).to have_content("Page Two")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")
    click_link "Go to One with Turbo"

    expect(page).to have_content("Page One")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")
    click_link "Go to Two without Turbo"

    expect(page).to have_content("Page Two")
    expect(page).to have_been_loaded(2).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")
    click_link "Go to One without Turbo"

    expect(page).to have_content("Page One")
    expect(page).to have_been_loaded(3).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")
  end

  it "performs detects changed controllers on turbo visit and dynamically reloads them" do
    visit "/"

    expect(page).to have_content("Page One")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")

    gsub_file controller_path("version"),
      "this.element.textContent = version",
      "this.element.textContent = 'v2'"

    click_link "Go to Two with Turbo"

    expect(page).to have_content("Page Two")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v2")
    expect(page).to have_selector("#admin--version", text: "v1")
  end

  it "hot-swaps when a controller is removed" do
    visit "/"
    expect(page).to have_content("Page One")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")

    remove_file controller_path("version")

    click_link "Go to Two with Turbo"

    expect(page).to have_content("Page Two")
    expect(page).to have_been_loaded(1).times
    expect(page).to_not have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")
  end

  it "triggers full reload when non-controller imports change" do
    visit "/"
    expect(page).to have_content("Page One")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")

    gsub_file utility_path,
      "const version = 'v1'",
      "const version = 'v2'"

    click_link "Go to Two with Turbo"

    sleep 1
    expect(page).to have_content("Page Two")
    expect(page).to have_been_loaded(2).times
    expect(page).to have_selector("#version", text: "v2")
    expect(page).to have_selector("#admin--version", text: "v2")
  end

  it "hot-swaps namespaced controllers (admin/version)" do
    visit "/"
    expect(page).to have_content("Page One")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "v1")

    gsub_file controller_path("admin/version"),
      "this.element.textContent = version",
      "this.element.textContent = 'admin-v2'"

    click_link "Go to Two with Turbo"

    expect(page).to have_content("Page Two")
    expect(page).to have_been_loaded(1).times
    expect(page).to have_selector("#version", text: "v1")
    expect(page).to have_selector("#admin--version", text: "admin-v2")
  end

  def reset_javascript_files!
    if system("git diff --quiet HEAD -- #{javascript_path}")
      # puts "no changes"
    else
      system "git checkout -- #{javascript_path}"
      raise "Failed to reset javascript files" unless $?.success?
      sleep 1
      # puts "changes"
    end
  end

  def remove_file path
    FileUtils.rm(path)
    sleep 1
  end

  def gsub_file(path, flag, *args, &block)
    content = File.read(path)
    content.gsub! flag, *args, &block
    File.write(path, content)
    sleep 1
  end

  def controller_path controller
    File.join(javascript_path, "controllers/#{controller}_controller.js")
  end

  def utility_path
    File.join(javascript_path, "utility.js")
  end

  def javascript_path
    File.expand_path("../dummy/app/javascript", __dir__)
  end
end
