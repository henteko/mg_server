require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/json'

# @param [String] mp4_file_path
# @return [String]
def gif_from_mp4(mp4_file_path)
  output_path = './tmp/out.gif'
  `ffmpeg -i #{mp4_file_path}  -an -r 15  -pix_fmt rgb24 -f gif #{output_path}`

  output_path
end

namespace '/api' do
  post '/convert' do
    path = gif_from_mp4 params[:file][:tempfile].path
    json :path => path
  end
end
