#!/bin/sh
set -e  # Exit on error

check_file_existence() {

  local FILE_PATH="$1"

  if [ -f "${FILE_PATH}" ]; then
    echo "${FILE_PATH}"
  else
    echo ""
  fi
}

generate_server_cert_pin() {

  local SERVER_CERT_FILE="$1"

if [ -n "${SERVER_CERT_FILE}" ]; then

    echo "pin-sha256:$(certtool --pubkey-info --infile "${SERVER_CERT_FILE}" --outder \
    | sha256sum \
    | awk '{print $1}' \
    | xxd -r -p \
    | base64)"
fi

}

set_defaults() {
#BASE_MTU=${BASE_MTU:-1300}
#CA_CERT=$(check_file_existence "${CA_CERT:-certs/ca.pem}")
#DTLS_CHIPHERS=${DTLS_CHIPHERS:-"NONE:+VERS-DTLS1.2:+COMP-NULL:+AES-256-CBC:+SIGN-RSA-SHA1:+SHA1:+RSA"}
#DTLS_LOCAL_PORT=${DTLS_LOCAL_PORT:-8443}
INTERFACE=${INTERFACE:-"ocon0"}
NO_SYSTEM_TRUST=${NO_SYSTEM_TRUST:-true}
#PROTOCOL=${PROTOCOL:-"anyconnect"}
#SERVER=${SERVER:-"vpn.bigcorp.com"}
#SERVER_CERT=$(check_file_existence "${SERVER_CERT:-certs/server.pem}")
SERVER_CERT_PIN=$(generate_server_cert_pin "${SERVER_CERT}")
#USER_CERT=$(check_file_existence "${USER_CERT:-certs/client.pem}")
#USER_NAME=${USER_NAME:-"test"}
#USER_PASSWORD=${USER_PASSWORD:-"test"}
#USER_PKEY=$(check_file_existence "${USER_PKEY:-certs/key.pem}")
#VERBOSE=${VERBOSE:-FALSE}
}

update_config_option() {
    local OPTION="$1"
    local VALUE="$2"
    local LOWER_VALUE=$(echo "${VALUE}" | tr '[:upper:]' '[:lower:]')

    # Process the config file
    {
        if [ "${LOWER_VALUE}" = "true" ]; then
            # Case 1: Uncomment the option if it exists as a commented line
            sed -E "s|^\s*#\s*(${OPTION}\b)|\1|" "${DEFAULT_CONFIG_FILE}"
        elif [ "${LOWER_VALUE}" != "false" ] && [ -n "${VALUE}" ]; then
            # Case 2: Update or add the option with the provided value
            if grep -qE "^\s*#\s*${OPTION}\s*=" "${DEFAULT_CONFIG_FILE}"; then
                # Case 2a: Uncomment and update the existing commented option
                sed -E "s|^\s*#\s*(${OPTION}\s*=).*|\1${VALUE}|" "${DEFAULT_CONFIG_FILE}"
            elif grep -qE "^\s*${OPTION}\s*=" "${DEFAULT_CONFIG_FILE}"; then
                # Case 2b: Update the existing uncommented option
                sed -E "s|^\s*(${OPTION}\s*=).*|\1${VALUE}|" "${DEFAULT_CONFIG_FILE}"
            else
                # Case 2c: Append the option if it doesn't exist
                echo "${OPTION}=${VALUE}"
            fi
        fi
    } | sed -e "/^\s*#/d; /^\s*$/d" >> "${CONFIG_FILE}"
}


update_config() {

 # Setup configuration
  update_config_option "base-mtu" "${BASE_MTU}"
  update_config_option "cafile" "${CA_CERT}"
  update_config_option "dtls-ciphers" "${DTLS_CHIPHERS}"
  update_config_option "dtls-local-port" "${DTLS_LOCAL_PORT}"
  update_config_option "interface" "${INTERFACE}"
  update_config_option "no-system-trust" "${NO_SYSTEM_TRUST}"
  update_config_option "protocol" "${PROTOCOL}"
  update_config_option "server" "https://${SERVER}"
  update_config_option "servercert" "${SERVER_CERT_PIN}"
  update_config_option "certificate" "${USER_CERT}"
  update_config_option "user" "${USER_NAME}"
  update_config_option "sslkey" "${USER_PKEY}"
  update_config_option "verbose" "${VERBOSE}"

}

