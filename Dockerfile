FROM ruby:2.7.4-bullseye

RUN gem install bundler jekyll

WORKDIR /app
