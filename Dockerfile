FROM node:lts-alpine
WORKDIR /app

COPY app/package*.json ./

RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev ; \
    else \
      npm install --omit=dev ; \
    fi

COPY app/. .

EXPOSE 8080
CMD ["npm", "start"]
