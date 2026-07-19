#!/bin/bash

set -Eeuo pipefail

declare -a join_flags
tok=/tmp/k0s-join-token
node_ip=$(ip addr | grep -o '10.200.0.[0-9]\+' | head -n 1)
usage="
usage: $(basename $0) ROLE [TOKEN]
where:
    ROLE        'worker' or 'controller'
    TOKEN       generated output of an existing controller
"

# Download k0s
[ ! -e /usr/local/bin/k0s ] && \
    curl --proto '=https' --tlsv1.2 -sSf https://get.k0s.sh | \
    sudo K0S_VERSION=v1.36.2+k0s.0 sh


if [ $# -lt 1 ]; then
    echo "$usage"
    exit 1
fi

# parse role
case "$1" in
    worker)
        join_flags+=(worker)
    ;;

    controller)
        sudo mkdir /etc/k0s 2>/dev/null || true
        k0s config create | sudo tee /etc/k0s/k0s.yaml >/dev/null

        sudo yq -yi \
            --arg nodeIp $node_ip \
            '
            .spec.api.address = $nodeIp |
            .spec.storage.etcd.peerAddress = $nodeIp |
            .spec.network.provider = "calico" |
            .spec.network.calico.mode = "bird" |
            .spec.network.calico.mtu = 1420 |
            .spec.network.nodeLocalLoadBalancing.enabled = true |
            .spec.telemetry.enabled = true |
            .spec.storage.etcd.extraArgs."heartbeat-interval" = "500" |
            .spec.storage.etcd.extraArgs."election-timeout" = "5000"
            ' /etc/k0s/k0s.yaml

        join_flags+=(
            controller -c /etc/k0s/k0s.yaml
            --enable-worker --no-taints
        )

        [ "$(uname -m)" == aarch64 ] && join_flags+=(-e ETCD_UNSUPPORTED_ARCH=arm)
        ;;

    -h|--help)
        echo "$usage"
        exit 0
        ;;

    *)
        echo "$usage"
        exit 1
        ;;
esac


if [ $# -gt 1 ]; then
    echo "$2" > $tok
    join_flags+=(--token-file $tok)
fi


sudo k0s install ${join_flags[@]} \
    --kubelet-extra-args="--node-ip=$node_ip" \
    --start
