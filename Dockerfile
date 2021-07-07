FROM registry.access.redhat.com/ubi8/nodejs-12

# Install dependencies
COPY package.json package-lock.json /app/
WORKDIR /app
RUN npm ci --production

# Copy app
COPY . /app

EXPOSE 8080
ENTRYPOINT [ "npm", "start" ]