# Main Execution
set_defaults
generate_server_cert_pin
update_config

# Run OpenConnect Server
exec "$@"

# Available options from Manual HTML

# --config=CONFIGFILE

# Read further options from CONFIGFILE before continuing to process
# options from the command line. The file should contain long-format
# options as would be accepted on the command line, but without the two
# leading -- dashes. Empty lines, or lines where the first non-space
# character is a # character, are ignored.

# Any option except the config option may be specified in the file.

# -b,--background

# Continue in background after startup

# --pid-file=PIDFILE

# Save the pid to PIDFILE when backgrounding

# -c,--certificate=CERT [,--mca-certificate=CERT]

# Use SSL client certificate CERT which may be either a file name or, if
# OpenConnect has been built with an appropriate version of GnuTLS, a
# PKCS#11 URL.

# The --mca-certificate option sets the secondary certificate for
# multi-certificate authentication (according to Cisco's terminology, the
# SSL client certificate is called the "machine" certificate, and the
# second certificate is called the "user" certificate).

# -e,--cert-expire-warning=DAYS

# Give a warning when SSL client certificate has DAYS left before expiry

# -k,--sslkey=KEY [,--mca-key=KEY]

# Use SSL private key KEY which may be either a file name or, if
# OpenConnect has been built with an appropriate version of GnuTLS, a
# PKCS#11 URL.

# The --mca-key option sets the private key for the secondary certificate
# (see --mca-certificate).

# -C,--cookie=COOKIE

# Use authentication cookie COOKIE.

# --cookie-on-stdin

# Read cookie from standard input.

# -d,--deflate

# Enable all compression, including stateful modes. By default, only
# stateless compression algorithms are enabled.

# -D,--no-deflate

# Disable all compression.

# --compression=MODE

# Set compression mode, where MODE is one of stateless, none, or all.

# By default, only stateless compression algorithms which do not maintain
# state from one packet to the next (and which can be used on UDP
# transports) are enabled. By setting the mode to all stateful algorithms
# (currently only zlib deflate) can be enabled. Or all compression can be
# disabled by setting the mode to none.

# --force-dpd=INTERVAL

# Use INTERVAL as Dead Peer Detection interval (in seconds). This will
# cause the client to use DPD at the specified interval even if the
# server hasn't requested it, or at a different interval from the one
# requested by the server.

# DPD mechanisms vary by protocol and by transport (TLS or DTLS/ESP), but
# are all functionally similar: they enable either the VPN client or the
# VPN server to transmit a signal to the peer, requesting an immediate
# reply which can be used to confirm that the link between the two peers
# is still working.

# -g,--usergroup=GROUP

# Set the URL path of the initial HTTPS connection to the server.

# With some protocols, this path may function as a login group or realm,
# hence the naming of this option. For example, the following invocations
# of OpenConnect are equivalent:
# openconnect --usergroup=loginPath vpn.server.com
# openconnect https://vpn.server.com/loginPath

# -F,--form-entry=FORM:OPTION[=VALUE]

# Provide authentication form input, where FORM and OPTION are the
# identifiers from the form and the specific input field, and VALUE is
# the string to be filled in automatically. For example, the standard
# username field (also handled by the --user option) could also be
# provided with this option thus: --form-entry main:username=joebloggs.

# If VALUE is not specified, this option will cause a hidden form field
# to be treated as a standard text-input field.

# This option should not be used to enter passwords. --passwd-on-stdin
# should be used for that purpose. Not only will this option expose the
# password value via the OpenConnect process's command line, but unlike
# --passwd-on-stdin this option will not recognize the case of an
# incorrect password, and stop trying to re-enter it repeatedly.

# -h,--help

# Display help text

# --http-auth=METHODS

# Use only the specified methods for HTTP authentication to a server. By
# default, only Negotiate, NTLM and Digest authentication are enabled.
# Basic authentication is also supported but because it is insecure it
# must be explicitly enabled. The argument is a comma-separated list of
# methods to be enabled. Note that the order does not matter: OpenConnect
# will use Negotiate, NTLM, Digest and Basic authentication in that
# order, if each is enabled, regardless of the order specified in the
# METHODS string.

