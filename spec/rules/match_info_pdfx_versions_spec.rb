require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MatchInfoPdfxVersions do

  it "fails if argument is not a Hash" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)

    expect{ Preflight::Rules::MatchInfoPdfxVersions.new(/PDF\/X/).check_hash(ohash) }.to raise_error(ArgumentError)
  end

  let(:ohash) { PDF::Reader::ObjectHash.new(filename) }
  let(:chk)   { Preflight::Rules::MatchInfoPdfxVersions.new(checks) }
  let(:checks) do
    {
      PDFX_1a: [
        Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /\APDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/),
        Preflight::Rules::MaxVersion.new(1.4)
      ],
      PDFX_4: [
        Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /\APDF\/X-4/),
        Preflight::Rules::MaxVersion.new(1.6)
      ]
    }
  end

  context "when providing a file that is not compliant at all with given PDFX versions" do
    let(:filename) { pdf_spec_file("no_document_id") }

    it "returns an list of errors" do
      chk.check_hash(ohash).should_not be_empty
    end

    it "includes format-specific errors" do
      errors = chk.check_hash(ohash)

      errors.each { |error|  error.description[/Invalid file for PDFX_(1a|4)*/].should_not be_empty }
    end
  end

  context "when providing a file that is not compliant with on of the PDFX attributes on a version" do
    let(:checks) do
      {
        PDFX_1a: [
          Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /\APDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/),
          Preflight::Rules::MaxVersion.new(1.3) # Set 1.3 as max allowed version for pdfx_1a
        ],
        PDFX_4: [
          Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /\APDF\/X-4/),
          Preflight::Rules::MaxVersion.new(1.6)
        ]
      }
    end

    let(:filename) { pdf_spec_file("version_1_4") }

    it "returns an list of errors" do
      errors = chk.check_hash(ohash)

      pdfx_1a_error = errors.first.description
      pdfx_4_error  = errors.last.description

      pdfx_1a_error[/Invalid file for PDFX_1a(.)+max_version=>1\.3(.)+current_version=>1\.4/].should_not be_nil
      pdfx_4_error[/PDFX_4(.)+invalid(.)+key=>:GTS_PDFXVersion/].should_not be_nil
    end
  end

  context "when providing a file that is compliant with PDFX-1a versions" do
    let(:filename) { pdf_spec_file("pdfx-1a-subsetting") }

    it "succeeds if file is compliant with PDFX-1A version" do
      chk.check_hash(ohash).should be_empty
    end
  end

  context "when providing a file that is compliant with PDFX-4 versions" do
    let(:filename) { pdf_spec_file("pdfx-4") }

    it "succeeds if file is compliant with PDFX-4 version" do
      chk.check_hash(ohash).should be_empty
    end
  end
end
