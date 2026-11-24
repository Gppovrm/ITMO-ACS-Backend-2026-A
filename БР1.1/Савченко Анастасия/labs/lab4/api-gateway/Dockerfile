FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install && npm install -g tsx@4.19.3
COPY . .
EXPOSE 3000
CMD ["npx", "tsx", "src/index.ts"]