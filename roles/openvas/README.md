## Post-Scan Checks

After each Greenbone/OpenVAS vulnerability scan, perform the following checks on `vulnscan1` to ensure that disk usage, logs, and Docker resources remain healthy.

### 1. Check filesystem usage

```bash
df -h /
```

The root filesystem should normally remain well below the Checkmk warning threshold.

Current Checkmk thresholds:

* WARN: 80%
* CRIT: 90%

If disk usage increases unexpectedly, identify the largest directories:

```bash
du -xhd1 /var/lib 2>/dev/null | sort -h
```

### 2. Check OpenVAS log size

```bash
ls -lh \
/var/lib/docker/volumes/greenbone-community-edition_openvas_log_data_vol/_data/openvas.log
```

OpenVAS logging is configured at INFO level (`level=64`) instead of DEBUG (`level=128`) to prevent excessive log growth.

Verify that DEBUG messages are not being generated:

```bash
grep -m 20 'DEBUG:' \
/var/lib/docker/volumes/greenbone-community-edition_openvas_log_data_vol/_data/openvas.log
```

Normally, this command should return no output.

The log is managed by:

```text
/etc/logrotate.d/greenbone-openvas
```

Current rotation policy:

* Rotate daily
* Rotate earlier if the log reaches 200 MB
* Keep 7 rotations
* Compress old logs

### 3. Check Docker disk usage

```bash
docker system df
```

Pay particular attention to the `RECLAIMABLE` size under Docker images.

Greenbone feed updates regularly download new Docker images and older versions can accumulate over time.

Unused Docker images older than 7 days are automatically removed weekly by:

```text
/etc/cron.weekly/greenbone-docker-cleanup
```

The cleanup executes:

```bash
docker image prune -a -f --filter "until=168h"
```

Do not run `docker volume prune` or manually remove Greenbone volumes, because they contain persistent scanner data, vulnerability feeds, and scan results.

### 4. Verify scanner services

Check that the main Greenbone containers remain running and healthy:

```bash
docker ps
```

In particular, verify:

```text
greenbone-community-edition-gvmd-1
greenbone-community-edition-pg-gvm-1
greenbone-community-edition-ospd-openvas-1
greenbone-community-edition-openvasd-1
```

If required, inspect the OSPD OpenVAS log:

```bash
docker logs --tail 50 \
greenbone-community-edition-ospd-openvas-1
```

### 5. Quick post-scan health check

The following commands are usually sufficient after a normal scan:

```bash
df -h /

ls -lh \
/var/lib/docker/volumes/greenbone-community-edition_openvas_log_data_vol/_data/openvas.log

docker system df

docker ps --filter name=greenbone-community-edition
```

Manual cleanup should normally not be necessary because log rotation and Docker image cleanup are configured automatically.

### Important

The OpenVAS log level is customized in:

```text
/opt/greenbone/docker-compose.yml
```

The `configure-openvas` service must contain:

```bash
sed "s/127/64/" /etc/openvas/openvas_log.conf
```

After replacing or upgrading the Greenbone Docker Compose configuration, verify that this customization has not been overwritten:

```bash
grep -n 'openvas_log.conf' /opt/greenbone/docker-compose.yml
```

The expected configuration is:

```text
sed "s/127/64/" /etc/openvas/openvas_log.conf
```

Using `level=128` enables DEBUG logging and can cause several gigabytes of logs to be generated during large vulnerability scans.
