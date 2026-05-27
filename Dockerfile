ARG DEBIAN_DIST=bookworm
FROM debian:trixie

ARG DEBIAN_DIST
ARG FORGEJO_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG FORGEJO_RELEASE

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/lib/systemd/system
RUN mkdir -p /output/usr/share/doc/forgejo
RUN mkdir -p /output/usr/share/bash-completion/completions
RUN mkdir -p /output/usr/share/zsh/vendor-completions
RUN mkdir -p /output/DEBIAN

COPY ${FORGEJO_RELEASE}/forgejo /output/usr/bin/forgejo
COPY output/forgejo.service /output/usr/lib/systemd/system/forgejo.service
COPY output/forgejo_bash_completion /output/usr/share/bash-completion/completions/forgejo
COPY output/_forgejo /output/usr/share/zsh/vendor-completions/_forgejo
COPY output/DEBIAN/control /output/DEBIAN/control
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
COPY output/DEBIAN/prerm /output/DEBIAN/prerm
COPY output/copyright /output/usr/share/doc/forgejo/copyright
COPY output/changelog.Debian /output/usr/share/doc/forgejo/changelog.Debian
COPY output/README.md /output/usr/share/doc/forgejo/README.md

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/forgejo/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/forgejo/changelog.Debian
RUN sed -i "s/FORGEJO_VERSION/$FORGEJO_VERSION/g" /output/usr/share/doc/forgejo/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/FORGEJO_VERSION/$FORGEJO_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

RUN chmod 755 /output/usr/bin/forgejo
RUN chmod 755 /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/prerm

RUN dpkg-deb --build /output /forgejo_${FULL_VERSION}.deb
