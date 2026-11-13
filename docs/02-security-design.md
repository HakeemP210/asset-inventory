# 2. Security Design

[← Back to README](../README.md)

## Approach

Security was built into the layout from the start instead of added at the end. The guiding rule was least privilege: every component gets only the access it needs, and nothing is reachable unless it has to be.

## Network Access

- **Chained security groups.** The load balancer only accepts my home IP, the app server only accepts the load balancer, and the database only accepts the app server.
- **Private database.** RDS sits in private subnets with no internet route and public access turned off.
- **Admin console not exposed.** WildFly's management port (9990) stays bound to localhost and isn't open in any security group.

## Server Access

- **No SSH.** Port 22 is closed and the instance has no key pair. I get a shell through AWS Systems Manager Session Manager, which requires IAM permission. Every session start is recorded in CloudTrail.

## Secrets

- **No passwords in code, in Git, or on disk.** RDS manages the database password in Secrets Manager.
- At boot, a script fetches the password into `/run`, which lives in memory only. WildFly reads it from an environment variable (`${env.DB_PASSWORD}`), so it never appears in WildFly's config file.
- **Encrypted database connection.** The datasource requires SSL (`sslmode=require`).

## IAM (Identity and Access Management)

The EC2 instance role can only do three things:

| Permission | Why |
|---|---|
| Systems Manager core | Allows Session Manager access instead of SSH |
| `secretsmanager:GetSecretValue` on one secret | Reads the database password, and only that secret |
| `s3:GetObject` / `s3:PutObject` on one bucket | Backs up and restores app builds |

## Supply Chain

- **Verified downloads.** WildFly, the PostgreSQL JDBC driver, and every app build are checked against a SHA-256 checksum before they're used. A mismatch stops the install or deployment.
- **Zero AWS credentials in GitHub.** The pipeline never connects to AWS. The server pulls builds instead (see [CI/CD Pipeline](03-cicd-pipeline.md)).

## Application

- **Mass-assignment protection.** The API ignores any ID a client sends when creating an asset, so a request can't overwrite an existing record. This is covered by a unit test.
- **XSS (cross-site scripting) protection.** The web page displays data with `textContent` instead of `innerHTML`, so anything typed into a field is treated as text and never runs as code.

## Known Gaps

HTTPS, app login, a dedicated lower-privilege database user, and automatic handling of password rotation are listed in the README's [Known Limitations](../README.md#known-limitations). They're planned for the Kubernetes version.
