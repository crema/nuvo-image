require 'json'
require 'open3'

module NuvoImage
  class Process
    attr_reader :stdin, :stdout, :thread

    ReadResult = Struct.new(:id, :width, :height, :size)
    CropResult = Struct.new(:id, :width, :height, :gravity)
    ResizeResult = Struct.new(:id, :width, :height, :interpolation)
    JpegResult = Struct.new(:id, :size, :quality)

    def initialize
      nuvo_image_process = File.dirname(__FILE__) + '/../../ext/nuvo_image/bin/nuvo_image'
      @stdin, @stdout, @thread = Open3.popen2(nuvo_image_process)
    end

    def call(args)
      stdin.puts(args.to_json)
      line = stdout.readline
      result = JSON.parse(line, symbolize_names: true)
      raise result[:error] unless result[:error].nil?
      result
    end

    def read(filename, auto_orient: true, flatten: :white)
      result = call process: :read, from: filename, auto_orient: auto_orient, flatten: flatten
      ReadResult.new(result[:to], result[:width], result[:height], result[:size])
    end

    def crop(image, width, height, gravity: :Center)
      result = call process: :crop, from: image.id, width: width, height: height, gravity: gravity
      CropResult.new(result[:to], result[:width], result[:height], result[:gravity].to_sym)
    end

    def resize(image, width, height, interpolation: :area)
      result = call process: :resize, from: image.id, width: width, height: height, interpolation: interpolation
      ResizeResult.new(result[:to], result[:width], result[:height], result[:interpolation].to_sym)
    end

    def jpeg(image, filename, quality: :high, min: 50, max: 100, search: 3, gray_ssim: true)
      result = call process: :jpeg, from: image.id, to: filename, quality: quality, min: min, max: max, search: search, gray_ssim: gray_ssim
      JpegResult.new(result[:to], result[:size], result[:quality])
    end

    def clear
      result = call process: :clear
      result[:result]
    end

    def close
      stdin.puts({process: :close}.to_json)
      thread.value
    end
  end
end
