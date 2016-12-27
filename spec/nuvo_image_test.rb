require 'minitest/autorun'
require 'nuvo_image'

describe NuvoImage::Process do
  before do
    Dir.chdir(File.join(File.dirname(__FILE__), '../ext/nuvo_image/build')) do
      `ruby extconf.rb`
      `make install`
    end
    test_image_dir = File.join(File.dirname(__FILE__), 'images/test')
    FileUtils.rm_rf(test_image_dir)
    FileUtils.mkdir_p(test_image_dir)
  end

  subject {NuvoImage::Process.new}

  describe '#read' do
    it 'should work' do
      sushi = subject.read(File.dirname(__FILE__) + '/images/sushi.jpg')
      sushi.width.must_equal 960
      sushi.height.must_equal 960
      sushi.size.must_equal 116_306
      sushi.frames.must_be_nil

      todd = subject.read(File.dirname(__FILE__) + '/images/todd.gif')
      todd.frames.must_equal 21
      todd.width.must_equal 320
      todd.height.must_equal 240
      todd.size.must_equal 472_973

      ia = subject.read(File.dirname(__FILE__) + '/images/IA.png')
      ia.width.must_equal 750
      ia.height.must_equal 1091
      ia.size.must_equal 562_086

      bag = subject.read(File.dirname(__FILE__) + '/images/bag-exif.jpg')
      bag.width.must_equal 552
      bag.height.must_equal 414
      bag.size.must_equal 62_735
    end

    after do
      subject.close
    end
  end

  describe '#crop' do
    before do
      @sushi = subject.read(File.dirname(__FILE__) + '/images/sushi.jpg')
      @todd = subject.read(File.dirname(__FILE__) + '/images/todd.gif')
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
        cropped.gravity.must_equal gravity
        [cropped.left, cropped.top, cropped.width, cropped.height].must_equal result
        cropped.frames.must_be_nil
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
        cropped.gravity.must_equal gravity
        [cropped.left, cropped.top, cropped.width, cropped.height].must_equal result
        cropped.frames.must_equal 21
      end
    end

    after do
      subject.close
    end
  end

  describe '#resize' do
    before do
      @sushi = subject.read(File.dirname(__FILE__) + '/images/sushi.jpg')
      @todd = subject.read(File.dirname(__FILE__) + '/images/todd.gif')
    end

    it 'should work' do
      [:nearest, :linear, :cubic, :area, :lanczos].each do |interpolation|
        resized = subject.resize(@sushi, 100, 50, interpolation: interpolation)
        resized.width.must_equal 100
        resized.height.must_equal 50
        resized.interpolation.must_equal interpolation
        resized.frames.must_be_nil
      end

      [:nearest, :linear, :cubic, :area, :lanczos].each do |interpolation|
        resized = subject.resize(@todd, 100, 50, interpolation: interpolation)
        resized.width.must_equal 100
        resized.height.must_equal 50
        resized.interpolation.must_equal interpolation
        resized.frames.must_equal 21
      end
    end

    after do
      subject.close
    end
  end

  describe '#frame' do
    before do
      @todd = subject.read(File.dirname(__FILE__) + '/images/todd.gif')
    end

    it 'should work' do
      (0..@todd.frames - 1).each do |frame|
        framed = subject.frame(@todd, frame)
        framed.frame.must_equal frame
        framed.width.must_equal 320
        framed.height.must_equal 240
        framed.frames.must_be_nil
      end
    end

    after do
      subject.close
    end
  end

  describe '#lossy' do
    before do
      @sushi = subject.read(File.dirname(__FILE__) + '/images/sushi.jpg')
      @miku = subject.read(File.dirname(__FILE__) + '/images/miku.gif')
    end

    it 'should work' do
      {
        sush: @sushi,
        miku: @miku
      }.each do |name, image|
        [:jpeg, :webp].each do |format|
          lossy_size = 0
          lossy_quality = 0
          {
            low: 0.90,
            medium: 0.933,
            high: 0.966,
            very_high: 0.999
          }.each do |quality, ssim|
            lossy_by_quality = subject.lossy(image, File.dirname(__FILE__) + "/images/test/#{name}_#{quality}.#{format}", format: format, quality: quality)
            lossy_by_ssim = subject.lossy(image, File.dirname(__FILE__) + "/images/test/#{name}_#{ssim}.#{format}", format: format, quality: ssim)
            assert lossy_by_quality.size >= lossy_size, 'must less size'
            assert lossy_by_quality.quality >= lossy_quality, 'must less quality'

            lossy_by_fixed_quality = subject.lossy(image, File.dirname(__FILE__) + "/images/test/#{name}_#{lossy_by_quality.quality}.#{format}", format: format, quality: quality)

            lossy_by_quality.quality.must_equal lossy_by_ssim.quality
            lossy_by_quality.size.must_equal lossy_by_ssim.size

            lossy_by_quality.quality.must_equal lossy_by_fixed_quality.quality
            lossy_by_quality.size.must_equal lossy_by_fixed_quality.size

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
      @ia = subject.read(File.dirname(__FILE__) + '/images/IA.png', flatten: :none)
      @miku = subject.read(File.dirname(__FILE__) + '/images/miku.gif')
    end

    it 'should work' do
      {
        ia: @ia,
        miku: @miku
      }.each do |name, image|
        [:png, :webp].each do |format|
          subject.lossless(image, File.dirname(__FILE__) + "/images/test/#{name}.#{format}", format: format)
        end
      end
    end

    after do
      subject.close
    end
  end

  describe '#compare' do
    before do
      @miku = subject.read(File.dirname(__FILE__) + '/images/miku.gif')
      @mikus = [:low, :medium, :high, :very_high].map do |quality|
        subject.lossy(@miku, File.dirname(__FILE__) + "/images/test/miku_#{quality}.jpg", format: :jpeg, quality: quality)
        [quality, subject.read(File.dirname(__FILE__) + "/images/test/miku_#{quality}.jpg")]
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
      @todd = subject.read(File.dirname(__FILE__) + '/images/todd.gif')
      @miku = subject.read(File.dirname(__FILE__) + '/images/miku.gif')
    end

    it 'should work' do
      mp4 = subject.video(@todd, File.dirname(__FILE__) + '/images/test/todd.mp4', format: :mp4)
      wemb = subject.video(@todd, File.dirname(__FILE__) + '/images/test/todd.webm', format: :webm)
      assert mp4.size > 0, 'must greater than 0'
      assert wemb.size > 0, 'must greater than 0'

      mp4 = subject.video(@miku, File.dirname(__FILE__) + '/images/test/miku.mp4', format: :mp4)
      wemb = subject.video(@miku, File.dirname(__FILE__) + '/images/test/miku.webm', format: :webm)
      assert mp4.size > 0, 'must greater than 0'
      assert wemb.size > 0, 'must greater than 0'
    end

    after do
      subject.close
    end
  end

  describe '#clear' do
    it 'return true' do
      subject.clear.must_equal true
    end

    after do
      subject.close
    end
  end

  describe '#close' do
    it 'return 0' do
      subject.close.must_equal 0
    end
  end
end
