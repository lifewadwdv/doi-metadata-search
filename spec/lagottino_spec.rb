require 'spec_helper'

describe "Lagottino", type: :model, vcr: true, match_requests_on: [:method, :path] do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:jwt) { User.generate_token(role_id: "staff_admin") }
  let(:user) { User.new(jwt) }

  subject { ApiSearch.new }

  context "call_metrics" do
    # it "with works" do
    #   dois = ["10.7272/q6g15xs4", "10.5438/G59A-FBT2"]
    #   metrics = subject.call_metrics(dois)
    #   expect(metrics[:meta]["doisRelationTypes"].length).to eq(1)
    # end
  end
  
  context "merge_metrics" do
    it "with works" do
      items = subject.get_works(query: "10.7272/q6g15xs4")[:data]
      metrics = JSON.parse(File.read(fixture_path+"metrics_events.json"))
      merged_metrics = subject.merge_metrics(items.first, metrics.dig("meta","doisRelationTypes"))
      expect(merged_metrics.length).to eq(6)
      expect(merged_metrics).to be_a(Hash)
    end
  end
  
  context "get_metrics" do
    it "with works" do
      items = subject.get_works(query: "10.7272/q6g15xs4")[:data]
      items_with_metrics = subject.get_metrics(items)


      expect(items_with_metrics.first.dig("metrics")).to be_a(Hash)
      expect(items_with_metrics.first.dig("metrics").length).to be > 0
    end
  
    it "no works" do
      items = []
      items_with_metrics = subject.get_metrics(items)


      expect(items_with_metrics).to be_a(Array)
      expect(items_with_metrics.length).to be(0)
    end
  end
end
