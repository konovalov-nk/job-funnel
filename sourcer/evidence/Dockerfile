FROM node:22-bookworm-slim

WORKDIR /app

COPY evidence/package.json evidence/package-lock.json ./
RUN npm ci

COPY evidence/ ./

EXPOSE 3000

CMD ["sh", "-c", "npm run sources && npm run dev"]
