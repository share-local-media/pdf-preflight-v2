# coding: utf-8

module Preflight
  module Profiles
    class BasePDFX
      include Preflight::Profile

      profile_name "base-pdfx"

      rule Preflight::Rules::MatchInfoPdfxVersions, {
        PDFX_1a: [
          Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /\APDF\/X/, :GTS_PDFXConformance => /\APDF\/X-1a/),
          Preflight::Rules::MaxVersion.new(1.4)
        ],
        PDFX_4: [
          Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /\APDF\/X-4/),
          Preflight::Rules::MaxVersion.new(1.6)
        ]
      }
      rule Preflight::Rules::RootHasKeys, :OutputIntents
      rule Preflight::Rules::InfoHasKeys, :Title, :CreationDate, :ModDate
      rule Preflight::Rules::InfoSpecifiesTrapping
      rule Preflight::Rules::CompressionAlgorithms, :ASCII85Decode, :CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode
      rule Preflight::Rules::DocumentId
      rule Preflight::Rules::NoFilespecs
      rule Preflight::Rules::NoTransparency
      rule Preflight::Rules::OnlyEmbeddedFonts
      rule Preflight::Rules::BoxNesting
      rule Preflight::Rules::PrintBoxes
      rule Preflight::Rules::OutputIntentForPdfx
      rule Preflight::Rules::PdfxOutputIntentHasKeys, :OutputConditionIdentifier, :Info
      rule Preflight::Rules::NoRgb
    end
  end
end
