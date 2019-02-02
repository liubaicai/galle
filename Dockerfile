FROM liubaicai/ruby2.6.0:common

RUN mkdir /galle
WORKDIR /galle

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test