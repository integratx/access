#!/bin/bash

# Run this script with the provided token and routing number to download the integratx agent package

if [ $# -ne 3 ]; then
    echo "Usage: $0 <token> <routing #> <host>" >&2
    exit 1
fi

# classic or fine-grained PAT with “read” on contents
export GH_TOKEN="$1"
export ROUTING_NUMBER="$2"
export AGENT_HOST="$3"

OWNER="integratx"                # repo owner
REPO="agent"
TAG="v1.0.beta"
PACKAGE="itx-agent-package"
NAME="$PACKAGE.tar.gz"
CHECK="checksum"

# 1 – look up the tar file id from the tagged release
asset_id=$(curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG" |
  jq -r --arg NAME "$NAME" '.assets[]|select(.name==$NAME)|.id')

# 2 – stream the tar file
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
if sha256sum -c checksum; then
    echo "Checksum verification passed."
else
    echo "Checksum verification failed."
    exit 1
fi

# Extract agent package from tar file
tar -xzf $NAME

# Initialize agent
$PACKAGE/init_agent.sh "$GH_TOKEN" "$ROUTING_NUMBER" "$AGENT_HOST"

exit 0