# --external-browser=BROWSER

# Set BROWSER as the executable used by OpenConnect to handle the
# authentication process with gateways that support the
# single-sign-on-external-browser authentication method.

# -i,--interface=IFNAME

# Use IFNAME for tunnel interface

# -l,--syslog

# After tunnel is brought up, use syslog for further progress messages

# --timestamp

# Prepend a timestamp to each progress message

# --passtos

# Copy TOS / TCLASS of payload packet into DTLS and ESP packets. This is
# not set by default because it may leak information about the payload
# (for example, by differentiating voice/video traffic).

# -U,--setuid=USER

# Drop privileges after connecting, to become user USER

# --csd-user=USER

# Drop privileges during execution of trojan binary or script (CSD, TNCC,
# or HIP).

# --csd-wrapper=SCRIPT

# Run SCRIPT instead of the trojan binary or script.

# --force-trojan=INTERVAL

# Use INTERVAL as interval (in seconds) for repeat execution of Trojan
# binary or script, overriding default and/or server-set interval.

# -m,--mtu=MTU

# Request MTU from server as the MTU of the tunnel.

# --base-mtu=MTU

# Indicate MTU as the path MTU between client and server on the
# unencrypted network. Newer servers will automatically calculate the MTU
# to be used on the tunnel from this value.

# -p,--key-password=PASS [,--mca-key-password=PASS]

# Provide passphrase for certificate file, or SRK (System Root Key) PIN
# for TPM

# --mca-key-password provides the passphrase for the secondary
# certificate (see --mca-certificate).

# -P,--proxy=PROXYURL

# Use HTTP or SOCKS proxy for connection. A username and password can be
# provided in the given URL, and will be used for authentication. If
# authentication is required but no credentials are given, GSSAPI and
# automatic NTLM authentication using Samba's ntlm_auth helper tool may
# be attempted.

# --proxy-auth=METHODS

# Use only the specified methods for HTTP authentication to a proxy. By
# default, only Negotiate, NTLM and Digest authentication are enabled.
# Basic authentication is also supported but because it is insecure it
# must be explicitly enabled. The argument is a comma-separated list of
# methods to be enabled. Note that the order does not matter: OpenConnect
# will use Negotiate, NTLM, Digest and Basic authentication in that
# order, if each is enabled, regardless of the order specified in the
# METHODS string.

# --no-proxy

# Disable use of proxy

# --libproxy

# Use libproxy to configure proxy automatically (when built with libproxy
# support)

# --key-password-from-fsid

# Passphrase for certificate file is automatically generated from the
# fsid of the file system on which it is stored. The fsid is obtained
# from the statvfs(2) or statfs(2) system call, depending on the
# operating system. On a Linux or similar system with GNU coreutils, the
# fsid used by this option should be equal to the output of the command:
# stat --file-system --printf=%i\\n $CERTIFICATE
# It is not the same as the 128-bit UUID of the file system.

# -q,--quiet

# Less output

# -Q,--queue-len=LEN

# Set packet queue limit to LEN packets. The default is 32. A high value
# may allow better overall bandwidth but at a cost of latency. If you run
# Voice over IP or other interactive traffic over the VPN, you don't want
# those packets to be queued behind thousands of other large packets
# which are part of a bulk transfer.

# This option sets the maximum inbound and outbound packet queue sizes in
# OpenConnect itself, which control how many packets will be sent and
# received in a single batch, as well as affecting other buffering such
# as the socket send buffer (SO_SNDBUF) for network connections and the
# OS tunnel device.

# Ultimately, the right size for a queue is "just enough packets that it
# never quite gets empty before more are pushed to it". Any higher than
# that is simply introducing bufferbloat and additional latency with no
# benefit. With the default of 32, we are able to saturate a single
# Gigabit Ethernet from modest hardware, which is more than enough for
# most VPN users.

# If OpenConnect is built with vhost-net support, it will only be used if
# the queue length is set to 16 or more. This is because vhost-net
# introduces a small amount of additional latency, but improves total
# bandwidth quite considerably for those operating at high traffic rates.
# Thus it makes sense to use it when the user has indicated a preference
# for bandwidth over latency, by increasing the queue size.

