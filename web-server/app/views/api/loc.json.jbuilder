json.vcs_url @vcs_url
if @error
  json.error @error
else
  json.results @results
end
