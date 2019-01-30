FROM ruby:2.6.0-slim-stretch

RUN apt-get update
RUN apt-get install --fix-missing
RUN apt-get install -y apt-transport-https lsb-release build-essential curl libsqlite3-dev git

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

RUN mkdir /galle
WORKDIR /galle

ENV RAILS_SERVE_STATIC_FILES=true PORT=80

COPY Gemfile Gemfile.lock ./
RUN bundle install