#!/bin/sh
# Tomcat entrypoint that survives a READ-ONLY container filesystem.
#
# Tomcat always writes somewhere (logs, work, temp, the exploded war), so this
# script copies the config into /tmp and runs Tomcat with CATALINA_BASE=/tmp/tomcat.
# Nothing outside /tmp is written, which is what Deplexo's free tier requires.
set -eu

PORT="${PORT:-8080}"
BASE="/tmp/tomcat"

rm -rf "$BASE"
mkdir -p "$BASE/logs" "$BASE/temp" "$BASE/work" "$BASE/webapps"
cp -R "$CATALINA_HOME/conf" "$BASE/conf"

# Publish the same webapp at "/" (the URL the lab asks you to submit) and at
# "/attendance" (the context path the lab document uses).
cp "$CATALINA_HOME/webapps/ROOT.war" "$BASE/webapps/ROOT.war"
cp "$CATALINA_HOME/webapps/ROOT.war" "$BASE/webapps/attendance.war"

# Listen on the port the platform hands us and keep the thread pool small:
# this container may only have 128 MB of RAM.
sed -i "s/port=\"8080\"/port=\"$PORT\"/" "$BASE/conf/server.xml"
sed -i 's/maxThreads="200"/maxThreads="20"/' "$BASE/conf/server.xml"

export CATALINA_BASE="$BASE"
export CATALINA_OPTS="${CATALINA_OPTS:-} -Djava.io.tmpdir=$BASE/temp"

exec "$CATALINA_HOME/bin/catalina.sh" run
