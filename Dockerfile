FROM ruby:2.5
WORKDIR /myapp
RUN apt-get update -qq && apt-get install -y nodejs sqlite3 libsqlite3-dev
COPY Gemfile  Gemfile.lock ./
RUN bundle install
COPY . .
RUN bundle exec rake db:create db:migrate db:seed

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
