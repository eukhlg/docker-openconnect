# Build Stage
ARG BASE_VERSION=3.21.0


FROM alpine:${BASE_VERSION} AS builder
ARG OPENCONNECT_VERSION=9.12

RUN apk add --no-cache \
		autoconf \
		automake \
		curl \
		g++ \
		gettext \
		gnutls-dev \
		libp11 \
		libproxy \
		libtasn1 \
		libxml2-dev \
		linux-headers \
		lynx \
		make \
		p11-kit \
		pkgconf \
		tar \
		xz \
		zlib \
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
FROM alpine:${BASE_VERSION}

# Set environment variables
ENV WORKDIR="/etc/openconnect"
ENV CONFIG_FILE="${WORKDIR}/openconnect.conf"
ENV DEFAULT_CONFIG_FILE="/tmp/openconnect-default.conf"

# Copy compiled binary from builder stage
COPY --from=builder /usr/local/sbin/ /usr/local/sbin/
COPY --from=builder /usr/local/lib/*openconnect.so* /usr/local/lib/
COPY --from=builder /tmp/openconnect-default.conf "${DEFAULT_CONFIG_FILE}"

# Add dependencies
RUN apk add --no-cache \
	curl \
	gnutls \
	gnutls-utils \
	libp11 \
	libproxy \
	libtasn1 \
	libxml2 \
	p11-kit \
	zlib \
	&& mkdir -p /etc/openconnect/certs /etc/vpnc /var/run/openconnect \
	&& curl -SL --connect-timeout 8 --max-time 120 --retry 128 --retry-delay 5 \
	"https://gitlab.com/openconnect/vpnc-scripts/raw/master/vpnc-script" -o /etc/vpnc/vpnc-script \
	&& chmod +x /etc/vpnc/vpnc-script

# Create openconnect user
RUN addgroup -S openconnect \
    && adduser -S openconnect -G openconnect \
    && chown -R openconnect:openconnect /var/run/openconnect

WORKDIR ${WORKDIR}

COPY --chmod=755 docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/sh", "-c", "echo \"${USER_PASSWORD}\" | openconnect --non-inter --passwd-on-stdin --config \"${CONFIG_FILE}\""]