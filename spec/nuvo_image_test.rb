require 'minitest/autorun'
require 'nuvo_image'

def image_path(filename)
  File.join(File.dirname(__FILE__), 'images', filename)
end

describe NuvoImage::Process do
  before do
    test_image_dir = File.join(File.dirname(__FILE__), 'images/test')
    FileUtils.rm_rf(test_image_dir)
    FileUtils.mkdir_p(test_image_dir)
  end

  subject {NuvoImage::Process.new}

  describe '#read' do
    it 'should work' do
      images = [
        # [filename, width, height, size, frames]
        ['sushi.jpg', 960, 960, 116_306, nil],
        ['todd.gif', 320, 240, 472_973, 21],
        ['IA.png', 750, 1091, 562_086, nil],
        ['bag-exif.jpg', 552, 414, 62_735, nil],
        ['Untouched.jpg', 3096, 4128, 2_753_095, nil],
        ['black_pink.jpg', 260, 370, 162_246, 2], # gif but have .jpg extension
        ['rainbow_socks.jpg', 260, 370, 107_417, 10] # gif but have .jpg extension
      ]
      images.each do |filename, width, height, size, frames|
        i = subject.read image_path(filename)
        value(i.width).must_equal width
        value(i.height).must_equal height
        value(i.size).must_equal size
        if frames.nil?
          value(i.frames).must_be_nil
        else
          value(i.frames).must_equal frames
        end
      end
    end

    after do
      subject.close
    end
  end

  describe '#crop' do
    before do
      @sushi = subject.read image_path('sushi.jpg')
      @todd = subject.read image_path('todd.gif')
      @black_pink = subject.read image_path('black_pink.jpg')
      @rainbow_socks = subject.read image_path('rainbow_socks.jpg')
    end

    it 'should work' do
      {
        Center: [430, 455, 100, 50],
        North: [430, 0, 100, 50],
        South: [430, 910, 100, 50],
        East: [860, 455, 100, 50],
        West: [0, 455, 100, 50],
        NorthEast: [860, 0, 100, 50],
        NorthWest: [0, 0, 100, 50],
        SouthEast: [860, 910, 100, 50],
        SouthWest: [0, 910, 100, 50]
      }.each do |gravity, result|
        cropped = subject.crop(@sushi, 100, 50, gravity: gravity)
        value(cropped.gravity).must_equal gravity
        value([cropped.left, cropped.top, cropped.width, cropped.height]).must_equal result
        value(cropped.frames).must_be_nil
      end

      {
        Center: [110, 95, 100, 50],
        North: [110, 0, 100, 50],
        South: [110, 190, 100, 50],
        East: [220, 95, 100, 50],
        West: [0, 95, 100, 50],
        NorthEast: [220, 0, 100, 50],
        NorthWest: [0, 0, 100, 50],
        SouthEast: [220, 190, 100, 50],
        SouthWest: [0, 190, 100, 50]
      }.each do |gravity, result|
        cropped = subject.crop(@todd, 100, 50, gravity: gravity)
        value(cropped.gravity).must_equal gravity
        value([cropped.left, cropped.top, cropped.width, cropped.height]).must_equal result
        value(cropped.frames).must_equal 21
      end

      {
        Center: [80, 160, 100, 50],
        North: [80, 0, 100, 50],
        South: [80, 320, 100, 50],
        East: [160, 160, 100, 50],
        West: [0, 160, 100, 50],
        NorthEast: [160, 0, 100, 50],
        NorthWest: [0, 0, 100, 50],
        SouthEast: [160, 320, 100, 50],
        SouthWest: [0, 320, 100, 50]
      }.each do |gravity, result|
        cropped = subject.crop(@black_pink, 100, 50, gravity: gravity)
        value(cropped.gravity).must_equal gravity
        value([cropped.left, cropped.top, cropped.width, cropped.height]).must_equal result
        value(cropped.frames).must_equal 2
      end

      {
        Center: [80, 160, 100, 50],
        North: [80, 0, 100, 50],
        South: [80, 320, 100, 50],
        East: [160, 160, 100, 50],
        West: [0, 160, 100, 50],
        NorthEast: [160, 0, 100, 50],
        NorthWest: [0, 0, 100, 50],
        SouthEast: [160, 320, 100, 50],
        SouthWest: [0, 320, 100, 50]
      }.each do |gravity, result|
        cropped = subject.crop(@rainbow_socks, 100, 50, gravity: gravity)
        value(cropped.gravity).must_equal gravity
        value([cropped.left, cropped.top, cropped.width, cropped.height]).must_equal result
        value(cropped.frames).must_equal 10
      end
    end

    after do
      subject.close
    end
  end

  describe '#resize' do
    before do
      @sushi = subject.read image_path('sushi.jpg')
      @todd = subject.read image_path('todd.gif')
      @black_pink = subject.read image_path('black_pink.jpg')
      @rainbow_socks = subject.read image_path('rainbow_socks.jpg')
    end

    it 'should work' do
      interpolations = %i[nearest linear cubic area lanczos]
      images = [
        [@sushi, nil],
        [@todd, 21],
        [@black_pink, 2],
        [@rainbow_socks, 10]
      ]
      images.each do |image, frames|
        interpolations.each do |interpolation|
          resized = subject.resize(image, 100, 50, interpolation: interpolation)
          value(resized.width).must_equal 100
          value(resized.height).must_equal 50
          value(resized.interpolation).must_equal interpolation
          if frames
            value(resized.frames).must_equal frames
          else
            value(resized.frames).must_be_nil
          end
        end
      end
    end

    after do
      subject.close
    end
  end

  describe '#frame' do
    before do
      @todd = subject.read image_path('todd.gif')
      @black_pink = subject.read image_path('black_pink.jpg')
      @rainbow_socks = subject.read image_path('rainbow_socks.jpg')
    end

    it 'should work' do
      (0..@todd.frames - 1).each do |frame|
        framed = subject.frame(@todd, frame)
        value(framed.frame).must_equal frame
        value(framed.width).must_equal 320
        value(framed.height).must_equal 240
        value(framed.frames).must_be_nil
      end

      (0..@black_pink.frames - 1).each do |frame|
        framed = subject.frame(@black_pink, frame)
        value(framed.frame).must_equal frame
        value(framed.width).must_equal 260
        value(framed.height).must_equal 370
        value(framed.frames).must_be_nil
      end

      (0..@rainbow_socks.frames - 1).each do |frame|
        framed = subject.frame(@rainbow_socks, frame)
        value(framed.frame).must_equal frame
        value(framed.width).must_equal 260
        value(framed.height).must_equal 370
        value(framed.frames).must_be_nil
      end
    end

    after do
      subject.close
    end
  end

  describe '#lossy' do
    before do
      @sushi = subject.read image_path('sushi.jpg')
      @miku = subject.read image_path('miku.gif')
      @black_pink = subject.read image_path('black_pink.jpg')
      @rainbow_socks = subject.read image_path('rainbow_socks.jpg')
    end

    it 'should work' do
      {
        sush: @sushi,
        miku: @miku,
        black_pink: @black_pink,
        rainbow_socks: @rainbow_socks
      }.each do |name, image|
        %i[jpeg webp].each do |format|
          lossy_size = 0
          lossy_quality = 0
          {
            low: 0.90,
            medium: 0.933,
            high: 0.966,
            very_high: 0.999
          }.each do |quality, ssim|
            lossy_by_quality = subject.lossy(image, image_path("test/#{name}_#{quality}.#{format}"), format: format, quality: quality)
            lossy_by_ssim = subject.lossy(image, image_path("test/#{name}_#{ssim}.#{format}"), format: format, quality: ssim)
            assert lossy_by_quality.size >= lossy_size, 'must less size'
            assert lossy_by_quality.quality >= lossy_quality, 'must less quality'

            lossy_by_fixed_quality = subject.lossy(image, image_path("test/#{name}_#{lossy_by_quality.quality}.#{format}"), format: format, quality: quality)

            value(lossy_by_quality.quality).must_equal lossy_by_ssim.quality
            value(lossy_by_quality.size).must_equal lossy_by_ssim.size

            value(lossy_by_quality.quality).must_equal lossy_by_fixed_quality.quality
            value(lossy_by_quality.size).must_equal lossy_by_fixed_quality.size

            lossy_size = lossy_by_quality.size
            lossy_quality = lossy_by_quality.quality
          end
        end
      end
    end

    after do
      subject.close
    end
  end

  describe '#lossless' do
    before do
      @ia = subject.read(image_path('IA.png'), flatten: :none)
      @miku = subject.read image_path('miku.gif')
      @black_pink = subject.read image_path('black_pink.jpg')
      @rainbow_socks = subject.read image_path('rainbow_socks.jpg')
    end

    it 'should work' do
      {
        ia: @ia,
        miku: @miku,
        black_pink: @black_pink,
        rainbow_socks: @rainbow_socks
      }.each do |name, image|
        %i[png webp].each do |format|
          subject.lossless(image, image_path("test/#{name}.#{format}"), format: format)
        end
      end
    end

    after do
      subject.close
    end
  end

  describe '#compare' do
    before do
      @miku = subject.read image_path('miku.gif')
      @mikus = %i[low medium high very_high].map do |quality|
        output_path = image_path("test/miku_#{quality}.jpg")
        subject.lossy(@miku, output_path, format: :jpeg, quality: quality)
        [quality, subject.read(output_path)]
      end
    end

    it 'should work' do
      @mikus.each do |_quality, image|
        subject.compare(@miku, image)
      end
    end
  end

  describe '#video' do
    before do
      @todd = subject.read image_path('todd.gif')
      @miku = subject.read image_path('miku.gif')
      @black_pink = subject.read image_path('black_pink.jpg')
      @rainbow_socks = subject.read image_path('rainbow_socks.jpg')
    end

    it 'should work' do
      {
        todd: @todd,
        miku: @miku,
        black_pink: @black_pink,
        rainbow_socks: @rainbow_socks
      }.each do |name, image|
        mp4 = subject.video(image, image_path("test/#{name}.mp4"), format: :mp4)
        value(mp4.size).must_be :>, 0
      end
    end

    after do
      subject.close
    end
  end

  describe '#clear' do
    it 'return true' do
      value(subject.clear).must_equal true
    end

    after do
      subject.close
    end
  end

  describe '#close' do
    it 'return 0' do
      value(subject.close).must_equal 0
    end
  end
end
