---
name: entity-page
description: This skill provides patterns for customizing Backstage EntityPage.tsx. Use when the user mentions "EntityPage", "entity page", "entity tabs", "entity cards", "catalog page", or asks about customizing entity views.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# EntityPage Customization

Expert patterns for customizing Backstage entity pages.

## Target File

`packages/app/src/components/catalog/EntityPage.tsx`

## Page Architecture

```tsx
// Entity page for a specific kind
const serviceEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/" title="Overview">
      {overviewContent}
    </EntityLayout.Route>
    <EntityLayout.Route path="/api" title="API">
      {apiContent}
    </EntityLayout.Route>
    {/* More tabs */}
  </EntityLayout>
);

// Router for all entity kinds
export const entityPage = (
  <EntitySwitch>
    <EntitySwitch.Case if={isKind('component')} children={componentPage} />
    <EntitySwitch.Case if={isKind('api')} children={apiPage} />
    {/* More cases */}
    <EntitySwitch.Case>{defaultEntityPage}</EntitySwitch.Case>
  </EntitySwitch>
);
```

## Adding Tabs

### Basic Tab
```tsx
import { MyPluginContent } from '@internal/plugin-my-plugin';

<EntityLayout.Route path="/my-plugin" title="My Plugin">
  <MyPluginContent />
</EntityLayout.Route>
```

### Conditional Tab
```tsx
import { isMyPluginAvailable, MyPluginContent } from '@internal/plugin-my-plugin';

<EntityLayout.Route
  path="/my-plugin"
  title="My Plugin"
  if={isMyPluginAvailable}
>
  <MyPluginContent />
</EntityLayout.Route>
```

### Tab with Custom Condition
```tsx
import { useEntity } from '@backstage/plugin-catalog-react';

const isGoService = (entity: Entity) =>
  entity.metadata.tags?.includes('golang') ?? false;

<EntityLayout.Route
  path="/golang"
  title="Go Tools"
  if={isGoService}
>
  <GoToolsContent />
</EntityLayout.Route>
```

## Adding Cards

### Overview Grid Card
```tsx
import { Grid } from '@material-ui/core';
import { MyCard } from '@internal/plugin-my-plugin';

const overviewContent = (
  <Grid container spacing={3} alignItems="stretch">
    <Grid item md={6}>
      <EntityAboutCard variant="gridItem" />
    </Grid>
    <Grid item md={6}>
      <MyCard variant="gridItem" />
    </Grid>
    <Grid item md={12}>
      <EntityLinksCard />
    </Grid>
  </Grid>
);
```

### Conditional Card
```tsx
<EntitySwitch>
  <EntitySwitch.Case if={isMyPluginAvailable}>
    <Grid item md={6}>
      <MyCard variant="gridItem" />
    </Grid>
  </EntitySwitch.Case>
</EntitySwitch>
```

## Built-in Components

### About & Metadata
```tsx
import {
  EntityAboutCard,
  EntityLinksCard,
  EntityLabelsCard,
} from '@backstage/plugin-catalog';

<EntityAboutCard variant="gridItem" />
<EntityLinksCard />
<EntityLabelsCard />
```

### Relationships
```tsx
import {
  EntityDependsOnComponentsCard,
  EntityDependsOnResourcesCard,
  EntityDependencyOfComponentsCard,
  EntityHasComponentsCard,
  EntityHasApisCard,
  EntityHasResourcesCard,
  EntityProvidedApisCard,
  EntityConsumedApisCard,
} from '@backstage/plugin-catalog';

// Component dependencies
<EntityDependsOnComponentsCard variant="gridItem" />
<EntityDependsOnResourcesCard variant="gridItem" />

// What depends on this
<EntityDependencyOfComponentsCard variant="gridItem" />

// System contents
<EntityHasComponentsCard variant="gridItem" />
<EntityHasApisCard variant="gridItem" />
<EntityHasResourcesCard variant="gridItem" />

// APIs
<EntityProvidedApisCard />
<EntityConsumedApisCard />
```

### TechDocs
```tsx
import { EntityTechdocsContent } from '@backstage/plugin-techdocs';

<EntityLayout.Route path="/docs" title="Docs">
  <EntityTechdocsContent />
</EntityLayout.Route>
```

