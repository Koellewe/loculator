# Main counting program

require 'rugged'
require 'tmpdir'

def main
  if ARGV.empty?
    puts 'Please provide the VCS url'
    exit
  end

  vcs_url = ARGV[0]

  # setup working dir
  Dir.mktmpdir 'loc' do |ws|

    # clone remote repo
    Rugged::Repository.clone_at(vcs_url, ws)

    puts lines_in_dir ws
  end

end

# Do DFS line counting
def lines_in_dir(dir)
  total_lines = 0

  Dir.open(dir).each_child do |filename|
    full_file = dir + '/' + filename
    if File.directory? full_file
      total_lines += lines_in_dir(full_file) unless filename == '.git'  # ignore .git dir
    else
      File.open(full_file) do |file|
        file.each do
          total_lines += 1
        end
      end
    end
  end

  total_lines
end

main
