require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MatchInfoPdfxVersions do

  it "fails if argument is not a Hash" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)

    expect{ Preflight::Rules::MatchInfoPdfxVersions.new(/PDF\/X/).check_hash(ohash) }.to raise_error(ArgumentError)
  end

  context "when providing a file that is not compliant with given PDFX versions" do
    it "returns an list of errors" do
      pdfx_1a_required_keys = {:GTS_PDFXVersion => /PDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}
      pdfx_4_required_keys  = {:GTS_PDFXVersion => /PDF\/X-4/}
      rule_attrs            = {PDFX_1a: pdfx_1a_required_keys, PDFX_4: pdfx_4_required_keys}
      filename              = pdf_spec_file("no_document_id")
      ohash                 = PDF::Reader::ObjectHash.new(filename)
      chk                   = Preflight::Rules::MatchInfoPdfxVersions.new(rule_attrs)

      chk.check_hash(ohash).should_not be_empty
    end

    it "includes format-specific errors" do
      pdfx_1a_required_keys = {:GTS_PDFXVersion => /PDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}
      pdfx_4_required_keys  = {:GTS_PDFXVersion => /PDF\/X-4/}
      rule_attrs            = {PDFX_1a: pdfx_1a_required_keys, PDFX_4: pdfx_4_required_keys}
      filename              = pdf_spec_file("no_document_id")
      ohash                 = PDF::Reader::ObjectHash.new(filename)
      chk                   = Preflight::Rules::MatchInfoPdfxVersions.new(rule_attrs)

      errors = chk.check_hash(ohash)

      errors.each { |error|  error.description[/Invalid file for PDFX_(1a|4)*/].should_not be_empty }
    end
  end

  it "succeeds if file is compliant with PDFX-1A version" do
    pdfx_1a_required_keys = {:GTS_PDFXVersion => /PDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}
    pdfx_4_required_keys  = {:GTS_PDFXVersion => /PDF\/X-4/}
    rule_attrs            = {PDFX_1a: pdfx_1a_required_keys, PDFX_4: pdfx_4_required_keys}
    filename              = pdf_spec_file("pdfx-1a-subsetting")
    ohash                 = PDF::Reader::ObjectHash.new(filename)
    chk                   = Preflight::Rules::MatchInfoPdfxVersions.new(rule_attrs)

    chk.check_hash(ohash).should be_empty
  end

  it "succeeds if file is compliant with PDFX-4 version" do
    pdfx_1a_required_keys = {:GTS_PDFXVersion => /PDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/}
    pdfx_4_required_keys  = {:GTS_PDFXVersion => /PDF\/X-4/}
    rule_attrs            = {PDFX_1a: pdfx_1a_required_keys, PDFX_4: pdfx_4_required_keys}
    filename              = pdf_spec_file("pdfx-4")
    ohash                 = PDF::Reader::ObjectHash.new(filename)
    chk                   = Preflight::Rules::MatchInfoPdfxVersions.new(rule_attrs)

    chk.check_hash(ohash).should be_empty
  end
end
