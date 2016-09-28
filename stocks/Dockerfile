FROM ruby:latest
MAINTAINER Chris Cox <chriscox@abandonedfactory.net>
RUN gem install typhoeus

RUN mkdir -p lib
RUN mkdir -p config

ADD positions.json .
ADD position.rb .

ENTRYPOINT /usr/local/bin/ruby position.rb positions.json
