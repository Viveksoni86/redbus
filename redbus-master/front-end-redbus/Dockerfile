# Stage 1: Build React App
FROM node:16-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

# 🔥 FIX: Increase Node memory (VERY IMPORTANT)
ENV NODE_OPTIONS=--max_old_space_size=4096


ARG REACT_APP_BACKEND_URL
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL


RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]