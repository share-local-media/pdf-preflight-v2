begin
  require 'prawn'
  require 'mini_magick'
rescue LoadError
  warn "Prawn or MiniMagick gem not found. PDF sample generation will be disabled."
  module PDFSamples
    def self.create_test_pdfs
      warn "PDF sample generation is disabled because required gems are not available."
    end
  end
else
  module PDFSamples
    SAMPLES_DIR = "spec/pdf"
    ICC_PROFILES = [
      "/usr/share/color/icc/sRGB.icc",           # Linux
      "/usr/local/share/color/icc/sRGB.icc",     # macOS
      "/Windows/System32/spool/drivers/color/sRGB Color Space Profile.icm" # Windows
    ]

    def self.create_test_pdfs
      # Check if ImageMagick is installed
      imagemagick_installed = ENV['PATH'].split(File::PATH_SEPARATOR).any? do |directory|
        File.exist?(File.join(directory, 'magick')) || File.exist?(File.join(directory, 'convert'))
      end

      unless imagemagick_installed
        warn "ImageMagick not found. Please install ImageMagick to generate PDF samples."
        return
      end

      FileUtils.mkdir_p(SAMPLES_DIR)
      create_rgb_pdf
      create_cmyk_pdf
      create_indexed_pdf
      create_icc_pdf
    end

    private

    def self.create_rgb_pdf
      temp_file = Tempfile.new(['rgb', '.png'])
      begin
        # Create RGB image using MiniMagick
        MiniMagick::Tool::Magick.new do |magick|
          magick << "xc:red"
          magick.size "200x200"
          magick << temp_file.path
        end

        Prawn::Document.generate(File.join(SAMPLES_DIR, "test_rgb.pdf")) do |pdf|
          pdf.text "RGB Color Space Test"
          pdf.move_down 20
          pdf.image temp_file.path, at: [50, pdf.cursor], width: 100
        end
      ensure
        temp_file.close
        temp_file.unlink
      end
    rescue => e
      warn "Failed to create RGB test PDF: #{e.message}"
    end

    def self.create_cmyk_pdf
      temp_file = Tempfile.new(['cmyk', '.jpg'])
      begin
        MiniMagick::Tool::Magick.new do |magick|
          magick << "xc:cyan"
          magick.size "200x200"
          magick.colorspace "CMYK"
          magick << temp_file.path
        end

        Prawn::Document.generate(File.join(SAMPLES_DIR, "test_cmyk.pdf")) do |pdf|
          pdf.text "CMYK Color Space Test"
          pdf.move_down 20
          pdf.image temp_file.path, at: [50, pdf.cursor], width: 100
        end
      ensure
        temp_file.close
        temp_file.unlink
      end
    rescue => e
      warn "Failed to create CMYK test PDF: #{e.message}"
    end

    def self.create_indexed_pdf
      temp_file = Tempfile.new(['indexed', '.png'])
      begin
        MiniMagick::Tool::Magick.new do |magick|
          magick << "gradient:red-blue"
          magick.size "200x200"
          magick.colors "16"
          magick.type "Palette"
          magick << temp_file.path
        end

        Prawn::Document.generate(File.join(SAMPLES_DIR, "test_indexed.pdf")) do |pdf|
          pdf.text "Indexed Color Space Test"
          pdf.move_down 20
          pdf.image temp_file.path, at: [50, pdf.cursor], width: 100
        end
      ensure
        temp_file.close
        temp_file.unlink
      end
    rescue => e
      warn "Failed to create indexed color space test PDF: #{e.message}"
    end

    def self.create_icc_pdf
      temp_file = Tempfile.new(['icc', '.jpg'])
      begin
        # Find available ICC profile
        icc_profile = ICC_PROFILES.find { |profile| File.exist?(profile) }

        unless icc_profile
          warn "No ICC profile found. Skipping ICC PDF generation."
          return
        end

        # Create image with ICC profile
        MiniMagick::Tool::Magick.new do |magick|
          magick << "gradient:red-blue"
          magick.size "200x200"
          magick.profile icc_profile
          magick << temp_file.path
        end

        # Verify ICC profile is embedded
        img = MiniMagick::Image.new(temp_file.path)
        unless img.data["properties"]["Profile-icc"]
          warn "ICC profile not properly embedded. Skipping ICC PDF generation."
          return
        end

        Prawn::Document.generate(File.join(SAMPLES_DIR, "test_icc.pdf")) do |pdf|
          pdf.text "ICC Profile Color Space Test"
          pdf.move_down 20
          pdf.image temp_file.path, at: [50, pdf.cursor], width: 100
        end
      ensure
        temp_file.close
        temp_file.unlink
      end
    rescue => e
      warn "Failed to create ICC profile test PDF: #{e.message}"
    end
  end
end
