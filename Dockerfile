FROM registry.access.redhat.com/ubi8/nodejs-12

# Install dependencies
COPY package.json /app/
WORKDIR /app
RUN npm ci --production

# Copy app
COPY . /app

EXPOSE 3000
ENTRYPOINT [ "npm", "start" ]
