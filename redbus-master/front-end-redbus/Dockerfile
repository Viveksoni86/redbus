FROM node:18

WORKDIR /app

COPY package*.json ./

RUN npm cache clean --force

RUN npm install --legacy-peer-deps --no-cache

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
