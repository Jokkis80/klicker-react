# extend the node alpine base
FROM node:8.1.2-alpine AS builder

MAINTAINER Roland Schlaefli <roland.schlaefli@bf.uzh.ch>
LABEL NAME klicker-react
LABEL VERSION 0.0.1

# root application directory
ENV KLICKER_DIR /app
WORKDIR $KLICKER_DIR

# inject the application dependencies
COPY package.json yarn.lock $KLICKER_DIR/

# install production yarn packages
# copy the packages to a temporary directory
RUN set -x \
  && yarn install --production \
  && cp -rp ./node_modules /tmp/node_modules

# install remaining packages (dev)
RUN set -x \
  && yarn install

# inject application sources
COPY . $KLICKER_DIR/

# switch to the node user (uid 1000)
# non-root as provided by the base image
RUN chown -R 1000:1000 $KLICKER_DIR/
USER 1000

# run the applications tests
RUN yarn test


FROM node:8.1.2-alpine AS runner

EXPOSE 3000
WORKDIR $KLICKER_DIR

COPY --from=builder /tmp/node_modules $KLICKER_DIR/node_modules

# inject the entrypoint and make it runnable
COPY entrypoint.sh /entrypoint.sh
RUN chown 1000:1000 /entrypoint.sh \
  && chmod u+x /entrypoint.sh

# inject application sources
COPY . $KLICKER_DIR/

# build the application
RUN yarn run build

# configure the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

# run next in production mode
CMD ["yarn", "run", "start"]
