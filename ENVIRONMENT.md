# Environment Variables

The backend now supports environment-variable based configuration for sensitive settings.

Supported variables:
- `SPRING_PROFILES_ACTIVE`
- `DB_URL`
- `DB_USERNAME`
- `DB_PASSWORD`
- `JPA_DDL_AUTO`
- `JPA_SHOW_SQL`
- `LOG_LEVEL_APP`
- `LOG_LEVEL_SECURITY`
- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_PASSWORD`
- `REDIS_DATABASE`
- `REDIS_TIMEOUT`
- `OSS_ENDPOINT`
- `OSS_ACCESS_KEY_ID`
- `OSS_ACCESS_KEY_SECRET`
- `OSS_BUCKET_NAME`
- `OSS_DOMAIN`
- `OSS_PREFIX`

Example PowerShell session:

```powershell
$env:SPRING_PROFILES_ACTIVE="prod"
$env:DB_URL="jdbc:mysql://localhost:3306/hailiao?useUnicode=true&characterEncoding=utf-8&useSSL=false&serverTimezone=Asia/Shanghai"
$env:DB_USERNAME="root"
$env:DB_PASSWORD="your-password"
$env:JPA_DDL_AUTO="update"
$env:JPA_SHOW_SQL="true"
$env:LOG_LEVEL_APP="INFO"
$env:LOG_LEVEL_SECURITY="WARN"
$env:REDIS_HOST="localhost"
$env:REDIS_PORT="6379"
$env:OSS_ACCESS_KEY_ID="your-access-key-id"
$env:OSS_ACCESS_KEY_SECRET="your-access-key-secret"
```

Notes:
- `hailiao-api` and `hailiao-admin` share the same database and Redis variables.
- `hailiao-api` and `hailiao-admin` also share the JPA and logging variables above.
- If an environment variable is not provided, Spring falls back to the default value in `application.yml`.
- For production, avoid relying on the fallback defaults for passwords and access keys.
- For production, prefer running with the `prod` Spring profile so `ddl-auto` and SQL logging use safer defaults.