# -s,--script=SCRIPT

# Invoke SCRIPT to configure the network after connection. Without this,
# routing and name service are unlikely to work correctly. The script is
# expected to be compatible with the vpnc-script which is shipped with
# the "vpnc" VPN client. See
# https://www.infradead.org/openconnect/vpnc-script.html for more
# information. This version of OpenConnect is configured to use
# /etc/vpnc/vpnc-script by default.

# On Windows, a relative directory for the default script will be handled
# as starting from the directory that the openconnect executable is
# running from, rather than the current directory. The script will be
# invoked with the command-based script host cscript.exe.

# -S,--script-tun

# Pass traffic to 'script' program over a UNIX socket, instead of to a
# kernel tun/tap device. This allows the VPN IP traffic to be handled
# entirely in userspace, for example by a program which uses lwIP to
# provide SOCKS access into the VPN.

# --server=[https://]HOST[:PORT][/PATH]

# Define the VPN server as a simple HOST or as an URL containing the HOST
# and optionally the PORT number and the PATH; with some protocols, the
# path may function as a login group or realm, and it may equivalently be
# specified with --usergroup.

# As an alternative, define the VPN server as non-option command line
# argument.

# -u,--user=NAME

# Set login username to NAME

# -V,--version

# Report version number

# -v,--verbose

# More output (may be specified multiple times for additional output)

# -x,--xmlconfig=CONFIG

# XML config file

# --authgroup=GROUP

# Select GROUP from authentication dropdown or list entry.

# Many VPNs require a selection from a dropdown or list during the
# authentication process. This selection may be known as authgroup (on
# Cisco VPNs), realm (Juniper, Pulse, Fortinet), domain (F5), and gateway
# (GlobalProtect). This option attempts to automatically fill the
# appropriate protocol-specific field with the desired value.

# --authenticate

# Authenticate to the VPN, output the information needed to make the
# connection in a form which can be used to set shell environment
# variables, and then exit.

# When invoked with this option, OpenConnect will not actually create the
# VPN connection or configure a tunnel interface, but if successful will
# print something like the following to stdout:
# COOKIE='3311180634@13561856@1339425499@B315A0E29D16C6FD92EE...'
# HOST='10.0.0.1'
# CONNECT_URL='https://vpnserver.example.com'
# FINGERPRINT='469bb424ec8835944d30bc77c77e8fc1d8e23a42'
# RESOLVE='vpnserver.example.com:10.0.0.1'
# Thus, you can invoke openconnect as a non-privileged user (with access
# to the user's PKCS#11 tokens, etc.) for authentication, and then invoke
# openconnect separately to make the actual connection as root:
# eval `openconnect --authenticate https://vpnserver.example.com`;
# [ -n ["$COOKIE"] ] && echo ["$COOKIE"] |
# sudo openconnect --cookie-on-stdin $CONNECT_URL --servercert
# $FINGERPRINT --resolve $RESOLVE

# Earlier versions of OpenConnect produced only the HOST variable
# (containing the numeric server address), and not the CONNECT_URL or
# RESOLVE variables. Subsequently, we discovered that servers behind
# proxies may not respond correctly unless the correct DNS name is
# present in the connection phase, and we added support for VPN protocols
# where the server URL's path component may be significant in the
# connection phase, prompting the addition of CONNECT_URL and RESOLVE,
# and the recommendation to use them as described above. If you are not
# certain that you are invoking a newer version of OpenConnect which
# outputs these variables, use the following command-line (compatible
# with most Bourne shell derivatives) which will work with either a newer
# or older version:
# sudo openconnect --cookie-on-stdin ${CONNECT_URL:-$HOST} --servercert
# $FINGERPRINT ${RESOLVE:+--resolve=$RESOLVE}

# --cookieonly

# Fetch and print cookie only; don't connect (this is essentially a
# subset of --authenticate).

# --printcookie

# Print cookie to stdout before connecting (see --authenticate for the
# meaning of this cookie)

# --cafile=FILE

# Additional CA file for server verification. By default, this simply
# causes OpenConnect to trust additional root CA certificate(s) in
# addition to those trusted by the system. Use --no-system-trust to
# prevent OpenConnect from trusting the system default certificate
# authorities.

