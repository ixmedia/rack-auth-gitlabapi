FROM ruby:3.4.9

ARG USER_ID=1000
ARG USER_GROUP_ID=1000
ARG TZ=America/Toronto

RUN \
    if ! id -g $USER_GROUP_ID; then addgroup --gid $USER_GROUP_ID custom; fi; \
    if ! id -u $USER_ID; then adduser --disabled-password --gecos "" --uid $USER_ID --gid $USER_GROUP_ID --shell /bin/bash --home /home/custom custom; fi;

ENV APP_HOME="/app"
RUN mkdir $APP_HOME && chown -R $USER_ID:$USER_GROUP_ID $APP_HOME
WORKDIR $APP_HOME

# Add a script to be executed every time the container starts.
COPY --chmod=0755 docker-entrypoint.sh /usr/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

COPY Gemfile* *.gemspec $APP_HOME/
COPY lib/ $APP_HOME/lib/
RUN chown -R $USER_ID:$USER_GROUP_ID $APP_HOME

# The commands below will be ran as the app user
USER $USER_ID:$USER_GROUP_ID

RUN bundle install --jobs $(nproc)

# Start the main process.
CMD ["rake", "test"]
