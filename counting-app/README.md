# LOCulator counting app

This is a ruby script that counts the number of lines in a remote repository by cloning it locally.

It uses the [rugged](https://github.com/libgit2/rugged) library to do relevant git operations. 

## Config

To clone from private repos, an SSH configuration is necessary. Create a config file in json format, and set its location as the environment variable `LOCULATOR_CONFIG`. This is required. 

For an example config file, see `docker_loc_cfg.json`, which is the default config file for the shipped Docker container. 
