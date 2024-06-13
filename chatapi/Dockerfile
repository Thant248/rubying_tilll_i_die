ARG RUBY_VERSION=3.1.2
# FROM ruby:${RUBY_VERSION}-slim-bullseye
FROM ruby:${RUBY_VERSION}
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client vim

ENV ROOT="/app"
WORKDIR ${ROOT}

COPY Gemfile ${ROOT}/Gemfile
COPY Gemfile.lock ${ROOT}/Gemfile.lock
RUN bundle install

COPY . ${ROOT}

# entrypoint
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# EXPOSE 3005

CMD ["rails", "server", "-b", "0.0.0.0"]