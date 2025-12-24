---
description: Customize Backstage entity pages by adding tabs, cards, and conditional content
argument-hint: <kind> [--add-tab=<name>] [--add-card=<name>]
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Entity Page Customizer

Add tabs, cards, and customize entity pages for specific kinds.

## Arguments

$ARGUMENTS

**Kinds:**
- `component` - Service, library, website pages
- `api` - API definition pages
- `system` - System overview pages
- `domain` - Domain pages
- `resource` - Resource pages
- `group` - Team pages
- `user` - User profile pages

## Target File

`packages/app/src/components/catalog/EntityPage.tsx`

## Process

### 1. Read Current EntityPage
Understand existing structure and patterns.

### 2. Identify Target Page
Based on kind argument, find the relevant page definition:
- `serviceEntityPage` / `websiteEntityPage` / `defaultEntityPage`
- `apiPage`
- `systemPage`
- `domainPage`
- `resourcePage`
- `groupPage`
- `userPage`

### 3. Add Component
Based on flags, add tab or card.

### 4. Update Imports
Add necessary imports for new components.

## Adding a Tab

### Basic Tab
```tsx
import { MyPluginContent } from '@internal/plugin-my-plugin';

// In entity page definition
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

### Tab with Entity Condition
```tsx
<EntityLayout.Route
  path="/kubernetes"
  title="Kubernetes"
  if={isKubernetesAvailable}
>
  <EntityKubernetesContent />
</EntityLayout.Route>
```

## Adding a Card

### Grid Card
```tsx
import { MyCard } from '@internal/plugin-my-plugin';

// In overview content Grid
<Grid item md={6}>
  <MyCard variant="gridItem" />
</Grid>
```

### Full Width Card
```tsx
<Grid item md={12}>
  <MyCard variant="gridItem" />
</Grid>
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

## Common Patterns

### Component Page Structure
```tsx
const serviceEntityPage = (
  <EntityLayout>
    {/* Overview Tab */}
    <EntityLayout.Route path="/" title="Overview">
      <Grid container spacing={3} alignItems="stretch">
        <Grid item md={6}>
          <EntityAboutCard variant="gridItem" />
        </Grid>
        <Grid item md={6}>
          <EntityLinksCard />
        </Grid>
        {/* Add more cards here */}
      </Grid>
    </EntityLayout.Route>

    {/* CI/CD Tab */}
    <EntityLayout.Route path="/ci-cd" title="CI/CD">
      <EntityCiCdContent />
    </EntityLayout.Route>

    {/* API Tab */}
    <EntityLayout.Route path="/api" title="API">
      <Grid container spacing={3}>
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
      <Grid container spacing={3}>
        <Grid item md={6}>
          <EntityDependsOnComponentsCard variant="gridItem" />
        </Grid>
        <Grid item md={6}>
          <EntityDependsOnResourcesCard variant="gridItem" />
        </Grid>
      </Grid>
    </EntityLayout.Route>

    {/* Docs Tab */}
    <EntityLayout.Route path="/docs" title="Docs">
      <EntityTechdocsContent />
    </EntityLayout.Route>
  </EntityLayout>
);
```

### Kind Router
```tsx
export const entityPage = (
  <EntitySwitch>
    <EntitySwitch.Case if={isKind('component')} children={componentPage} />
    <EntitySwitch.Case if={isKind('api')} children={apiPage} />
    <EntitySwitch.Case if={isKind('group')} children={groupPage} />
    <EntitySwitch.Case if={isKind('user')} children={userPage} />
    <EntitySwitch.Case if={isKind('system')} children={systemPage} />
    <EntitySwitch.Case if={isKind('domain')} children={domainPage} />
    <EntitySwitch.Case if={isKind('resource')} children={resourcePage} />
    <EntitySwitch.Case>{defaultEntityPage}</EntitySwitch.Case>
  </EntitySwitch>
);
```

### Component Type Routing
```tsx
const componentPage = (
  <EntitySwitch>
    <EntitySwitch.Case if={isComponentType('service')}>
      {serviceEntityPage}
    </EntitySwitch.Case>
    <EntitySwitch.Case if={isComponentType('website')}>
      {websiteEntityPage}
    </EntitySwitch.Case>
    <EntitySwitch.Case>{defaultEntityPage}</EntitySwitch.Case>
  </EntitySwitch>
);
```

## Built-in Cards

### About & Links
- `EntityAboutCard` - Entity metadata
- `EntityLinksCard` - External links
- `EntityLabelsCard` - Labels display

### Relationships
- `EntityDependsOnComponentsCard` - Dependencies
- `EntityDependsOnResourcesCard` - Resource dependencies
- `EntityDependencyOfComponentsCard` - Dependents
- `EntityHasComponentsCard` - System components
- `EntityHasApisCard` - System APIs
- `EntityProvidedApisCard` - Provided APIs
- `EntityConsumedApisCard` - Consumed APIs

### Members
- `EntityMembersCard` - Group members
- `EntityOwnershipCard` - Ownership info
- `EntityUserProfileCard` - User profile

### Documentation
- `EntityTechdocsContent` - TechDocs viewer

## Available Condition Helpers

```tsx
import {
  isKind,
  isComponentType,
  isNamespace,
  isOrphan,
  hasAnnotation,
  hasLabel,
  isKubernetesAvailable,
  isTechDocsAvailable,
} from '@backstage/plugin-catalog';
```

## Output

After customization:
1. Modified file with diff
2. Required imports added
3. Component placement in layout
4. Restart instruction: `yarn start`
