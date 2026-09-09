# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Build argument for backend API URL
ARG REACT_APP_MOVIE_API_URL=http://localhost:5000
ENV REACT_APP_MOVIE_API_URL=${REACT_APP_MOVIE_API_URL}

COPY package*.json ./
RUN npm ci || npm install

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
