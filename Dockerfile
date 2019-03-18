FROM ruby:2.1.8
RUN apt-get update -qq && apt-get install -y nodejs
RUN mkdir /eventer
WORKDIR /eventer
COPY Gemfile /eventer/Gemfile
COPY Gemfile.lock /eventer/Gemfile.lock
RUN bundle install
COPY . /eventer

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]