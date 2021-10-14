require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MatchInfoPdfxVersions do

  it "fails if argument is not an Array" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)

    expect{
      Preflight::Rules::MatchInfoPdfxVersions.new(:GTS_PDFXVersion => /PDF\/X/).check_hash(ohash)
    }.to raise_error(ArgumentError)
  end

  it "fails with files that are missing required PDF keys the Info dict" do
    pdfx_1a_required_keys = {:GTS_PDFXVersion => /PDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}
    rule_attrs            = [pdfx_1a_required_keys]
    filename              = pdf_spec_file("no_document_id")
    ohash                 = PDF::Reader::ObjectHash.new(filename)
    chk                   = Preflight::Rules::MatchInfoPdfxVersions.new(rule_attrs)

    chk.check_hash(ohash).should_not be_empty
  end

  it "passes with files with GTS_PDFXVersion PDF-X entry in the Info dict" do
    pdfx_1a_required_keys = {:GTS_PDFXVersion => /PDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}
    rule_attrs            = [pdfx_1a_required_keys]
    filename              = pdf_spec_file("pdfx-1a-subsetting")
    ohash                 = PDF::Reader::ObjectHash.new(filename)
    chk                   = Preflight::Rules::MatchInfoPdfxVersions.new(rule_attrs)

    chk.check_hash(ohash).should be_empty
  end

  it "passes with files with GTS_PDFXVersion PDFX-4 entry in the Info dict" do
    pdfx_4_required_keys = {:GTS_PDFXVersion => /PDF\/X-4/}
    rule_attrs           = [pdfx_4_required_keys]
    filename             = pdf_spec_file("pdfx-4")
    ohash                = PDF::Reader::ObjectHash.new(filename)
    chk                  = Preflight::Rules::MatchInfoPdfxVersions.new(rule_attrs)

    chk.check_hash(ohash).should be_empty
  end
end
