#!/bin/bash

exec_wait() {
    local controller=$1
    shift

    while ! res=$(docker exec k0s-$controller "$@" 2>/dev/null); do  
        sleep 1
    done

    echo "$res"
}

case "$1" in
    add)
        shift
        for i in $@; do
            # https://docs.k0sproject.io/v1.36.2+k0s.0/k0s-in-docker/

            if [ $i -ne $1 ]; then
                token=$(exec_wait $1 k0s token create --role=controller)

                join=(k0s controller --enable-worker --no-taints "$token")
            fi

            docker run -d --name k0s-$i --hostname k0s-$i \
                --tmpfs /run `# this is where k0s stores runtime data` \
                --privileged `# this is the easiest way to enable container-in-container workloads` \
                -p 5500$i:6443 `# publish the Kubernetes API server port` \
                docker.io/k0sproject/k0s:v1.36.2-k0s.0 \
                "${join[@]}"
        done

        exec_wait $1 k0s kubeconfig admin > ~/.kube/k0s-$1.config

        ;;

    del)
        shift
        for i in $@; do
            docker stop k0s-$i
            docker rm k0s-$i
        done

        rm ~/.kube/k0s-$1.config
    ;;
esac
