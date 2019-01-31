FROM ruby:2.6.0-slim-stretch

RUN apt-get update
RUN apt-get install -y build-essential curl libsqlite3-dev git

RUN mkdir /galle
WORKDIR /galle

ENV RAILS_SERVE_STATIC_FILES=true PORT=80

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test