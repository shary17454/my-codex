# Build context is the repository root, not this directory.
#
# `my-codex` is a monorepo: its root holds a Flutter manifest, a legacy web app, and
# several unrelated iOS projects. A root-directory build therefore detects the wrong
# stack — the first attempt installed Python and started the old SQLite web app on a
# hardcoded port 5005, which Railway's proxy can never reach.
#
# Pointing the service at this Dockerfile (RAILWAY_DOCKERFILE_PATH) keeps the whole
# deployment definition inside the app that owns it, and copies only the two files the
# backend actually needs instead of the ~700 MB of catalog data and Xcode projects
# sitting next to them.
FROM node:22-alpine

# The server is dependency-free (Node standard library only), so there is no install
# step and nothing to cache — copying the sources is the entire build.
WORKDIR /app
COPY ios/BatalAlDroob/ai-backend/package.json ./package.json
COPY ios/BatalAlDroob/ai-backend/server.mjs ./server.mjs

ENV NODE_ENV=production

# Drop privileges: this process holds an OpenAI key and speaks to the public internet.
USER node

# PORT is injected by the platform; server.mjs binds 0.0.0.0 whenever it is present.
CMD ["node", "server.mjs"]
