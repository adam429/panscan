FROM ruby:2.7

RUN apt-get update && \
    apt-get install -y \
        libpq-dev \
        unzip
        #  default-mysql-client \
        #  default-libmysqlclient-dev \

WORKDIR /tmp

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN sudo ./aws/install


WORKDIR /panscan
# COPY Gemfile /panscan/Gemfile
# COPY Gemfile.lock /panscan/Gemfile.lock
COPY panscan /panscan
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 80

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "80"]