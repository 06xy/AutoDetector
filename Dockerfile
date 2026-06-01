FROM node:20-alpine

WORKDIR /app

COPY public ./public
COPY src ./src
COPY server.js ./

RUN mkdir -p /app/data

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:5000/login.html || exit 1

CMD ["node", "server.js", "--host", "0.0.0.0", "--port", "5000", "--storage-ai-config-path", "/app/data/storage-ai.settings.json"]
