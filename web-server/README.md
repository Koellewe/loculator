# LOCulator web server

A pretty simple web server, serving as a wrapper for the counting app.

## Config

Config for this web app is in json format. The file should be specified in the environment variable `LOC_WEB_CFG` and set before running the app. Example config can be found in `example_cfg.json`.

## Running

```shell script
bin/rails serve
```

## Prod

Deploy this rail however you want. Currently the CI does some very crude zipping, uploading, and serving with Passenger. 
