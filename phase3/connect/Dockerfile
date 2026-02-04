# ---- Build Iceberg Kafka Connect runtime (creates the connector plugin dir) ----
FROM gradle:8.7-jdk17 AS iceberg_build

ARG ICEBERG_TAG=apache-iceberg-1.10.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 --branch ${ICEBERG_TAG} https://github.com/apache/iceberg.git

WORKDIR /build/iceberg

# Kafka Connect runtime dist task 
RUN ./gradlew :iceberg-kafka-connect:iceberg-kafka-connect-runtime:distZip --no-daemon

# Unzip the generated runtime ZIP no matter which module produced it
RUN mkdir -p /out && \
    ZIPFILE=$(find . -path "*/build/distributions/*.zip" | head -n 1) && \
    echo "Using ZIP: $ZIPFILE" && \
    unzip -q "$ZIPFILE" -d /out && \
    mv /out/iceberg-kafka-connect-runtime* /out/iceberg-kafka-connect 2>/dev/null || \
    mv /out/iceberg-kafka-connect* /out/iceberg-kafka-connect


# ---- Final image: Confluent Connect + Iceberg plugin installed ----
FROM confluentinc/cp-kafka-connect:7.6.0

USER root

# Put the Iceberg connector plugin directory in the standard plugin area
COPY --from=iceberg_build /out/iceberg-kafka-connect /usr/share/java/iceberg-kafka-connect

# Make sure the non-root Connect user can read everything
RUN chown -R appuser:appuser /usr/share/java/iceberg-kafka-connect

USER appuser
