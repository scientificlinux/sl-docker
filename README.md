# Dockerfiles

![sl-logo](http://ftp.scientificlinux.org/linux/scientific/graphics/latest/logo/sl-logo-48.png "SL Logo")

This repository provides Dockerfiles for [Scientific Linux](http://www.scientificlinux.org/) on [docker hub](https://hub.docker.com/r/scientificlinux/sl/).

Each release is in [its own branch](http://github.com/scientificlinux/sl-docker/branches) and contains the kickstart used to build the image.

These images are maintained by the Scientific Linux Team in [github](https://github.com/scientificlinux/sl-docker).

## Container Tags

A tag will be provided for each of the [maintained major releases](http://www.scientificlinux.org/downloads/sl-versions/) of Scientific Linux (`6`, `7`).

The `latest` tag will track the highest version numbered release of Scientific Linux.

Updated images will be released roughly once per month.

## Build Logs

The SL docker containers are built on our internal build system and packaged at [Docker Cloud](https://cloud.docker.com/app/scientificlinux/repository/docker/scientificlinux/sl/builds/).

## Getting Help

* [SL Faq](https://www.scientificlinux.org/documentation/faq)

* [Email Lists](https://www.scientificlinux.org/community)

## Docker, overlayfs, and yum

Recent Docker versions support the [overlayfs](https://docs.docker.com/engine/userguide/storagedriver/overlayfs-driver/) backend, which is enabled by default on most distros supporting it from Docker 1.13 onwards. On SL 6 and 7, that backend requires `yum-plugin-ovl` to be installed and enabled, which it is in our containers. Make it sure you retain the `plugins=1` option in `/etc/yum.conf` if you update that file; otherwise, you may encounter errors related to rpmdb checksum failure - see [Docker ticket 10180](https://github.com/docker/docker/issues/10180) for more details.

## Package docs and licence files

By default the SL docker images do not include these files.  If you require them, please remove `tsflags=nodocs` from `/etc/yum.conf` and run `yum reinstall mypackage` to recieve the documentation.

---
# Quick Reference

## Example Usage
You can try out the containers via:

```
$ docker pull scientificlinux/sl
$ docker run -it scientificlinux/sl:6 cat /etc/redhat-release
$ docker run -it scientificlinux/sl:7 cat /etc/redhat-release
```

## Enabling systemd in SL7
The SL7 docker container ships with systemd mostly functional.  You can build a SL7 systemd enabled container with the following Dockerfile

In order to run a container with systemd, you will need to mount the cgroups volumes from the host.

```
# Example SL7 systemd Dockerfile
FROM sl:7
ENV container docker
### To enable apache within the container uncomment the next two lines
# RUN yum -y install httpd; yum clean all; systemctl enable httpd.service
# EXPOSE 80
### To enable apache within the container uncomment the previous two lines
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
```

You can build and run this example (with apache) via:
```
$ docker build --rm -t local/mycontainer
$ docker run -ti -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 80:80 local/mycontainer
```
Which will run systemd within the container in a limited context.

It is recommended that you install any relevant [OCI hooks](https://www.opencontainers.org/) for your container host - such as `oci-register-machine` or `oci-systemd-hook`.

Some container hosts must add `-v /tmp/$(mktemp -d):/run` to the `docker run` command.

---
# About Scientific Linux

Scientific Linux is a [Fermilab](http://fnal.gov/) sponsored project.  Our primary user base is within the High Energy and High Intensity Physics community.  However, our users come from a wide variety of industries with various use cases all over the globe – and sometimes off of it!

Our Mission:
> Driven by Fermilab’s scientific mission and focusing on the changing needs of experimental facilities, Scientific Linux should provide a world class environment for scientific computing needs.

Scientific Linux is a rebuild of Red Hat Enterprise Linux (property of Red Hat Inc. NYSE:RHT).

Please see [About Scientific Linux](http://www.scientificlinux.org/about/) and [Why Make Scientific Linux](http://www.scientificlinux.org/about/why-make-scientific-linux/) for more information.

