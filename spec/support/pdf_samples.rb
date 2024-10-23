begin
  require 'prawn'
rescue LoadError
  warn "Prawn gem not found. PDF sample generation will be disabled."
  module PDFSamples
    def self.create_test_pdfs
      warn "PDF sample generation is disabled because the prawn gem is not available."
    end
  end
else
  module PDFSamples
    def self.create_test_pdfs
      create_rgb_pdf
      create_cmyk_pdf
      create_indexed_pdf
      create_icc_pdf
    end

    private

    def self.create_rgb_pdf
      Prawn::Document.generate("spec/pdf/test_rgb.pdf") do |pdf|
        # Create RGB image and embed it
      end
    rescue => e
      warn "Failed to create RGB test PDF: #{e.message}"
    end

    def self.create_cmyk_pdf
      Prawn::Document.generate("spec/pdf/test_cmyk.pdf") do |pdf|
        # Create CMYK image and embed it
      end
    rescue => e
      warn "Failed to create CMYK test PDF: #{e.message}"
    end

    def self.create_indexed_pdf
      Prawn::Document.generate("spec/pdf/test_indexed.pdf") do |pdf|
        # Create indexed color space PDF
      end
    rescue => e
      warn "Failed to create indexed color space test PDF: #{e.message}"
    end

    def self.create_icc_pdf
      Prawn::Document.generate("spec/pdf/test_icc.pdf") do |pdf|
        # Create ICC profile PDF
      end
    rescue => e
      warn "Failed to create ICC profile test PDF: #{e.message}"
    end
  end
end
