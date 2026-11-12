# Updating the running App Suite Seeder web service

This service is **not** published to a container registry. You update it by
building the image on your Mac, saving it to a `.tar.gz`, copying that file to
the server with `scp`, loading it into Docker there, and replacing the running
container.

Fixed facts about this service (used throughout below):

| Thing | Value |
|---|---|
| Image name & tag | `appsuite-seeder:latest` |
| Container name | `seeder` |
| Port | `8080` on the host → `8080` in the container |
| Restart policy | `unless-stopped` |
| Tarball on your Mac | `Binaries/Docker Images/appsuite-seeder.tar.gz` |

Replace `USER@HOST` with your SSH login (e.g. `root@seeder.example.com`) in
every command.

---

## Step 1 — Build the image (on your Mac)

From the repo root:

```bash
cd webservice
./build-image.sh
```

This builds `appsuite-seeder:latest` for `linux/amd64` and writes the tarball to
`Binaries/Docker Images/appsuite-seeder.tar.gz`.

> Skip this step if you just built the image and the tarball is already
> up to date.

---

## Step 2 + 3 — Copy and load in one command (recommended)

You can skip the intermediate file entirely by piping the image over SSH
straight into `docker load` on the server. `gunzip` decompresses locally, the
stream travels over SSH's stdin, and `docker load` reads it on the far side —
nothing is written to disk on the server, so there's nothing to clean up later.

The local path has a space in it, so keep the quotes:

```bash
cd ..   # back to the repo root
gunzip -c "Binaries/Docker Images/appsuite-seeder.tar.gz" | ssh USER@HOST 'docker load'
```

This is the line `build-image.sh` prints at the end of a build. You should see
`Loaded image: appsuite-seeder:latest`. This replaces the
`appsuite-seeder:latest` image with the new build (the old running container
keeps using the old image until you recreate it in Step 4).

Then continue at **Step 4**.

> **Prefer to stage the file first?** Use the two-step variant instead:
>
> ```bash
> # on your Mac (repo root):
> scp "Binaries/Docker Images/appsuite-seeder.tar.gz" USER@HOST:~/appsuite-seeder.tar.gz
> # then on the server:
> ssh USER@HOST
> gunzip -c ~/appsuite-seeder.tar.gz | docker load
> ```
>
> This leaves `~/appsuite-seeder.tar.gz` on the server (remove it in Step 6).
> Handy if the connection is flaky and you want the upload to complete before
> loading, or you want to keep the tarball around as a rollback artifact.

---

## Step 4 — Replace the running container

Still on the server. Stop and remove the old container, then start a fresh one
from the new image:

```bash
docker stop seeder
docker rm seeder
docker run -d \
  --restart unless-stopped \
  -p 8080:8080 \
  --name seeder \
  appsuite-seeder:latest
```

> If `docker stop`/`docker rm` complain that there is **no such container**, the
> previous deploy used a different name. Find it with `docker ps -a` and use that
> name, or just skip straight to the `docker run` command.

---

## Step 5 — Verify

```bash
docker ps                 # 'seeder' should be listed as Up, on 0.0.0.0:8080->8080/tcp
docker logs seeder        # should show the server starting on port 8080
curl -s localhost:8080/api/config   # should return JSON like {"accounts":[...],"demoAvailable":true}
```

Then open the UI in a browser: `http://HOST:8080/`.

---

## Step 6 — Clean up (optional)

Remove any dangling old image layers on the server:

```bash
docker image prune -f
```

If you used the two-step `scp` variant, also delete the uploaded tarball (the
piped one-command form leaves nothing to remove):

```bash
rm ~/appsuite-seeder.tar.gz
```

---

## One-shot version (copy/paste)

Once you trust the flow, the whole update is these two commands.

Build and load in one go (from the repo root):

```bash
cd webservice && ./build-image.sh && cd ..
gunzip -c "Binaries/Docker Images/appsuite-seeder.tar.gz" | ssh USER@HOST 'docker load'
```

Then swap the container (from `ssh USER@HOST`):

```bash
docker stop seeder; docker rm seeder; \
docker run -d --restart unless-stopped -p 8080:8080 --name seeder appsuite-seeder:latest; \
docker ps
```

---

## Notes

- **No registry involved.** The `docker load` step is what stands in for a
  `docker pull` — the image travels as a file, not through a registry.
- **`:latest` is reused every build.** Because the tag never changes, Step 4's
  stop/rm/run is what actually swaps the running code — loading the image alone
  does nothing to the live container.
- **Credentials are never stored** by the service, but it will happily push data
  to any App Suite server entered in the UI. Keep it behind a VPN, firewall, or
  reverse-proxy auth — don't expose port 8080 openly on the internet.
- **`compose.yaml` is for local dev**, where it builds from source
  (`docker compose up --build`). It is not used in this registry-less server
  update flow.
