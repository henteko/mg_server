@dir = "./"

worker_processes 1
working_directory @dir

timeout 300
listen 4567

pid "#{@dir}unicorn.pid"

stderr_path "#{@dir}unicorn.stderr.log"
stdout_path "#{@dir}unicorn.stdout.log"
