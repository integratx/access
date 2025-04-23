#!/bin/bash

# Run this script with the provided token to download the integratx agent package

# classic or fine-grained PAT with “read” on contents
export GH_TOKEN=[pat]

OWNER="integratx"                # repo owner
REPO="agent"
TAG="v1.0.beta"
NAME="itx-agent-package.tar.gz"
CHECK="checksum"

# 1 – look up the asset id from the tagged release
asset_id=$(curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG" |
  jq -r --arg NAME "$NAME" '.assets[]|select(.name==$NAME)|.id')

# 2 – stream the asset
curl -L \
  -H "Accept: application/octet-stream" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -o "$NAME" \
  "https://api.github.com/repos/$OWNER/$REPO/releases/assets/$asset_id"

# 3 - look up the checksum id from the tagged release
checksum_id=$(curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG" |
  jq -r --arg NAME "$CHECK" '.assets[]|select(.name==$NAME)|.id')

# 4 – stream the checksum
curl -L \
-H "Accept: application/octet-stream" \
-H "Authorization: Bearer $GH_TOKEN" \
-H "X-GitHub-Api-Version: 2022-11-28" \
-o "$CHECK" \
"https://api.github.com/repos/$OWNER/$REPO/releases/assets/$checksum_id"

# 5 - verify the checksum
sha256sum -c <<< "$(cat checksum)"
