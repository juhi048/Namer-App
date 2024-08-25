# Stage 1: Build the Flutter Web App
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    libgconf-2-4 \
    gdb \
    libstdc++6 \
    libglu1-mesa \
    fonts-droid-fallback \
    lib32stdc++6 \
    python3 \
    && apt-get clean

# Clone the Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set Flutter environment path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter web support
RUN flutter doctor -v
RUN flutter channel master
RUN flutter upgrade
RUN flutter config --enable-web

# Copy the Flutter app source code and build the web app
WORKDIR /app
COPY . /app/
RUN flutter build web --release

# Stage 2: Serve the Flutter Web App with Nginx
FROM nginx:1.21.1-alpine

# Remove default Nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy the Nginx config to serve on port 8080
COPY nginx.conf /etc/nginx/conf.d

# Copy the built Flutter web app from the build stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
