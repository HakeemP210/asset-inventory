# 4. Troubleshooting Log

[← Back to README](../README.md)

Real problems hit during the build, how I found the cause, and how each one was fixed.

## Load Balancer Target Stayed Unhealthy

**Problem:** The load balancer kept marking the app server as unhealthy, even after waiting several extra minutes.

**Root cause:** The health check path was `/asset-inventory`. WildFly answers that with a 302 redirect to `/asset-inventory/`, and the load balancer only counts a 200 as healthy.

**Fix:** Changed the health check path to `/asset-inventory/` with the trailing slash. I didn't add 302 as an accepted success code, since that would also hide real failures.

## WildFly Failed to Start After a Reboot

**Problem:** After rebooting the server, WildFly didn't come back up.

**Root cause:** The script that fetches the database password runs right before WildFly starts. Right after boot, the instance's IAM credentials weren't ready yet, so the AWS CLI call failed and took WildFly down with it.

**Fix:**
- Added a retry loop to the script (12 tries, 5 seconds apart).
- Made the service wait for `network-online.target` before starting.

A second reboot test passed.

## Arm Instance Types Were Greyed Out

**Problem:** The `t4g` instance types couldn't be selected when launching the server.

**Root cause:** The selected AMI (Amazon Machine Image) was x86, and `t4g` instances run on Arm (Graviton) processors.

**Fix:** Switched to the 64-bit Arm version of Amazon Linux 2023.

## First Pipeline Run Failed

**Problem:** The first GitHub Actions run failed during the build step.

**Root cause:** A temporary error downloading Maven. I confirmed the download URL itself was valid.

**Fix:** Re-ran the failed job, and it passed. No code change was needed.

## Handoff to the New Deploy Process

**Problem:** After switching from manual deploys to the automated script, the first automated deploy failed.

**Root cause:** The old manual deploy had left marker files in WildFly's deployments folder, which conflicted with deploying through `jboss-cli`.

**Fix:** Removed the leftover `.deployed` and `.dodeploy` markers and cleared the failed-build record. The next run deployed successfully, and every deploy since has gone through the script.
