FROM ruby:2.7-alpine
RUN apk update
RUN apk add file
RUN apk add openssh
RUN apk add git

WORKDIR workspace
COPY counting_app.rb ./
COPY docker_loc_cfg.json ./cfg.json

CMD LOCULATOR_CONFIG=/workspace/cfg.json ruby counting_app.rb ${VCS_URL}