# --no-system-trust

# Do not trust the system default certificate authorities. If this option
# is given, only certificate authorities given with the --cafile option,
# if any, will be trusted automatically.

# --disable-ipv6

# Do not advertise IPv6 capability to server

# --dtls-ciphers=LIST

# Set OpenSSL ciphers to support for DTLS

# --dtls12-ciphers=LIST

# Set OpenSSL ciphers for Cisco's DTLS v1.2

# --dtls-local-port=PORT

# Use PORT as the local port for DTLS and UDP datagrams

# --dump-http-traffic

# Enable verbose output of all HTTP requests and the bodies of all
# responses received from the server.

# --pfs

# Enforces Perfect Forward Secrecy (PFS). That ensures that if the
# server's long-term key is compromised, any session keys established
# before the compromise will be unaffected. If this option is provided
# and the server does not support PFS in the TLS channel the connection
# will fail.

# PFS is available in Cisco ASA releases 9.1(2) and higher; a suitable
# cipher suite may need to be manually enabled by the administrator using
# the ssl encryption setting.

# --no-dtls

# Disable DTLS and ESP

# --no-http-keepalive

# Version 8.2.2.5 of the Cisco ASA software has a bug where it will
# forget the client's SSL certificate when HTTP connections are being
# re-used for multiple requests. So far, this has only been seen on the
# initial connection, where the server gives an HTTP/1.0 redirect
# response with an explicit Connection: Keep-Alive directive. OpenConnect
# as of v2.22 has an unconditional workaround for this, which is never to
# obey that directive after an HTTP/1.0 response.

# However, Cisco's support team has failed to give any competent response
# to the bug report and we don't know under what other circumstances
# their bug might manifest itself. So this option exists to disable ALL
# re-use of HTTP sessions and cause a new connection to be made for each
# request. If your server seems not to be recognizing your certificate,
# try this option. If it makes a difference, please report this
# information to the openconnect-devel@lists.infradead.org mailing list.

# --no-passwd

# Never attempt password (or SecurID) authentication.

# --no-external-auth

# Prevent OpenConnect from advertising to the server that it supports any
# kind of authentication mode that requires an external browser.

# Some servers will force the client to use such an authentication mode
# if the client advertises it, but fallback to a more "scriptable"
# authentication mode if the client doesn't appear to support it.

# --no-xmlpost

# Do not attempt to post an XML authentication/configuration request to
# the server; use the old style GET method which was used by older
# clients and servers instead.

# This option is a temporary safety net, to work around potential
# compatibility issues with the code which falls back to the old method
# automatically. It causes OpenConnect to behave more like older versions
# (4.08 and below) did. If you find that you need to use this option,
# then you have found a bug in OpenConnect. Please see
# https://www.infradead.org/openconnect/mail.html and report this to the
# developers.

# --allow-insecure-crypto

# The ancient, broken 3DES and RC4 ciphers are insecure; we explicitly
# disable them by default. However, some still-in-use VPN servers can't
# do any better.

# This option enables use of these insecure ciphers, as well as the use
# of SHA1 for server certificate validation.

# --non-inter

# Do not expect user input; exit if it is required.

# --passwd-on-stdin

# Read password from standard input

# --protocol=PROTO

# Select VPN protocol PROTO to be used for the connection. Supported
# protocols are anyconnect for Cisco AnyConnect (the default), nc for
# experimental support for Juniper Network Connect (also supported by
# most Ivanti/Pulse Connect Secure servers), pulse for experimental
# support for Ivanti/Pulse Connect Secure, gp for experimental support
# for Palo Alto Networks GlobalProtect, f5 for experimental support for
# F5 Big-IP, fortinet for experimental support for Fortinet Fortigate,
# and array for experimental support for Array Networks SSL VPN.

# See https://www.infradead.org/openconnect/protocols.html for details on
# features and deficiencies of the individual protocols.

# OpenConnect does not yet support all of the authentication options used
# by Pulse, nor does it support Host Checker/TNCC with Pulse. If your
# Junos/Ivanti Pulse VPN is not yet supported with --protocol=pulse, then
# --protocol=nc may be a useful fallback option.

