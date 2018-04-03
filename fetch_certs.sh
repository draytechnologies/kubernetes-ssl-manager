#!/bin/bash

EMAIL=${EMAIL}
DOMAINS=(${DOMAINS})

if [ -z "$DOMAINS" ]; then
    echo "ERROR: Domain list is empty or unset"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "ERROR: Email is empty string or unset"
    exit 1
fi

domain_args=""
for domain in "${DOMAINS[@]}"
do
    certbot certonly \
        --webroot -w /letsencrypt/challenges/ \
        --text --renew-by-default --agree-tos \
        -d $domain \
        --email=$EMAIL
done

