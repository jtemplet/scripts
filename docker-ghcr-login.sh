#!/usr/bin/env fish

# Retrieve the token from Keychain
set TOKEN (security find-generic-password -s ghcr.io -a jtemplet -w)

# Use the token to log in to Docker
echo $TOKEN | docker login ghcr.io -u jtemplet --password-stdin
