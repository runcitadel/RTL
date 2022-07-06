# ---------------
# Install Dependencies
# ---------------
FROM amd64/node:18-alpine as builder

WORKDIR /RTL

COPY package.json /RTL/package.json
COPY yarn.lock /RTL/yarn.lock
COPY .yarnrc.yml /RTL/.yarnrc.yml
COPY .yarn/releases/yarn-3.2.1.cjs /RTL/.yarn/releases/yarn-3.2.1.cjs
COPY .yarn/plugins/@yarnpkg/plugin-workspace-tools.cjs /RTL/.yarn/plugins/@yarnpkg/plugin-workspace-tools.cjs

RUN yarn

# ---------------
# Build App
# ---------------
COPY . .

# Build the Angular application
RUN yarn buildfrontend

# Build the Backend from typescript server
RUN yarn buildbackend

FROM node:18-alpine as dependencies

WORKDIR /RTL

COPY package.json /RTL/package.json
COPY yarn.lock /RTL/yarn.lock
COPY .yarnrc.yml /RTL/.yarnrc.yml
COPY .yarn/releases/yarn-3.2.1.cjs /RTL/.yarn/releases/yarn-3.2.1.cjs
COPY .yarn/plugins/@yarnpkg/plugin-workspace-tools.cjs /RTL/.yarn/plugins/@yarnpkg/plugin-workspace-tools.cjs

# Download only production necessary modules
RUN yarn workspaces focus --production

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
COPY --from=dependencies /RTL/node_modules/ ./node_modules

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "-g", "--"]

CMD ["node", "rtl"]
