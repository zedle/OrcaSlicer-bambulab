# Linux bridge host + Bambu's Linux networking plug-in, for running the bridge on macOS (or anywhere) through Docker.
# On macOS the Mach-O plug-in only signs print commands inside a Bambu-signed app; the Linux plug-in has no such
# binding, so the same host runs here unchanged. Bambu publishes the Linux plug-in for x86-64 only.
#
# Plug-in 02.08.02.54 uses the PrintParams layout with task_timelapse_use_internal, svc_context, slicer_uid and
# queue_plate_id, which this source tree compiles under PJARCZAK_BAMBU_NETWORK_ABI_0209.
FROM --platform=linux/amd64 debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake libssl-dev libboost-filesystem-dev ca-certificates curl unzip binutils \
    && rm -rf /var/lib/apt/lists/*
COPY src /src
RUN cmake -S /src/tools/pjarczak_bambu_linux_host -B /build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-DPJARCZAK_BAMBU_NETWORK_ABI_0209=1" \
    && cmake --build /build --target pjarczak_bambu_linux_host_abi1 -j"$(nproc)"

ARG PLUGIN_VERSION=02.08.02.54
ARG PLUGIN_URL=https://public-cdn.bblmw.com/upgrade/studio/plugins/02.08.02.54/f1a94b8828/linux_02.08.02.54.zip
ARG PLUGIN_ZIP_SHA256=a7ea8ccec85ab5a7b8959a5697f7be957d58da82e67aad1cb0ad9b3cdf5baed6
ARG NETWORK_SO_SHA256=bba49709c8dea14ba70251b43965646c0a5e2cde8fd133c64f764d425691bdf2
ARG SOURCE_SO_SHA256=4e05f16fa02740fd12f0040b9efc3e70d43446c7a1a877c6a3926ef0758ca7db
ARG STUDIO_TAG=v02.08.02.61
ARG SLICER_CER_SHA256=f504dc1c37bc9741b7a95198914e67f3f6f1d917b1e45eaa14b9e84eb7b51ec8
ARG PRINTER_CER_SHA256=36f2bcee347ec7adce719b5fd350099591a4d3d0ec4e039c7019890d78e152a0
RUN mkdir -p /opt/bambu/cert \
    && curl -fsSL --max-filesize 134217728 -o /tmp/plugin.zip "$PLUGIN_URL" \
    && echo "$PLUGIN_ZIP_SHA256  /tmp/plugin.zip" | sha256sum -c - \
    && unzip -j /tmp/plugin.zip libbambu_networking.so libBambuSource.so -d /opt/bambu \
    && printf '%s  %s\n' "$NETWORK_SO_SHA256" /opt/bambu/libbambu_networking.so "$SOURCE_SO_SHA256" /opt/bambu/libBambuSource.so | sha256sum -c - \
    && for c in slicer_base64.cer printer.cer; do \
         curl -fsSL -o "/opt/bambu/cert/$c" "https://raw.githubusercontent.com/bambulab/BambuStudio/$STUDIO_TAG/resources/cert/$c"; done \
    && printf '%s  %s\n' "$SLICER_CER_SHA256" /opt/bambu/cert/slicer_base64.cer "$PRINTER_CER_SHA256" /opt/bambu/cert/printer.cer | sha256sum -c - \
    # The exports are extern "C", so the string ABI shows only in type names: the abi1 host needs std::__cxx11 strings.
    && strings -a /opt/bambu/libbambu_networking.so | grep -q 'NSt7__cxx1112basic_string' \
    && cp /build/tools/pjarczak_bambu_linux_host/pjarczak_bambu_linux_host_abi1 /opt/bambu/pjarczak_bambu_linux_host

FROM --platform=linux/amd64 debian:bookworm-slim AS x86
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libssl3 libboost-filesystem1.74.0 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/bambu /opt/bambu
# Fail the build if the plug-in needs a library this image lacks.
RUN ! ldd /opt/bambu/libbambu_networking.so /opt/bambu/libBambuSource.so /opt/bambu/pjarczak_bambu_linux_host | grep 'not found'
# The Linux host opens the plug-in by bare name unless these give its path. The plug-in's HTTPS needs a CA bundle
# (Orca sets the same three variables before loading it); without one every REST call fails with curl error 60.
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/etc/ssl/certs \
    PJARCZAK_BAMBU_PLUGIN_DIR=/opt/bambu \
    PJARCZAK_BAMBU_NETWORK_SO=/opt/bambu/libbambu_networking.so \
    PJARCZAK_BAMBU_SOURCE_SO=/opt/bambu/libBambuSource.so \
    PJARCZAK_EXPECTED_BAMBU_NETWORK_VERSION=02.08.02.54
WORKDIR /opt/bambu
ENTRYPOINT ["/opt/bambu/pjarczak_bambu_linux_host"]

# Apple silicon (the default target): the plug-in crashes in its own initializer (SIGBUS) under Docker Desktop's
# Rosetta, but runs under QEMU. A native arm64 image carries the x86 filesystem and runs the host through
# qemu-x86_64, so Docker's emulation settings stay untouched. On x86-64 hosts build with --target x86.
FROM debian:bookworm-slim AS qemu
RUN apt-get update && apt-get install -y --no-install-recommends qemu-user-static && rm -rf /var/lib/apt/lists/*
COPY --from=x86 / /x86
ENV SSL_CERT_FILE=/x86/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/x86/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_DIR=/x86/etc/ssl/certs \
    PJARCZAK_BAMBU_PLUGIN_DIR=/x86/opt/bambu \
    PJARCZAK_BAMBU_NETWORK_SO=/x86/opt/bambu/libbambu_networking.so \
    PJARCZAK_BAMBU_SOURCE_SO=/x86/opt/bambu/libBambuSource.so \
    PJARCZAK_EXPECTED_BAMBU_NETWORK_VERSION=02.08.02.54
WORKDIR /x86/opt/bambu
ENTRYPOINT ["qemu-x86_64-static", "-L", "/x86", "/x86/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2", \
            "--library-path", "/x86/usr/lib/x86_64-linux-gnu:/x86/opt/bambu", "/x86/opt/bambu/pjarczak_bambu_linux_host"]
