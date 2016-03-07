require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/json'
require 'aws-sdk'
require 'digest/md5'
require 'rmagick'
require 'tmpdir'

require 'sinatra/base'
class MgApp < Sinatra::Base
  register Sinatra::Namespace

  BACKET_NAME = 'mg.henteko07.com'
  S3 = Aws::S3::Client.new(region: 'ap-northeast-1')

  # @param [String] mp4_file_path
  # @return [String]
  def gif_from_mp4(mp4_file_path, output_dir_path)
    hash = Digest::MD5.file(mp4_file_path).to_s
    output_path = File.join(output_dir_path, "#{hash}.gif")
    `ffmpeg -y -i #{mp4_file_path}  -an -r 15  -pix_fmt rgb24 -f gif #{output_path}`

    output_path
  end

  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end

  namespace '/api' do
    post '/convert' do
      Dir.mktmpdir do |dir|
        path = gif_from_mp4(params[:file][:tempfile].path, dir.to_s) # TODO: check params
        file_name = File.basename(path)
        S3.put_object(
            bucket: BACKET_NAME,
            body: File.open(path),
            key: file_name
        )
        json gif: "#{base_url}/#{file_name}"
      end
    end
  end

  get '/:file_name' do
    file_name = params[:file_name]
    Tempfile.create(file_name) do |f|
      resp = S3.get_object(
          response_target: f.path,
          bucket: BACKET_NAME,
          key: file_name
      )
      # TODO: check resp
      img = Magick::ImageList.new(f.path)
      content_type 'image/gif'
      img.to_blob
    end
  end

  get '/' do
    "curl -F 'file=@input.mp4' #{base_url}/api/convert"
  end
end

run MgApp
