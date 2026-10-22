# Simple Attendance by Seat Id — Tomcat 9 + Java 11
#
# Difference from RenderLab.docx: the .war is assembled *inside the image* from
# web/ + src/, so no local JDK / NetBeans / Ant / jar is needed to deploy.
# The doc's variant (commit a prebuilt attendance.war) also works — see README.
FROM tomcat:9.0-jdk11-corretto

# Tomcat's own sample webapps are not needed
RUN rm -rf /usr/local/tomcat/webapps/ROOT \
           /usr/local/tomcat/webapps/docs \
           /usr/local/tomcat/webapps/examples \
           /usr/local/tomcat/webapps/host-manager \
           /usr/local/tomcat/webapps/manager

# Web assets + servlet source
COPY web/ /tmp/webapp/
COPY src/ /tmp/src/

# Compile the servlet, assemble the webapp, then publish it under TWO contexts:
#   /            -> ROOT.war        (this is the URL you submit to the lab)
#   /attendance  -> attendance.war  (the context path used in the lab document)
RUN mkdir -p /tmp/webapp/WEB-INF/classes \
 && javac -encoding UTF-8 \
          -cp "$CATALINA_HOME/lib/servlet-api.jar" \
          -d /tmp/webapp/WEB-INF/classes \
          $(find /tmp/src -name '*.java') \
 && cd /tmp/webapp \
 && jar cf "$CATALINA_HOME/webapps/ROOT.war" . \
 && cp "$CATALINA_HOME/webapps/ROOT.war" "$CATALINA_HOME/webapps/attendance.war"

# Render injects PORT; the entrypoint patches Tomcat's server.xml before startup
COPY entrypoint.sh /usr/local/tomcat/bin/entrypoint.sh
RUN chmod +x /usr/local/tomcat/bin/entrypoint.sh

EXPOSE 8080
CMD ["/usr/local/tomcat/bin/entrypoint.sh"]
