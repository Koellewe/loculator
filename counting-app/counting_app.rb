# Main counting program

require 'tmpdir'
require 'json'

$final_out = {}

def main

  if (cfg_file = ENV['LOCULATOR_CONFIG'])
    cfg = JSON.parse(File.read(cfg_file))
  else
    $final_out['error'] = 'ENV var "LOCULATOR_CONFIG" not set.'
    complete_run 1
  end

  if ARGV.empty?
    $final_out['error'] = 'VCS url not provided'
    complete_run 1
  end

  vcs_url = ARGV[0]

  # setup working dir
  Dir.mktmpdir 'loc' do |ws|
    Dir.chdir(ws)
    # clone remote repo
    # setup command
    cmd = "GIT_SSH_COMMAND='ssh -i #{cfg['private_key']} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no' " \
        "#{cfg['git']} clone #{vcs_url} ./ 2>&1"
    cmd_output = `#{cmd}` # hectic backticks

    if cmd_output.include? 'not accessible: No such file or directory'
      $final_out['error'] = 'Could not read private key: ' + cfg['private_key']
      complete_run 1
    elsif cmd_output.include? 'Permission denied (publickey)'
      $final_out['error'] = 'Failed to authenticate. SSH key mismatch.'
      complete_run 1
    else
      # setup output
      $final_out['total_lines'] = 0
      $final_out['blank_lines'] = 0
      $final_out['total_files'] = 0
      $final_out['non_text_files'] = 0

      # do counting
      lines_in_dir ws
      complete_run 0
    end
  end

end

# Do DFS line counting
def lines_in_dir(dir)

  # iterate through all items in dir
  Dir.open(dir).each_child do |filename|
    full_file = dir + '/' + filename
    if File.directory? full_file
      lines_in_dir(full_file) unless filename == '.git' # ignore .git dir
    else
      if `file -ib #{full_file}`.start_with? 'text' # text file
        File.open(full_file) do |file|
          file.each do |line|
            $final_out['total_lines'] += 1
            $final_out['blank_lines'] += 1 if line.strip.empty?
          end
        end
      else
        $final_out['non_text_files'] +=1
      end
      $final_out['total_files'] += 1
    end
  end

end

def complete_run(exit_code = 0)
  puts $final_out.to_json
  exit exit_code
end

main
