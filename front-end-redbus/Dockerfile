# Stage 1: Build React App
FROM node:16 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

# Increase Node memory for the CRA build
ENV NODE_OPTIONS=--max_old_space_size=4096

# Empty by default so the app uses relative URLs (/v1/api/...) that nginx
# proxies to the backend. Override only if you serve the API on another host.
ARG REACT_APP_BACKEND_URL=
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL

RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine

# nginx entrypoint renders templates with envsubst at startup. Restrict
# substitution to BACKEND_ vars so nginx's own $uri/$host are preserved.
ENV NGINX_ENVSUBST_FILTER=^BACKEND_
ENV BACKEND_HOST=backend

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
