FROM ruby:3.4.12
WORKDIR /app
COPY . .
ENV BUNDLE_FROZEN=true
RUN sed -i 's/\r$//' bin/run && bundle install
CMD ["ruby", "bin/run"]
