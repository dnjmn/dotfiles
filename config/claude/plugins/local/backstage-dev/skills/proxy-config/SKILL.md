---
name: proxy-config
description: This skill provides patterns for configuring Backstage API proxies. Use when the user mentions "proxy", "API proxy", "external API", "backend-for-frontend", or asks about integrating external services.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# API Proxy Configuration

Expert patterns for Backstage proxy configuration and external API integration.

## Basic Proxy Setup

**app-config.yaml:**
```yaml
proxy:
  endpoints:
    '/my-api':
      target: https://api.example.com
      changeOrigin: true
```

**Frontend usage:**
```typescript
const { fetch } = useApi(fetchApiRef);
const response = await fetch('/api/proxy/my-api/endpoint');
const data = await response.json();
```

## Proxy Configuration Options

### Complete Example
```yaml
proxy:
  endpoints:
    '/external-service':
      target: https://api.external-service.com
      changeOrigin: true
      headers:
        Authorization: Bearer ${EXTERNAL_API_TOKEN}
        Accept: application/json
      pathRewrite:
        '^/api/proxy/external-service': ''
      allowedMethods:
        - GET
        - POST
      allowedHeaders:
        - Content-Type
        - X-Request-Id
```

### Options Reference

| Option | Description |
|--------|-------------|
| `target` | Base URL of the external API |
| `changeOrigin` | Modify origin header (usually `true`) |
| `headers` | Static headers to add to requests |
| `pathRewrite` | Rewrite path before forwarding |
| `allowedMethods` | Allowed HTTP methods (default: all) |
| `allowedHeaders` | Allowed request headers to forward |
| `credentials` | Credential handling mode |

## Common Integrations

### GitHub API
```yaml
proxy:
  endpoints:
    '/github-api':
      target: https://api.github.com
      changeOrigin: true
      headers:
        Accept: application/vnd.github.v3+json
        Authorization: token ${GITHUB_TOKEN}
```

### GitLab API
```yaml
proxy:
  endpoints:
    '/gitlab-api':
      target: https://gitlab.com/api/v4
      changeOrigin: true
      headers:
        PRIVATE-TOKEN: ${GITLAB_TOKEN}
```

### Jenkins
```yaml
proxy:
  endpoints:
    '/jenkins':
      target: http://jenkins.internal:8080
      changeOrigin: true
      headers:
        Authorization: Basic ${JENKINS_AUTH_BASE64}
```

### CircleCI
```yaml
proxy:
  endpoints:
    '/circleci':
      target: https://circleci.com/api/v1.1
      changeOrigin: true
      headers:
        Circle-Token: ${CIRCLECI_TOKEN}
```

### PagerDuty
```yaml
proxy:
  endpoints:
    '/pagerduty':
      target: https://api.pagerduty.com
      changeOrigin: true
      headers:
        Authorization: Token token=${PAGERDUTY_TOKEN}
```

### Datadog
```yaml
proxy:
  endpoints:
    '/datadog':
      target: https://api.datadoghq.com
      changeOrigin: true
      headers:
        DD-API-KEY: ${DATADOG_API_KEY}
        DD-APPLICATION-KEY: ${DATADOG_APP_KEY}
```

### Grafana
```yaml
proxy:
  endpoints:
    '/grafana':
      target: https://grafana.company.com
      changeOrigin: true
      headers:
        Authorization: Bearer ${GRAFANA_TOKEN}
```

### SonarQube
```yaml
proxy:
  endpoints:
    '/sonarqube':
      target: https://sonarqube.company.com/api
      changeOrigin: true
      headers:
        Authorization: Basic ${SONARQUBE_TOKEN_BASE64}
```

### Jira
```yaml
proxy:
  endpoints:
    '/jira':
      target: https://your-domain.atlassian.net/rest/api/3
      changeOrigin: true
      headers:
        Authorization: Basic ${JIRA_AUTH_BASE64}
```

### Prometheus
```yaml
proxy:
  endpoints:
    '/prometheus':
      target: http://prometheus.internal:9090/api/v1
      changeOrigin: true
```

## Frontend Usage Patterns

### Basic Fetch
```typescript
import { useApi, fetchApiRef } from '@backstage/core-plugin-api';

function MyComponent() {
  const fetchApi = useApi(fetchApiRef);

  const getData = async () => {
    const response = await fetchApi.fetch('/api/proxy/my-api/endpoint');
    if (!response.ok) {
      throw new Error(`Failed: ${response.statusText}`);
    }
    return response.json();
  };
}
```

### With useAsync Hook
```typescript
import { useApi, fetchApiRef } from '@backstage/core-plugin-api';
import useAsync from 'react-use/lib/useAsync';

function MyComponent() {
  const fetchApi = useApi(fetchApiRef);

  const { value, loading, error } = useAsync(async () => {
    const response = await fetchApi.fetch('/api/proxy/my-api/data');
    return response.json();
  }, []);

  if (loading) return <Progress />;
  if (error) return <Alert severity="error">{error.message}</Alert>;

  return <DataDisplay data={value} />;
}
```

### POST Request
```typescript
const createItem = async (item: Item) => {
  const response = await fetchApi.fetch('/api/proxy/my-api/items', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(item),
  });

  if (!response.ok) {
    throw new Error(`Failed to create item: ${response.statusText}`);
  }

  return response.json();
};
```

## Path Rewriting

### Remove Proxy Prefix
```yaml
proxy:
  endpoints:
    '/my-api':
      target: https://api.example.com
      pathRewrite:
        '^/api/proxy/my-api': ''
```

Request: `/api/proxy/my-api/users` → `https://api.example.com/users`

### Add Path Prefix
```yaml
proxy:
  endpoints:
    '/my-api':
      target: https://api.example.com
      pathRewrite:
        '^/api/proxy/my-api': '/v2/api'
```

Request: `/api/proxy/my-api/users` → `https://api.example.com/v2/api/users`

## Security Considerations

1. **Never expose sensitive tokens in frontend code**
   - Use proxy to add auth headers server-side

2. **Restrict allowed methods**
   ```yaml
   allowedMethods:
     - GET
     - POST
   ```

3. **Use environment variables for secrets**
   ```yaml
   headers:
     Authorization: Bearer ${API_TOKEN}
   ```

4. **Consider rate limiting**
   - External APIs may have rate limits
   - Implement caching where appropriate

5. **Audit proxy endpoints**
   - Review what APIs are exposed
   - Limit to necessary endpoints

## Debugging

### Check Proxy Configuration
```bash
# View resolved config
yarn backstage-cli config:print | grep -A 20 proxy
```

### Test Proxy Endpoint
```bash
# Direct test
curl http://localhost:7007/api/proxy/my-api/health

# With auth header (if needed)
curl -H "Authorization: Bearer <token>" \
  http://localhost:7007/api/proxy/my-api/health
```

### Common Issues

1. **CORS errors**: Ensure `changeOrigin: true`
2. **401 Unauthorized**: Check token in headers
3. **404 Not Found**: Verify pathRewrite rules
4. **502 Bad Gateway**: Check target URL accessibility
