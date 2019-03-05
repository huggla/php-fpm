ARG TAG="20190220"
ARG DESTDIR="/php"

FROM huggla/alpine as alpine

ARG BUILDDEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c argon2-dev coreutils curl-dev libedit-dev libsodium-dev libxml2-dev libressl-dev sqlite-dev"
ARG VERSION="7.3.2"
ARG DOWNLOAD="https://secure.php.net/get/php-$VERSION.tar.xz/from/this/mirror"
ARG CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ARG CPPFLAGS="$PHP_CFLAGS"
ARG LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ARG DESTDIR
ARG INIDIR="/etc/php"

RUN apk add $BUILDDEPS \
 && mkdir -p "$INIDIR/conf.d" \
 && downloadDir="$(mktemp -d)" \
 && cd $downloadDir \
 && wget "$DOWNLOAD" \
 && buildDir="$(mktemp -d)" \
 && cd $buildDir \
 && tar -xJvp -f "$downloadDir/$(basename "$DOWNLOAD")" --strip-components=1 \
 && rm -rf "$downloadDir" \
 && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure --build="$gnuArch" --with-config-file-path="$INIDIR" --with-config-file-scan-dir="$INIDIR/conf.d" --enable-option-checking=fatal --with-mhash --enable-ftp --enable-mbstring --enable-mysqlnd --with-password-argon2 --with-sodium=shared --with-curl --with-libedit --with-openssl --with-zlib $(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
 && make -j "$(nproc)" \
	&& find -type f -name '*.a' -delete \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
 && make clean \
 && cp -v php.ini-* "$INIDIR/" \
	&& cd / \
 && rm -rf "$buildDir" \
 && scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
 && pecl update-channels \
 && rm -rf /tmp/pear ~/.pearrc

FROM huggla/busybox:$TAG as image

ARG DESTDIR

COPY --from=alpine $DESTDIR $DESTDIR
