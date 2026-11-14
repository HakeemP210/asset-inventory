# ---------- Stage 1: build the WAR ----------
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw -B dependency:go-offline

COPY src/ src/
RUN ./mvnw -B package -DskipTests

# ---------- Stage 2: run it on WildFly ----------
FROM quay.io/wildfly/wildfly:42.0.0.Final-jdk21

ADD --chown=jboss:jboss \
    --checksum=sha256:73914527305a40cce504b0d3d90b23caf565136912d607ae8ae7c5895512332c \
    https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.14/postgresql-42.7.14.jar \
    /tmp/postgresql.jar

COPY --chown=jboss:jboss docker/configure-wildfly.cli /tmp/configure-wildfly.cli
RUN /opt/jboss/wildfly/bin/jboss-cli.sh --file=/tmp/configure-wildfly.cli \
 && rm -rf /opt/jboss/wildfly/standalone/configuration/standalone_xml_history/current \
           /tmp/postgresql.jar /tmp/configure-wildfly.cli

COPY --from=build --chown=jboss:jboss /app/target/asset-inventory.war /opt/jboss/wildfly/standalone/deployments/

EXPOSE 8080