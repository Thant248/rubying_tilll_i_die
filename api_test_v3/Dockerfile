# Use the official Ruby image
FROM ruby:3.3.0

# Set environment variables
ENV RAILS_ROOT /app
ENV RAILS_ENV production

# Set working directory
WORKDIR $RAILS_ROOT

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y nodejs default-mysql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle install --jobs 20 --retry 5

# Copy application code
COPY . .

# Precompile assets


# Expose port
EXPOSE 4000

# Start the application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "4000"]

