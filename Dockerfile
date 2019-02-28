ARG TAG="20190220"

FROM huggla/alpine-official as alpine

ARG BUILDDEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2cargon2-dev coreutils curl-dev libedit-dev libsodium-dev libxml2-dev libressl-dev sqlite-dev"
ARG VERSION="7.3.2"
ARG DOWNLOAD="https://secure.php.net/get/php-$VERSION.tar.xz/from/this/mirror"
ARG CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ARG CPPFLAGS="$PHP_CFLAGS"
ARG LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ARG INI_DIR="/etc/php"

RUN apk add $BUILDDEPS \
 && mkdir -p "$INI_DIR" \
 && downloadDir="$(mktemp -d)" \
 && cd $downloadDir \
 && wget "$DOWNLOAD" \
 && buildDir="$(mktemp -d)" \
 && cd $buildDir \
 && tar -xJvp -f "$downloadDir/$(basename "$DOWNLOAD")" --strip-components=1 \
 
 
 && pip3 --no-cache-dir install --upgrade pip \
 && pip3 --no-cache-dir install gunicorn \
 && git clone --branch $PGADMIN4_TAG --depth 1 https://git.postgresql.org/git/pgadmin4.git \
 && pip3 --no-cache-dir install -r $buildDir/pgadmin4/requirements.txt \
 && cp -a $buildDir/pgadmin4/web /rootfs/pgadmin4 \
 && cp -a /usr/bin/gunicorn /rootfs/usr/bin/ \
 && cd / \
 && rm -rf $buildDir /rootfs/pgadmin4/regression /rootfs/pgadmin4/pgadmin/feature_tests \
 && find /rootfs/pgadmin4 -name tests -type d | xargs rm -rf \
 && mv /rootfs/pgadmin4 /pgadmin4 \
 && python3.6 -OO -m compileall /pgadmin4 \
 && mv /pgadmin4 /rootfs/pgadmin4 \
 && pip3 --no-cache-dir uninstall --yes pip \
 && cp -a /usr/lib/python3.6/site-packages /rootfs/usr/lib/python3.6/ \
&& apk --purge del $BUILDDEPS
