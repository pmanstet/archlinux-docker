# build archlinux:base-devel

**Note**: requires an archlinux host

```shell
# sudo pacman -Sy make devtools git podman fakechroot fakeroot
make clean
make image-base-devel
podman image ls
podman run -it --rm localhost/archlinux/archlinux:base-devel
```

# build/test archlinux:jupyterlab

```shell
# create volume to be used as home and populate with /etc/skel of host
podman volume rm demohome || true
podman volume create demohome --opt o=uid=$(id -u),gid=$(id -g)
DEMOHOME=$(podman volume inspect demohome --format={{.Mountpoint}})
podman unshare cp -r /etc/skel/. "${DEMOHOME}/"
sudo chown --reference "${DEMOHOME}" -R "${DEMOHOME}"
podman unshare ls -la "${DEMOHOME}"

# build image
podman build -f jupyterlab/Dockerfile.jupyterlab -t localhost/archlinux/archlinux:jupyterlab jupyterlab
podman image ls
podman image prune

# start local jupyter lab (overrule default entrypoint)
podman run --rm -it \
    -p 8888:8888 \
    -e NB_UID=$(id -u) \
    -e NB_GID=$(id -g) \
    -e NB_USER=$(id -nu) \
    -v demohome:/home/$(id -nu) \
    -w /home/$(id -nu) \
    localhost/archlinux/archlinux:jupyterlab

# start "fake" jupyter hub -> expected to fail as no hub is running
podman run --rm -it -e JUPYTERHUB_SERVICE_URL="fake" \
    -e NB_UID=$(id -u) \
    -e NB_GID=$(id -g) \
    -e NB_USER=$(id -nu) \
    -v demohome:/home/$(id -nu) \
    -w /home/$(id -nu) \
    localhost/archlinux/archlinux:jupyterlab

# cleanup    
podman volume rm demohome
```

# publish archlinux/archlinux:jupyterlab

```shell
# OWN_REGISTRY=...
# OWN_PROJECT=...
# OWN_USERNAME=...
podman login -u "${OWN_USERNAME}" "${OWN_REGISTRY}" --password-stdin <<< $(pass "${OWN_REGISTRY}/${OWN_USERNAME}")

podman tag localhost/archlinux/archlinux:jupyterlab "${OWN_REGISTRY}/${OWN_PROJECT}/archlinux:jupyterlab"
podman image ls | grep "${OWN_REGISTRY}"
podman push "${OWN_REGISTRY}/${OWN_PROJECT}/archlinux:jupyterlab"

podman logout "${OWN_REGISTRY}" || true
```
