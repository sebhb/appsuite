#!/bin/bash

# Receive Parameters
HOST="$1"
USER="$2"
PASS="$3"

# Make sure all three parameters are set
if [[ -z "$HOST" || -z "$USER" || -z "$PASS" ]]; then
  echo "Usage: $0 <hostname> <username> <password>"
  exit 1
fi

echo "Importing Emails"
appsuite import mails --server "$HOST" --name "$USER" --password "$PASS" --importFolderTree --source GoldAccounts/chris.davis --adjustRecipient true --stretchPeriod 180

echo "Importing Taks"
appsuite import tasks --server "$HOST" --name "$USER" --password "$PASS" --source tasks.json

echo "Importing Files"
appsuite import files --server "$HOST" --name "$USER" --password "$PASS" --source testfiles/

echo "Generating Contacts"
appsuite generate contacts --server "$HOST" --name "$USER" --password "$PASS" --source ./contactTemplates.json --numberOfContacts 30

echo "Generating Appointments"
appsuite generate appointments --server "$HOST" --name "$USER" --password "$PASS" --source appointmentTemplates.json --days 180
