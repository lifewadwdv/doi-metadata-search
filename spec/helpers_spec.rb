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

  context "prefix_format" do
    it "zero prefixes" do
      attributes = { "prefixes" => [] }
      response = subject.prefix_format(attributes)
      expect(response).to eq("")
    end

    it "one prefix" do
      attributes = { "prefixes" => ["10.5438"] }
      response = subject.prefix_format(attributes)
      expect(response).to eq("Prefix: 10.5438")
    end

    it "two prefixes" do
      attributes = { "prefixes" => ["10.5438", "10.14454"] }
      response = subject.prefix_format(attributes)
      expect(response).to eq("Prefixes: 10.5438 10.14454")
    end
  end

  context "creative_work_type" do
    it "dataset" do
      attributes = { "resource-type-id" => "dataset" }
      response = subject.creative_work_type(attributes)
      expect(response).to eq("Dataset")
    end

    it "unknown" do
      attributes = { "resource-type-id" => "unknown" }
      response = subject.creative_work_type(attributes)
      expect(response).to eq("CreativeWork")
    end
  end
end
