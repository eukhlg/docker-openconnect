# Build Stage
FROM alpine:3.21.0 AS builder

ARG OPENCONNECT_VERSION=9.12

		#p11-kit libp11 libproxy \
		#libtasn1 gettext \
		# gnutls-dev \
RUN apk add --no-cache \
		libxml2-dev \
		zlib \
		openssl-dev \
		automake autoconf pkgconf \
		curl g++ linux-headers make tar xz gettext lynx \
	&& mkdir -p /usr/src/openconnect \
	&& curl -SL --connect-timeout 8 --max-time 120 --retry 128 --retry-delay 5 \
	"https://www.infradead.org/openconnect/download/openconnect-${OPENCONNECT_VERSION}.tar.gz" -o openconnect.tar.xz \
	&& tar -xf openconnect.tar.xz -C /usr/src/openconnect --strip-components=1 \
	&& rm openconnect.tar.xz* \
	&& cd /usr/src/openconnect \
	&& ./configure --with-vpnc-script=/etc/vpnc/vpnc-script \
	&& make \
	&& make install \
	&& lynx -dump -nolist https://www.infradead.org/openconnect/manual.html \
	| awk '/^OPTIONS$/ {flag=1; next} /^SIGNALS$/ {flag=0} flag { $1=$1; print ($0 == "" ? "" : "# " $0) }' \
	| sed -E '/^$/ { N; s/\n(#[[:space:]]-[a-zA-Z],--|#[[:space:]]--)/\n#/; }' > /tmp/openconnect-default.conf

# Runtime Stage
FROM alpine:3.20.3

# Copy compiled binary from builder stage
COPY --from=builder /usr/local/sbin/ /usr/local/sbin/
COPY --from=builder /usr/local/lib/*openconnect.so* /usr/local/lib/
COPY --from=builder /tmp/openconnect-default.conf /tmp/openconnect-default.conf
COPY --chmod=755 openconnect_pwd.sh /usr/local/sbin/openconnect_pwd

# Captures options section of HTML Manual, normalizes it an comments all strings
#lynx -dump -nolist https://www.infradead.org/openconnect/manual.html \
#| awk '/^OPTIONS$/ {flag=1; next} /^SIGNALS$/ {flag=0} flag { $1=$1; print ($0 == "" ? "" : "# " $0) }'

# Improoved version which also removes -- in front of each parameter
#lynx -dump -nolist https://www.infradead.org/openconnect/manual.html \
#| awk '/^OPTIONS$/ {flag=1; next} /^SIGNALS$/ {flag=0} flag { $1=$1; print ($0 == "" ? "" : "# " $0) }' \
#| sed -E '/^$/ { N; s/\n(#[[:space:]]-[a-zA-Z],--|#[[:space:]]--)/\n#/; }'


#&& runDeps="$(apk list | grep "$(scanelf --needed --nobanner /usr/local/bin/openconnect \
#    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
#    | xargs -r -n1 -I{} sh -c 'apk info "{}" | head -n1 \
#    | sed "s/ description:.*//"')" \
#    | awk -F'[{}]' '{print $2}' | sort -u)" \
#&& apk add --no-cache ${runDeps} lynx curl \

# lynx curl gnutls libxml2 libp11 p11-kit libproxy libtasn1 \

RUN apk add --no-cache \
	curl openssl libxml2 libproxy \
	&& mkdir -p /etc/openconnect/certs /etc/vpnc /var/run/openconnect \
	&& curl -SL --connect-timeout 8 --max-time 120 --retry 128 --retry-delay 5 \
	"https://gitlab.com/openconnect/vpnc-scripts/raw/master/vpnc-script" -o /etc/vpnc/vpnc-script \
	&& chmod +x /etc/vpnc/vpnc-script

# Create openconnect user
RUN addgroup -S openconnect \
    && adduser -S openconnect -G openconnect \
    && chown -R openconnect:openconnect /var/run/openconnect

WORKDIR /etc/openconnect

COPY --chmod=755 docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

#EXPOSE 443
CMD ["openconnect_pwd", "--config", "/etc/openconnect/openconnect.conf"]
