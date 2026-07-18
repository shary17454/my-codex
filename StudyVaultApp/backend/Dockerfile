FROM node:24-alpine

WORKDIR /app

COPY package.json ./
COPY server.mjs ./server.mjs
COPY sql ./sql
COPY tests ./tests

ENV NODE_ENV=production
ENV PORT=8787

EXPOSE 8787

CMD ["node", "server.mjs"]
