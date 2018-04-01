FROM nginx:1.11

ENV KUBECTL_VERSION v1.9.4

RUN apt-get update && apt-get install -y wget cron bc

RUN wget http://nginx.org/packages/keys/nginx_signing.key
RUN cat nginx_signing.key | apt-key add -
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >>  /etc/apt/sources.list
RUN apt-get update && apt-get install -y certbot -t jessie-backports

RUN mkdir -p /letsencrypt/challenges/.well-known/acme-challenge
RUN certbot-auto; exit 0

# You should see "OK" if you go to http://<domain>/.well-known/acme-challenge/health

RUN echo "OK" > /letsencrypt/challenges/.well-known/acme-challenge/health

# Install kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
RUN chmod +x kubectl
RUN mv kubectl /usr/local/bin/

# Add our nginx config for routing through to the challenge results
RUN rm /etc/nginx/conf.d/*.conf
ADD nginx/nginx.conf /etc/nginx/
ADD nginx/letsencrypt.conf /etc/nginx/conf.d/

# Add some helper scripts for getting and saving scripts later
ADD fetch_certs.sh /letsencrypt/
ADD save_certs.sh /letsencrypt/
ADD recreate_pods.sh /letsencrypt/
ADD refresh_certs.sh /letsencrypt/
ADD start.sh /letsencrypt/

ADD nginx/letsencrypt.conf /etc/nginx/snippets/letsencrypt.conf

WORKDIR /letsencrypt

ENTRYPOINT ./start.sh
