require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/json'
require 'aws-sdk'
require 'digest/md5'
require 'RMagick'

# @param [String] mp4_file_path
# @return [String]
def gif_from_mp4(mp4_file_path)
  hash = Digest::MD5.file(mp4_file_path).to_s
  output_path = "./tmp/#{hash}.gif"
  `ffmpeg -y -i #{mp4_file_path}  -an -r 15  -pix_fmt rgb24 -f gif #{output_path}`

  output_path
end

def base_url
  @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
end

BACKET_NAME = 'mg.henteko07.com'
s3 = Aws::S3::Client.new(region: 'ap-northeast-1')

namespace '/api' do
  post '/convert' do
    path = gif_from_mp4(params[:file][:tempfile].path) # TODO: check params
    file_name = File.basename(path)
    s3.put_object(
        bucket: BACKET_NAME,
        body: File.open(path),
        key: file_name
    )
    json gif: "#{base_url}/#{file_name}"
  end
end

get '/:file_name' do
  file_name = params[:file_name]
  Tempfile.create(file_name) do |f|
    resp = s3.get_object(
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
