json.vcs_url @vcs_url
json.cached_commit @sha
if @error
  json.error @error
else
  json.results @results
end
