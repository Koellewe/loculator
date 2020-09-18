# LOCulator counting app

This is a ruby script that counts the number of lines in a remote repository by cloning it locally.

## Dependencies

The program doesn't have any compile-time dependencies, but it does make some external shell calls at run-time. Specifically it relies on `git` (can be specified in config), and `file` commands.

## Config

To clone from private repos, an SSH configuration is necessary. Create a config file in json format, and set its location as the environment variable `LOCULATOR_CONFIG`. This is required. 

For an example config file, see `docker_loc_cfg.json`, which is the default config file for the shipped Docker container. 

## Running

Since it has no dependencies, running is as simple as:

```shell script
ruby counting_app.rb [VCS_url]
```

Where the VCS url is either an https url to a public repository, or an ssh url (of the form `git@domain:usr/repo`) to a private repo.

## Output

For processing convenience, the program always outputs in JSON directly to STDOUT. Example successful output:

```json
{"total_lines":2070,"blank_lines":307,"total_files":82,"non_text_files":21}
``` 

If there's an error, the outputted json will have one key called `error` with value being a string description of what went wrong. Most likely this will be an SSH key mismatch.
