#!/bin/bash

# Default to signed commits in this repo
git config commit.gpgsign true

# sign tar archive
cd sl*
gpg --detach-sign --armor *.tar.xz

