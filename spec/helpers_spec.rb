require 'spec_helper'

describe "Helpers", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "license_img" do
    it "understands CC Zero" do
      license = "https://creativecommons.org/publicdomain/zero/1.0/"
      expect(subject.license_img(license)).to eq("<i class=\"cc cc-cc\"> </i> <i class=\"cc cc-zero\"> </i>")
    end

    it "understands CC-BY" do
      license = "https://creativecommons.org/licenses/by/4.0/"
      expect(subject.license_img(license)).to eq("<i class=\"cc cc-cc\"> </i> <i class=\"cc cc-by\"> </i>")
    end

    it "understands CC-BY-NC" do
      license = "https://creativecommons.org/licenses/by-nc/4.0/"
      expect(subject.license_img(license)).to eq("<i class=\"cc cc-cc\"> </i> <i class=\"cc cc-by\"> </i> <i class=\"cc cc-nc\"> </i>")
    end

    it "understands CC-BY-SA" do
      license = "https://creativecommons.org/licenses/by-sa/4.0/"
      expect(subject.license_img(license)).to eq("<i class=\"cc cc-cc\"> </i> <i class=\"cc cc-by\"> </i> <i class=\"cc cc-sa\"> </i>")
    end

    it "understands CC-BY-NC-ND" do
      license = "https://creativecommons.org/licenses/by-nc-nd/4.0/"
      expect(subject.license_img(license)).to eq("<i class=\"cc cc-cc\"> </i> <i class=\"cc cc-by\"> </i> <i class=\"cc cc-nc\"> </i> <i class=\"cc cc-nd\"> </i>")
    end

    it "understands CC url" do
      license = "https://creativecommons.org/"
      expect(subject.license_img(license)).to eq("<i class=\"cc cc-cc\"> </i>")
    end

    it "understands MIT" do
      license = "https://opensource.org/licenses/MIT"
      expect(subject.license_img(license)).to eq("<img src=\"https://img.shields.io/:license-MIT-blue.svg\" />")
    end

    it "understands Apache 2.0" do
      license = "https://opensource.org/licenses/Apache-2.0"
      expect(subject.license_img(license)).to eq("<img src=\"https://img.shields.io/:license-Apache%202.0-blue.svg\" />")
    end

    it "understands GPL 3.0" do
      license = "https://opensource.org/licenses/GPL-3.0"
      expect(subject.license_img(license)).to eq("<img src=\"https://img.shields.io/:license-GPL%203.0-blue.svg\" />")
    end

    it "understands Mozilla Public License" do
      license = "https://opensource.org/licenses/MPL-2.0"
      expect(subject.license_img(license)).to eq("<img src=\"https://img.shields.io/:license-MPL%202.0-blue.svg\" />")
    end
  end

  context "validate_orcid" do
    it "validate_orcid" do
      orcid = "https://orcid.org/0000-0002-2590-225X"
      response = subject.validate_orcid(orcid)
      expect(response).to eq("0000-0002-2590-225X")
    end

    it "validate_orcid id" do
      orcid = "0000-0002-2590-225X"
      response = subject.validate_orcid(orcid)
      expect(response).to eq("0000-0002-2590-225X")
    end

    it "validate_orcid wrong id" do
      orcid = "0000 0002 1394 3097"
      response = subject.validate_orcid(orcid)
      expect(response).to be_nil
    end
  end

  context "validate_doi" do
    it "validate_doi" do
      doi = "https://doi.org/10.6084/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to eq("10.6084/M9.FIGSHARE.3501629")
    end

    it "validate_doi https" do
      doi = "https://doi.org/10.6084/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to eq("10.6084/M9.FIGSHARE.3501629")
    end

    it "validate_doi id" do
      doi = "10.6084/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to eq("10.6084/M9.FIGSHARE.3501629")
    end

    it "validate_doi wrong id" do
      doi = "10.abc/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to be_nil
    end
  end

  context "reduce_aggs" do
    let(:meta) {file_fixture('usage_metrics_meta.json').read}
    let(:empty_meta) {{}}

    it "reduce for usage" do
      relation_types = subject.reduce_aggs(meta,{yop: 2015})
      expect(relation_types).to have_key("total-dataset-requests-regular")
      expect(relation_types.size).to eq(6)
      expect(relation_types.dig("total-dataset-investigations-regular")).to be(635)
      expect(relation_types.dig("unique-dataset-investigations-regular")).to be(371)
      expect(relation_types.dig("total-dataset-requests-regular")).to be(34)
      expect(relation_types.dig("unique-dataset-requests-regular")).to be(27)
      expect(relation_types.dig("total-dataset-investigations-machine")).to be(1)
      expect(relation_types.dig("unique-dataset-investigations-machine")).to be(1)
    end

    it "reduce when there is no meta" do
      relation_types = subject.reduce_aggs(empty_meta,{yop: 2015})
      expect(relation_types.size).to eq(0)
    end

    it "reduce with out of bounds data" do
      relation_types = subject.reduce_aggs(meta,{yop: 2017})
      expect(relation_types.size).to eq(6)
      expect(relation_types.dig("unique-dataset-investigations-regular")).to be(31)
      expect(relation_types.dig("total-dataset-requests-regular")).to be(0)
      expect(relation_types.dig("total-dataset-investigations-regular")).to be(0)
      expect(relation_types.dig("total-dataset-requests-regular")).to be(0)
      expect(relation_types.dig("unique-dataset-requests-regular")).to be(0)
      expect(relation_types.dig("total-dataset-investigations-machine")).to be(0)
      expect(relation_types.dig("unique-dataset-investigations-machine")).to be(0)
    end
  end

  context "filter_relation_types" do
    let(:metrics) {{"references"=>"2165", "has-part"=>"1", "is-cited-by"=>"2", "total-dataset-investigations-regular"=>"40"}}
    let(:usage) {{ "has-part"=>"1",  "total-dataset-investigations-regular"=>"40"}}

    it "filter for citations" do
      citations = subject.filter_relation_types(metrics)
      expect(citations).to eq(2167)
    end

    it "no citations" do
      citations = subject.filter_relation_types(usage)
      expect(citations).to eq(0)
    end
  end



  context "helpers" do
    it "relation_type_title" do
      related_identifiers = [{ "relation-type-id" => "HasPart",
                               "related-identifier" => "https://doi.org/10.5061/DRYAD.T748P/1" }]
      id = "https://doi.org/10.5061/DRYAD.T748P/1"
      response = subject.relation_type_title(related_identifiers, id)
      expect(response).to eq("Is part of")
    end

    it "missing" do
      related_identifiers = [{ "relation-type-id" => "HasPart",
                               "related-identifier" => "https://doi.org/10.5061/DRYAD.T748P/2" }]
      id = "https://doi.org/10.5061/DRYAD.T748P/1"
      response = subject.relation_type_title(related_identifiers, id)
      expect(response).to eq("")
    end

    it "is identical" do
      related_identifiers = [{"relation-type-id"=>"IsIdenticalTo", "related-identifier"=>"https://doi.org/10.6084/M9.FIGSHARE.4621336"}]
      id = "https://doi.org/10.6084/M9.FIGSHARE.4621336"
      response = subject.relation_type_title(related_identifiers, id)
      expect(response).to eq("Is identical to")
    end
  end
end
