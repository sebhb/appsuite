# syntax=docker/dockerfile:1

# ---------- build stage ----------
# Builds the web service, which depends on the ../appsuite library package.
# The build context is the repository root so both packages are available.
FROM swift:6.2 AS build
WORKDIR /src
COPY appsuite ./appsuite
COPY webservice ./webservice
WORKDIR /src/webservice
RUN swift build -c release
RUN install -Dm755 "$(swift build -c release --show-bin-path)/AppsuiteWeb" /out/AppsuiteWeb

# ---------- runtime stage ----------
# Slim image with the Swift runtime; runs the binary plus the bundled UI and
# the subset of demo data actually used (no 97 MB comic avatars, no testmails).
FROM swift:6.2-slim
WORKDIR /app

COPY --from=build /out/AppsuiteWeb ./AppsuiteWeb
COPY webservice/Public ./Public

COPY Demo/GoldAccounts ./Demo/GoldAccounts
COPY Demo/testfiles ./Demo/testfiles
COPY Demo/tasks.json ./Demo/tasks.json
COPY Demo/contactTemplates.json ./Demo/contactTemplates.json
COPY Demo/appointmentTemplates.json ./Demo/appointmentTemplates.json
COPY ["Demo/Male Avatars", "./Demo/Male Avatars"]
COPY ["Demo/Female Avatars", "./Demo/Female Avatars"]

ENV APPSUITE_DEMO_DIR=/app/Demo
ENV PORT=8080
EXPOSE 8080

CMD ["./AppsuiteWeb"]
