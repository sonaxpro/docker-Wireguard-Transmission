#!/bin/bash

# Loop through 1 to 100 to check IP via ifconfig.io
for i in $(seq 1 100); do
    echo -n "Attempt $i: "
    # Execute curl command in docker container
    docker exec transmission sh -c 'curl -4 ifconfig.io' || echo "Failed"
    echo ""
    echo "Sleeping for 5 seconds..."
    sleep 5
done



# for i in $(seq 1 100); do echo -n "$i: "; docker exec transmission sh -c 'curl -4 ifconfig.io' || echo "❌"; echo "sleep 5"; sleep 5; done
