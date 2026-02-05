---
name: catalog-info
description: This skill provides patterns for creating catalog-info.yaml entity definitions. Use when the user mentions "catalog-info.yaml", "entity", "Component", "API", "System", "Resource", "Domain", or asks about Backstage catalog entities.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Catalog Entity Definitions

Expert patterns for Backstage catalog-info.yaml files.

## Entity Structure

Every entity follows this envelope:
```yaml
apiVersion: backstage.io/v1alpha1
kind: <Kind>
metadata:
  name: <unique-name>
  description: <description>
  annotations: {}
  labels: {}
  tags: []
  links: []
spec:
  # Kind-specific fields
```

## Entity Kinds

### Component
Software component: service, website, library.

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: order-service
  description: Handles order processing and fulfillment
  annotations:
    github.com/project-slug: myorg/order-service
    backstage.io/techdocs-ref: dir:.
    backstage.io/kubernetes-id: order-service
    pagerduty.com/service-id: PXXXXXX
  labels:
    team: commerce
  tags:
    - golang
    - grpc
    - kubernetes
  links:
    - url: https://grafana.company.com/d/orders
      title: Grafana Dashboard
      icon: dashboard
    - url: https://runbook.company.com/order-service
      title: Runbook
      icon: docs
spec:
  type: service  # service, website, library
  lifecycle: production  # experimental, production, deprecated
  owner: group:commerce-team
  system: commerce-system
  subcomponentOf: commerce-platform
  dependsOn:
    - resource:default/orders-db
    - resource:default/redis-cache
    - component:default/inventory-service
  providesApis:
    - orders-api
  consumesApis:
    - inventory-api
    - payment-api
```

### API
API definitions (OpenAPI, gRPC, GraphQL, AsyncAPI).

```yaml
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: orders-api
  description: Order management REST API
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - rest
    - orders
spec:
  type: openapi  # openapi, asyncapi, graphql, grpc
  lifecycle: production
  owner: group:commerce-team
  system: commerce-system
  definition: |
    openapi: "3.0.0"
    info:
      title: Orders API
      version: "1.0.0"
    servers:
      - url: https://api.company.com/orders
    paths:
      /orders:
        get:
          summary: List orders
          responses:
            '200':
              description: List of orders
      /orders/{id}:
        get:
          summary: Get order by ID
          parameters:
            - name: id
              in: path
              required: true
              schema:
                type: string
          responses:
            '200':
              description: Order details
```

**For external definition files:**
```yaml
spec:
  type: openapi
  lifecycle: production
  owner: group:commerce-team
  definition:
    $text: ./api/openapi.yaml
```

### System
Collection of components and resources.

```yaml
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: commerce-system
  description: E-commerce platform handling orders, payments, and inventory
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - commerce
    - core
spec:
  owner: group:commerce-team
  domain: retail
```

### Domain
Business domain grouping systems.

```yaml
apiVersion: backstage.io/v1alpha1
kind: Domain
metadata:
  name: retail
  description: Retail and e-commerce business domain
spec:
  owner: group:retail-leadership
```

### Resource
Infrastructure resources (databases, queues, buckets).

```yaml
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: orders-db
  description: PostgreSQL database for order data
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - postgresql
    - database
spec:
  type: database  # database, s3-bucket, queue, cdn
  owner: group:platform-team
  system: commerce-system
  dependencyOf:
    - component:default/order-service
```

### Group
Teams and organizations.

```yaml
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: commerce-team
  description: Commerce engineering team
spec:
  type: team  # team, business-unit, product-area
  profile:
    displayName: Commerce Team
    email: commerce-team@company.com
    picture: https://company.com/teams/commerce.png
  parent: engineering
  children: []
  members:
    - user:jane.doe
    - user:john.smith
```

### User
Individual users.

```yaml
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: jane.doe
spec:
  profile:
    displayName: Jane Doe
    email: jane.doe@company.com
    picture: https://company.com/avatars/jane.png
  memberOf:
    - group:commerce-team
```

### Location
Reference to other entities.

```yaml
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: org-entities
  description: Organization structure entities
spec:
  type: url
  target: https://github.com/myorg/backstage-catalog/blob/main/org/all.yaml
  # Or multiple targets:
  # targets:
  #   - ./teams/*.yaml
  #   - ./users/*.yaml
```

## Common Annotations

| Annotation | Purpose |
|------------|---------|
| `github.com/project-slug` | GitHub repo (owner/repo) |
| `backstage.io/techdocs-ref` | TechDocs source location |
| `backstage.io/kubernetes-id` | Kubernetes workload identifier |
| `backstage.io/kubernetes-namespace` | Kubernetes namespace |
| `backstage.io/kubernetes-cluster` | Kubernetes cluster name |
| `jenkins.io/github-folder` | Jenkins folder path |
| `sonarqube.org/project-key` | SonarQube project key |
| `jira.com/project-key` | Jira project key |
| `pagerduty.com/service-id` | PagerDuty service ID |
| `backstage.io/source-location` | Source code location |

## Entity References

Format: `[<kind>:][<namespace>/]<name>`

```yaml
# Full reference
owner: group:default/commerce-team

# Implicit default namespace
owner: group:commerce-team

# Implicit Component kind (in dependsOn)
dependsOn:
  - inventory-service  # = component:default/inventory-service
```

## Best Practices

1. **Use consistent naming**: kebab-case for names
2. **Always set owner**: Every entity needs an owner
3. **Document with TechDocs**: Add techdocs-ref annotation
4. **Tag appropriately**: Use tags for discovery
5. **Define relationships**: Use dependsOn, providesApis, consumesApis
6. **Keep descriptions current**: Update as components evolve