# --token-mode=MODE

# Enable one-time password generation using the MODE algorithm.
# --token-mode=rsa will call libstoken to generate an RSA SecurID
# tokencode, --token-mode=totp will generate an RFC 6238 time-based
# password, and --token-mode=hotp will generate an RFC 4226 HMAC-based
# password. Yubikey tokens which generate OATH codes in hardware are
# supported with --token-mode=yubioath. --token-mode=oidc will use the
# provided OpenIDConnect token as an RFC 6750 bearer token.

# --token-secret={ SECRET[,COUNTER] | @FILENAME }

# The secret to use when generating one-time passwords/verification
# codes. Base 32-encoded TOTP/HOTP secrets can be used by specifying
# "base32:" at the beginning of the secret, and for HOTP secrets the
# token counter can be specified following a comma.

# RSA SecurID secrets can be specified as an Android/iPhone URI or a raw
# numeric CTF string (with or without dashes).

# For Yubikey OATH the token secret specifies the name of the credential
# to be used. If not provided, the first OATH credential found on the
# device will be used.

# For OIDC the secret is the bearer token to be used.

# FILENAME, if specified, can contain any of the above strings. Or, it
# can contain a SecurID XML (SDTID) seed.

# If this option is omitted, and --token-mode is "rsa", libstoken will
# try to use the software token seed saved in ~/.stokenrc by the "stoken
# import" command.

# --reconnect-timeout=SECONDS

# After disconnection or Dead Peer Detection, keep trying to reconnect
# for SECONDS. The default is 300 seconds, which means that openconnect
# can recover a VPN connection after a temporary network outage lasting
# up to 300 seconds.

# --resolve=HOST:IP

# Automatically resolve the hostname HOST to IP instead of using the
# normal resolver to look it up.

# --sni=HOST

# When creating new TLS connections, always present the hostname HOST as
# the SNI (Server Name Indication) in place of the correct hostname,
# which will still be sent in the HTTP 'Host:' header, and expect the
# peer's certificate to match the SNI rather than the correct hostname.
# This may be useful for Domain Fronting, by which some filtered or
# censored Internet connections can be bypassed.

# Note that sending different values for the SNI and 'Host:' header
# violates HTTP standards and is prevented by many cloud hosting
# providers.

# --servercert=HASH

# Accept server's SSL certificate only if it matches the provided
# fingerprint. This option implies --no-system-trust, and may be
# specified multiple times in order to accept multiple possible
# fingerprints.

# The allowed fingerprint types are SHA1, SHA256, and PIN-SHA256. They
# are distinguished by the 'sha1:', 'sha256:' and 'pin-sha256:' prefixes
# to the encoded hash. The first two are custom identifiers providing hex
# encoding of the peer's public key, while 'pin-sha256:' is the RFC7469
# key PIN, which utilizes base64 encoding. To ease certain testing
# use-cases, a partial match of the hash will also be accepted, if it is
# at least 4 characters past the prefix.

# --useragent=STRING

# Use STRING as 'User-Agent:' field value in HTTP header.

# Some VPN servers may require specific values matching those sent by
# proprietary VPN clients in order to successfully authenticate or
# connect. For example, when connecting to a Cisco VPN server,
# --useragent 'AnyConnect Windows 4.10.06079' or --useragent 'Cisco
# AnyConnect VPN Agent for Windows 2.2.0133', or when connecting to a
# Pulse server, --useragent 'Pulse-Secure/9.1.11.6725'.

# --version-string=STRING

# Use STRING as the software version reported to the head end. (e.g.
# --version-string '2.2.0133')

# --local-hostname=STRING

# Use STRING as 'X-CSTP-Hostname:' field value in HTTP header. For
# example --local-hostname 'mypc', will advertise the value 'mypc' as the
# suggested hostname to point to the provided IP address.

# --os=STRING

# OS type to report to gateway. Recognized values are: linux, linux-64,
# win, mac-intel, android, apple-ios. Reporting a different OS type may
# affect the dynamic access policy (DAP) applied to the VPN session. If
# the gateway requires CSD, it will also cause the corresponding CSD
# trojan binary to be downloaded, so you may need to use --csd-wrapper if
# this code is not executable on the local machine.