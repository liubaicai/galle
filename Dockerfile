FROM liubaicai/ruby2.6.0:base

RUN mkdir /galle
WORKDIR /galle

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test