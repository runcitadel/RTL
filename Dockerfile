# ---------------
# Install Dependencies
# ---------------
FROM node:18-alpine as builder

WORKDIR /RTL

COPY package.json /RTL/package.json
COPY yarn.lock /RTL/yarn.lock
COPY .yarnrc.yml /RTL/.yarnrc.yml
COPY .yarn/releases/yarn-3.2.1.cjs /RTL/.yarn/releases/yarn-3.2.1.cjs

RUN yarn

# ---------------
# Build App
# ---------------
COPY . .

# Build the Angular application
RUN yarn buildfrontend

# Build the Backend from typescript server
RUN yarn buildbackend

# Remove non production necessary modules
RUN yarn install --production --ignore-scripts --prefer-offline

# ---------------
# Release App
# ---------------
FROM node:18-alpine as runner

WORKDIR /RTL

RUN apk add --no-cache tini

COPY --from=builder /RTL/rtl.js ./rtl.js
COPY --from=builder /RTL/package.json ./package.json
COPY --from=builder /RTL/frontend ./frontend
COPY --from=builder /RTL/backend ./backend
COPY --from=builder /RTL/node_modules/ ./node_modules

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "-g", "--"]

CMD ["node", "rtl"]
