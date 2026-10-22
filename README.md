# Simple Attendance by Seat Id

Lab 1 project — a single servlet + one HTML page, packaged as a war and run by Tomcat 9 in Docker,
deployed on Render.

**Live:** https://attend95555.onrender.com/

```
src/java/attendance/Attend.java   the servlet (@WebServlet("/Attend"))
web/index.html                    the submission form
web/WEB-INF/web.xml               deployment descriptor (no metadata-complete, so @WebServlet scans)
Dockerfile                        builds the war inside the image, publishes / and /attendance
entrypoint.sh                     patches Tomcat's server.xml to Render's $PORT
render.yaml                       Render Blueprint (service name attend95555)
Attend-sorted.java.txt            optional Q3 variant: Attendee List sorted by Student Id
```

## Why the Dockerfile differs from the lab document

`RenderLab.docx` copies the war as `attendance.war`, which mounts the app at `/attendance/`, and deletes
Tomcat's `ROOT` — so `https://attend95555.onrender.com/`, the URL the assignment asks you to submit,
would return 404. This Dockerfile publishes the same webapp under both `/` and `/attendance/`.

Two contexts are two independent Tomcat applications, so each has its **own** in-memory `sid2seat` map:
a record made at `/` is not visible at `/attendance/`. Grade against a single URL (`/`).

Second difference: the war is compiled and packed **inside the image** (`javac` + `jar` from the
`tomcat:9.0-jdk11-corretto` JDK image), so no local JDK / NetBeans / Ant / `jar` is required.

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
