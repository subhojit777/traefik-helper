#!/bin/sh

CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

YML_TEMPLATE="$CURRENTDIR/traefik-helper.yml";
YML_TEMPLATE_DEFAULT="$CURRENTDIR/traefik-helper.default.yml";

if [ ! -e "$YML_TEMPLATE" ]; then
  # Custom yml file not preset, use default.
  YML_TEMPLATE="$YML_TEMPLATE_DEFAULT";
fi

YML_FILE_LOCATION="/tmp/traefik-helper.yml";
TRAEFIC_COMMAND="docker-compose -f $YML_FILE_LOCATION";

if [ "$1" = "" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
  echo "Manage Traefik Docker container with docker-compose.

Usage:
$0 [ARGS...]

[ARGS...] will be passed directly to docker-compose.

Examples:
$0 up -d  # Bring up Traefik Docker container.
$0 start  # Start Traefik Docker container.
$0 stop   # Stop Traefik Docker container.
$0 down   # Bring down Traefik Docker container.";
  exit 0;
fi

# Get all networks.
NETWORKS=`docker network ls | grep '_default' | awk "{print \\$2}"`;

if [ "$NETWORKS" = "" ]; then
  echo "**Error: No networks found. Start Docker containers first.";
  exit 0;
fi

# Build token replacements for the yml file.
NETWORK_LIST='';
NETWORK_SECTION='';
for n in $NETWORKS
do
  NETWORK_LIST="$NETWORK_LIST      - $n
";
  NETWORK_SECTION="$NETWORK_SECTION  $n:
    external:
      name: $n
";
done

echo "Networks found:";
echo "---------------";
echo "$NETWORKS";
echo "";

# Read the yml and replace tokens.
YML=$(<"$YML_TEMPLATE");
YML="${YML/~NETWORK_LIST~/${NETWORK_LIST}}";
YML="${YML/~NETWORK_SECTION~/${NETWORK_SECTION}}";

# Write the yml file out.
echo "$YML" > "$YML_FILE_LOCATION";

# Run the docker-compose command with passed arguments.
$TRAEFIC_COMMAND $@;