### Kubernetes
```tsx
import {
  EntityKubernetesContent,
  isKubernetesAvailable,
} from '@backstage/plugin-kubernetes';

<EntityLayout.Route
  path="/kubernetes"
  title="Kubernetes"
  if={isKubernetesAvailable}
>
  <EntityKubernetesContent />
</EntityLayout.Route>
```

### CI/CD
```tsx
import { EntityGithubActionsContent } from '@backstage/plugin-github-actions';

<EntityLayout.Route path="/ci-cd" title="CI/CD">
  <EntityGithubActionsContent />
</EntityLayout.Route>
```

## Condition Helpers

```tsx
import {
  isKind,
  isComponentType,
  isNamespace,
  isOrphan,
  hasAnnotation,
  hasLabel,
} from '@backstage/plugin-catalog';

// Check entity kind
if={isKind('component')}
if={isKind('api')}

// Check component type
if={isComponentType('service')}
if={isComponentType('website')}

// Check namespace
if={isNamespace('production')}

// Check for orphan entities
if={isOrphan}

// Check for annotations
if={hasAnnotation('backstage.io/techdocs-ref')}

// Check for labels
if={hasLabel('team', 'platform')}
```

## Complete Service Page Example

```tsx
const serviceEntityPage = (
  <EntityLayout>
    {/* Overview Tab */}
    <EntityLayout.Route path="/" title="Overview">
      <Grid container spacing={3} alignItems="stretch">
        <Grid item md={6}>
          <EntityAboutCard variant="gridItem" />
        </Grid>
        <Grid item md={6} xs={12}>
          <EntityLinksCard />
        </Grid>

        {/* Conditional cards */}
        <EntitySwitch>
          <EntitySwitch.Case if={isPagerDutyAvailable}>
            <Grid item md={6}>
              <EntityPagerDutyCard />
            </Grid>
          </EntitySwitch.Case>
        </EntitySwitch>

        <Grid item md={6} xs={12}>
          <EntityHasSubcomponentsCard variant="gridItem" />
        </Grid>
      </Grid>
    </EntityLayout.Route>

    {/* CI/CD Tab */}
    <EntityLayout.Route path="/ci-cd" title="CI/CD">
      <EntityCiCdContent />
    </EntityLayout.Route>

    {/* API Tab */}
    <EntityLayout.Route path="/api" title="API" if={hasRelation('providesApi')}>
      <Grid container spacing={3} alignItems="stretch">
        <Grid item md={6}>
          <EntityProvidedApisCard />
        </Grid>
        <Grid item md={6}>
          <EntityConsumedApisCard />
        </Grid>
      </Grid>
    </EntityLayout.Route>

    {/* Dependencies Tab */}
    <EntityLayout.Route path="/dependencies" title="Dependencies">
      <Grid container spacing={3} alignItems="stretch">
        <Grid item md={6}>
          <EntityDependsOnComponentsCard variant="gridItem" />
        </Grid>
        <Grid item md={6}>
          <EntityDependsOnResourcesCard variant="gridItem" />
        </Grid>
      </Grid>
    </EntityLayout.Route>

    {/* Kubernetes Tab */}
    <EntityLayout.Route
      path="/kubernetes"
      title="Kubernetes"
      if={isKubernetesAvailable}
    >
      <EntityKubernetesContent />
    </EntityLayout.Route>

    {/* Docs Tab */}
    <EntityLayout.Route path="/docs" title="Docs" if={isTechDocsAvailable}>
      <EntityTechdocsContent />
    </EntityLayout.Route>
  </EntityLayout>
);
```

## Component Type Routing

```tsx
const componentPage = (
  <EntitySwitch>
    <EntitySwitch.Case if={isComponentType('service')}>
      {serviceEntityPage}
    </EntitySwitch.Case>
    <EntitySwitch.Case if={isComponentType('website')}>
      {websiteEntityPage}
    </EntitySwitch.Case>
    <EntitySwitch.Case if={isComponentType('library')}>
      {libraryEntityPage}
    </EntitySwitch.Case>
    <EntitySwitch.Case>
      {defaultEntityPage}
    </EntitySwitch.Case>
  </EntitySwitch>
);
```

## Best Practices

1. **Use Grid for layout**: Consistent responsive design
2. **Add `variant="gridItem"`**: Cards render correctly in grid
3. **Use conditionals**: Only show relevant content
4. **Group related cards**: Organize in meaningful tabs
5. **Consider mobile**: Use `xs={12}` for mobile breakpoints
