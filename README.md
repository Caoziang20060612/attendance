# Simple Attendance by Seat Id

Lab 1 project — a single servlet + one HTML page, packaged as a war and run by Tomcat 9 in Docker.

```
src/java/attendance/Attend.java   the servlet (@WebServlet("/Attend"))
web/index.html                    the submission form
web/WEB-INF/web.xml               deployment descriptor (no metadata-complete, so @WebServlet scans)
Dockerfile                        multi-stage: javac builds the war, final image is JRE + Tomcat 9
entrypoint.sh                     runs Tomcat from /tmp (works on read-only container filesystems)
deplexo.yaml                      Deplexo config: dockerfile build, port 8080
render.yaml                       Render Blueprint (service name attend95555), kept for reference
Attend-sorted.java.txt            optional Q3 variant: Attendee List sorted by Student Id
```

## Build flow

`src/java + web` → `javac` + `jar` (the same artefacts NetBeans/Ant produce) → `ROOT.war` →
Tomcat 9 → published at **`/`** and **`/attendance/`**.

The build happens in the first Docker stage on `eclipse-temurin:11-jdk-alpine`, which also downloads
Tomcat 9.0.123 and uses its own `lib/servlet-api.jar` for `javac`. The final image is
`eclipse-temurin:11-jre-alpine` plus that Tomcat tree (~90 MB total), because the free hosting tiers
this runs on give only 128 MB RAM / 250 MB disk.

## Runtime tuning for 128 MB RAM

- `-Xmx48m -XX:MaxMetaspaceSize=48m -XX:ReservedCodeCacheSize=16m -XX:+UseSerialGC -Xss512k`
- Tomcat's connector `maxThreads` lowered from 200 to 20
- Tomcat's samples, docs, manager and host-manager are deleted from the image

## Read-only filesystem

Deplexo mounts the container root filesystem read-only, so `entrypoint.sh` copies `conf/` into
`/tmp/tomcat`, puts the war in `/tmp/tomcat/webapps`, and starts Tomcat with `CATALINA_BASE=/tmp/tomcat`.
Nothing outside `/tmp` is written.

## Why `/` and `/attendance/` both work

`RenderLab.docx` copies the war as `attendance.war`, which mounts the app at `/attendance/`, and deletes
Tomcat's `ROOT` — so the bare domain the assignment asks you to submit would return 404. This image
publishes the same webapp under both contexts.

Two contexts are two independent Tomcat applications, so each has its **own** in-memory `sid2seat` map:
a record made at `/` is not visible at `/attendance/`. Grade against a single URL (`/`).

## Run it locally (optional)

```bash
docker build -t attendance .
docker run -p 8080:8080 attendance
# http://localhost:8080/
```

## Behaviour

| Request | Response |
|---|---|
| `/` | the form (Student Id / Seat Id) |
| `/Attend` (no params) | Attendee List, dumped from the in-memory map |
| `/Attend?studentId=001&seatId=A1` | `001:A1 is recorded:` + links |
| `/Attend?studentId=&seatId=A1` | `Student Id can not be blank` + links |

The map is `static` and in memory: restarting the container clears all records (as the lab document notes).
