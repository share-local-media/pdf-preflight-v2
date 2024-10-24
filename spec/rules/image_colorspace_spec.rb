require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::ImageColorspace do
  before(:all) do
    $DEBUG = true  # Enable debug output for all tests in this file
  end

  after(:all) do
    $DEBUG = false # Disable debug output after tests complete
  end

  let(:rgb_pdf_path) { pdf_spec_file("color-space-rgb") }
  let(:cmyk_pdf_path) { pdf_spec_file("color-space-cymk") }
  let(:prophoto_pdf_path) { pdf_spec_file("prophoto-rgb") } # Assuming this is the path to a PDF with ProPhoto RGB

  describe "ColorSpaceInfo" do
    let(:color_info) { Preflight::Rules::ImageColorspace::ColorSpaceInfo }

    it "correctly identifies DeviceRGB color space" do
      PDF::Reader.open(rgb_pdf_path) do |reader|
        page = reader.page(1)
        # Use page.xobjects instead of resources
        image = page.xobjects.values.find { |xobj|
          xobj.hash[:Subtype] == :Image
        }

        info = color_info.new(image)
        expect(info.base_type).to eq(:DeviceRGB)
        expect(info.components).to eq(3)
        expect(info.bit_depth).to be_between(1, 16) # Usually 8
      end
    end

    it "correctly identifies CMYK color space" do
      PDF::Reader.open(cmyk_pdf_path) do |reader|
        page = reader.page(1)
        image = page.xobjects.values.find { |xobj|
          xobj.hash[:Subtype] == :Image
        }

        info = color_info.new(image)
        expect(info.base_type).to eq(:DeviceCMYK)
        expect(info.components).to eq(4)
      end
    end

    it "detects presence of alpha channel" do
      PDF::Reader.open(rgb_pdf_path) do |reader|
        page = reader.page(1)
        image = page.xobjects.values.find { |xobj|
          xobj.hash[:Subtype] == :Image &&
          (xobj.hash[:SMask] || xobj.hash[:Mask])
        }

        if image
          info = color_info.new(image)
          expect(info.has_alpha).to be true
        end
      end
    end

    it "correctly formats color space information as string" do
      PDF::Reader.open(rgb_pdf_path) do |reader|
        page = reader.page(1)
        image = page.xobjects.values.find { |xobj|
          xobj.hash[:Subtype] == :Image
        }

        info = color_info.new(image)
        expect(info.to_s).to include("Type:")
        expect(info.to_s).to include("Components:")
        expect(info.to_s).to include("Bits/Component:")
      end
    end
  end

  describe "Rule Implementation" do
    let(:rule) { Preflight::Rules::ImageColorspace.new(:DeviceRGB) }

    it "accepts files with allowed color spaces" do
      PDF::Reader.open(rgb_pdf_path) do |reader|
        issues = rule.check_page(reader.page(1))
        expect(issues).to be_empty
      end
    end

    it "rejects files with disallowed color spaces" do
      rule = Preflight::Rules::ImageColorspace.new(:DeviceRGB) # Only allow RGB

      PDF::Reader.open(cmyk_pdf_path) do |reader|
        issues = rule.check_page(reader.page(1))
        expect(issues).not_to be_empty
        expect(issues.first.description).to include("invalid color space")
      end
    end

    it "handles multiple allowed color spaces" do
      rule = Preflight::Rules::ImageColorspace.new(:DeviceRGB, :DeviceCMYK, :DeviceN)

      [rgb_pdf_path, cmyk_pdf_path].each do |path|
        PDF::Reader.open(path) do |reader|
          issues = rule.check_page(reader.page(1))
          expect(issues).to be_empty
        end
      end
    end

    context "with ICC profiles" do
      let(:rule) { Preflight::Rules::ImageColorspace.new(:ICCBased) }

      it "detects ICC-based color spaces" do
        PDF::Reader.open(rgb_pdf_path) do |reader|
          page = reader.page(1)
          image = page.xobjects.values.find { |xobj|
            xobj.hash[:Subtype] == :Image &&
            xobj.hash[:ColorSpace].is_a?(Array) &&
            xobj.hash[:ColorSpace][0] == :ICCBased
          }

          if image
            info = Preflight::Rules::ImageColorspace::ColorSpaceInfo.new(image)
            expect(info.base_type).to eq(:ICCBased)
            # The actual profile name should be present
            expect(info.icc_profile).not_to be_nil
            puts "Found ICC Profile: #{info.icc_profile}"
          end
        end
      end

      it "identifies common ICC profiles" do
        PDF::Reader.open(rgb_pdf_path) do |reader|
          page = reader.page(1)
          page.xobjects.each do |name, xobj|
            next unless xobj.hash[:Subtype] == :Image
            next unless xobj.hash[:ColorSpace].is_a?(Array) &&
                      xobj.hash[:ColorSpace][0] == :ICCBased

            info = Preflight::Rules::ImageColorspace::ColorSpaceInfo.new(xobj)
            puts "Image #{name} ICC Profile: #{info.icc_profile}"

            # The profile should be one of the known types or a custom name
            expect(info.icc_profile).to satisfy { |profile|
              profile.is_a?(String) || [:DeviceRGB, :DeviceCMYK, :DeviceGray].include?(profile)
            }
          end
        end
      end
    end

    context "with indexed color spaces" do
      let(:rule) { Preflight::Rules::ImageColorspace.new(:Indexed) }

      it "detects indexed color spaces" do
        PDF::Reader.open(rgb_pdf_path) do |reader|
          page = reader.page(1)
          image = page.xobjects.values.find { |xobj|
            xobj.hash[:Subtype] == :Image &&
            xobj.hash[:ColorSpace].is_a?(Array) &&
            xobj.hash[:ColorSpace][0] == :Indexed
          }

          if image
            info = Preflight::Rules::ImageColorspace::ColorSpaceInfo.new(image)
            expect(info.base_type).to eq(:Indexed)
            expect(info.components).to eq(1)
          end
        end
      end
    end

    context "with blacklisted color profiles" do
      let(:rule) { Preflight::Rules::ImageColorspace.new(:DeviceRGB, blacklist: ['ProPhoto RGB']) }

      it "flags images using ProPhoto RGB as blacklisted" do
        PDF::Reader.open(prophoto_pdf_path) do |reader|
          issues = rule.check_page(reader.page(1))
          puts "Issues: #{issues.inspect}"
          expect(issues).not_to be_empty
          expect(issues.first.description).to include("blacklisted ICC profile")
          expect(issues.first.description).to include("ProPhoto RGB")
        end
      end
    end
  end
end
