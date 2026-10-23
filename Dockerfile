# ---------------------------------------------------------------------------
# Simple Attendance by Seat Id — Java servlet, Tomcat 9, built for tiny
# free tiers (Deplexo free plan: 128 MB RAM / 250 MB disk, read-only rootfs).
#
# Flow:  src/java + web  ->  javac + jar (same artefacts NetBeans/Ant produce)
#        ->  ROOT.war  ->  Tomcat 9  ->  published at "/" and "/attendance".
#
# Stage 1 uses the JDK because it compiles the servlet; the final image only
# carries a JRE + Tomcat, which keeps it around 90 MB.
# ---------------------------------------------------------------------------

FROM eclipse-temurin:11-jdk-alpine AS build

ARG TOMCAT_VERSION=9.0.123

RUN apk add --no-cache curl tar \
 && mkdir -p /opt/tomcat \
 && curl -fsSL "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
      | tar -xz --strip-components=1 -C /opt/tomcat \
 && rm -rf /opt/tomcat/webapps/* /opt/tomcat/logs/*

COPY src/ /src/
COPY web/ /web/

RUN mkdir -p /war/WEB-INF/classes \
 && javac -encoding UTF-8 \
          -cp /opt/tomcat/lib/servlet-api.jar \
          -d /war/WEB-INF/classes \
          $(find /src -name '*.java') \
 && cp -R /web/. /war/ \
 && cd /war && jar cf /ROOT.war .

FROM eclipse-temurin:11-jre-alpine

ENV CATALINA_HOME=/opt/tomcat \
    CATALINA_OPTS="-Xms16m -Xmx48m -XX:MaxMetaspaceSize=48m -XX:ReservedCodeCacheSize=16m -Xss512k -XX:+UseSerialGC -Djava.awt.headless=true -Dfile.encoding=UTF-8"

COPY --from=build /opt/tomcat /opt/tomcat
COPY --from=build /ROOT.war /opt/tomcat/webapps/ROOT.war
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
CMD ["/entrypoint.sh"]
