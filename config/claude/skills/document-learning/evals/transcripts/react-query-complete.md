# Simulated prior conversation — a completed /learn session on react-query

The following is the entire prior conversation between the user and Claude in a /learn session. Your job (as described in the user's next message) is to document this session.

---

**User:** /learn react-query

**Assistant:** [Launches research agents via Context7 + WebSearch]

Ran research. Before I lay out the roadmap, a quick scenario: If you needed to fetch user data on component mount and keep it fresh across tabs without refetching on every navigation, how would you approach it today?

**User:** Probably a useEffect with fetch, store the data in useState, maybe a context if multiple components need it. I'd add a manual refresh button. Don't really have a story for cross-tab.

**Assistant:** Good — tells me you have the React fundamentals but no cache primitive. Roadmap:

```
[ ] queries — fetching + caching keyed by query key (new)
[ ] staleTime vs cacheTime — when data is "fresh" vs retained (new)
[ ] query invalidation — telling the cache something is dirty (new)
[ ] mutations — server state changes + cache sync (new)
[ ] optimistic updates — UI assumes success, rolls back on error (new)
```

Ready?

**User:** yes

**Assistant:** **Concept 1: queries.** Why it exists: React has no built-in notion of "server state" — data owned by a server that the client caches. useState treats server data as if it were local state, which is why you end up with stale data, duplicate fetches, and no cross-component sharing. React Query introduces a *query cache* keyed by a tuple (the queryKey), so any component calling `useQuery(['user', id], fetchUser)` hits the same cache entry.

[Source: TanStack Query Docs — Queries](https://tanstack.com/query/latest/docs/framework/react/guides/queries)

```js
const { data, isLoading, error } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => fetch(`/api/users/${userId}`).then(r => r.json()),
})
```

Gotcha: the queryKey is a *structural* identity — `['user', 1]` and `['user', 1]` are the same entry regardless of which component called it.

In your own words: what problem does useQuery solve that useState + useEffect doesn't?

**User:** useState treats fetched data like it's local to the component, so two components fetching the same user would hit the network twice and could disagree about the current value. useQuery gives you a cache keyed by the query key so both components see the same entry and only one fetch happens. It's basically turning "server state" into a first-class thing instead of pretending it's local.

**Assistant:** Correct. One thing to watch: the queryFn must return a promise that either resolves with data or throws — don't return undefined on error, react-query treats that as success.

**Concept 2: staleTime vs cacheTime.** Why it exists: once you have a cache, you need two orthogonal policies — (a) how long is the data considered *fresh* (no refetch on mount/focus), and (b) how long do we keep it around after nothing is using it. staleTime answers (a), cacheTime (renamed gcTime in v5) answers (b).

[Source: TanStack Query Docs — Caching](https://tanstack.com/query/latest/docs/framework/react/guides/caching)

Defaults: staleTime=0 (always refetch on mount), gcTime=5min (evict 5min after unmount).

Gotcha: staleTime=0 surprises people — it means every mount triggers a background refetch even though the cached data shows instantly.

Analogy: staleTime is like HTTP `max-age` (the client treats the cached response as valid without revalidation). gcTime is more like memcached eviction — it governs when the entry is *removed*, not when it's considered stale. The two are independent.

In your own words: how would you explain staleTime vs gcTime to a teammate?

**User:** staleTime is like Redis TTL except client-side — I control for how long the cached data is trusted without revalidation. gcTime is how long the entry survives in memory with no subscribers. So you could have staleTime=1min, gcTime=10min — meaning after one minute any new mount triggers a background refetch, but the old data still displays instantly from cache, and if nobody uses it for 10 minutes it's garbage collected.

**Assistant:** Right. That's the mental model exactly.

**Concept 3: query invalidation.** Why it exists: after a mutation ("user updated their name"), the cache is now wrong. You need a way to mark entries as stale so they refetch next time they're observed. `queryClient.invalidateQueries({ queryKey: ['user'] })` marks every entry whose key starts with `['user']` as stale.

[Source: TanStack Query Docs — Query Invalidation](https://tanstack.com/query/latest/docs/framework/react/guides/query-invalidation)

Gotcha: invalidation is *prefix-based* — invalidating `['user']` also invalidates `['user', 1]`, `['user', 2]`, etc. This is a feature, not a bug, but it surprises people.

In your own words: why is invalidation a separate step from mutation?

**User:** Because the mutation only tells the server the truth changed — the cache doesn't automatically know. Invalidation is the bridge: after the mutation resolves, I tell the cache "these keys are now dirty" and next time anyone observes them they'll refetch. It's similar to the K8s reconciliation loop in that the cache converges toward server truth, but the trigger here is explicit invalidation rather than a watch.

**Assistant:** Correct. The K8s analogy is apt — both are about closing the gap between desired and actual state, just with different triggers.

**Concept 4: mutations.** Why it exists: queries are for reads; mutations are for writes. `useMutation` gives you a function you call to trigger the change, plus lifecycle callbacks (`onSuccess`, `onError`) where invalidation typically lives.

[Source: TanStack Query Docs — Mutations](https://tanstack.com/query/latest/docs/framework/react/guides/mutations)

```js
const mutation = useMutation({
  mutationFn: (newName) => fetch('/api/user', { method: 'PUT', body: JSON.stringify({ name: newName })}),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['user'] }),
})
```

In your own words: why aren't mutations just "a query you trigger manually"?

**User:** Because queries are idempotent by design — they represent "give me the current value" and the cache is keyed on the query key. Mutations are imperative side effects that don't have a meaningful "result to cache" — you care about the lifecycle (pending, success, error) and the cache consequences, not the return value itself. Separating them lets the library treat them with different defaults — mutations don't retry on failure by default because retrying a POST could double-charge a credit card.

**Assistant:** Correct, and that last point is the most important one. Mutations defaulting to no-retry is a safety guarantee.

**Concept 5: optimistic updates.** Why it exists: for snappy UX, you want the UI to reflect the change before the server confirms. But if the server rejects the change, you need to roll back. React Query provides `onMutate` (pre-mutation) and `onError` (rollback) hooks to implement this cleanly.

[Source: TanStack Query Docs — Optimistic Updates](https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates)

```js
useMutation({
  mutationFn: updateTodo,
  onMutate: async (newTodo) => {
    await queryClient.cancelQueries({ queryKey: ['todos'] })
    const previous = queryClient.getQueryData(['todos'])
    queryClient.setQueryData(['todos'], old => [...old, newTodo])
    return { previous }
  },
  onError: (err, newTodo, context) => {
    queryClient.setQueryData(['todos'], context.previous)
  },
})
```

Gotcha: you must `cancelQueries` first, otherwise an in-flight refetch can overwrite your optimistic update with stale server data.

In your own words: what's the rollback contract?

**User:** In onMutate I snapshot the current cache value and return it as context. I then mutate the cache optimistically. If the mutation fails, onError receives that context and I restore the snapshot. The cancelQueries step is to prevent a refetch that's already in flight from landing after my optimistic write and stomping on it.

**Assistant:** Correct. You're done with all five concepts.

[Launches graduation research agent]

## You're Ready

You've validated all 5 concepts for react-query.

### Session Handoff Prompt
Copy this into a new Claude Code session when you're ready to build:

---
I've completed a learning session on react-query. Here's my context:

**What I know:**
- `useQuery` turns server state into a first-class cached primitive keyed by queryKey — two components requesting the same key share one cache entry and one fetch
- staleTime is like Redis TTL but client-side — controls how long cached data is trusted without revalidation. gcTime is independent and governs in-memory retention after unsubscribe
- Invalidation is prefix-based and explicit — it's the bridge between a mutation resolving and the cache converging toward server truth, analogous to a K8s reconciliation trigger
- Mutations are separate from queries because they're imperative side effects, don't have a cacheable result, and default to no-retry so a POST can't double-charge
- Optimistic updates use onMutate to snapshot + write optimistically, cancelQueries to block in-flight refetches, onError to roll back from the snapshot

**My mental model:**
React Query is a client-side cache for server state, with explicit invalidation as the convergence mechanism. I think of it as HTTP cache semantics (max-age) plus a mutation layer that owns the dirty-marking.

**Gotchas I should remember:**
- staleTime=0 is the default and triggers background refetch on every mount
- Invalidation is prefix-based — `invalidateQueries(['user'])` hits all `['user', *]` entries
- Mutations don't retry on failure by default; do NOT change this for non-idempotent writes
- In onMutate, you must cancelQueries before writing optimistically or an in-flight refetch will stomp on it
- queryFn must throw on error, not return undefined

**I'm building:** [describe your task here]
---

### Further Reading
- queries: [TanStack Query Docs — Queries](https://tanstack.com/query/latest/docs/framework/react/guides/queries)
- caching: [TanStack Query Docs — Caching](https://tanstack.com/query/latest/docs/framework/react/guides/caching)
- invalidation: [TanStack Query Docs — Query Invalidation](https://tanstack.com/query/latest/docs/framework/react/guides/query-invalidation)
- mutations: [TanStack Query Docs — Mutations](https://tanstack.com/query/latest/docs/framework/react/guides/mutations)
- optimistic updates: [TanStack Query Docs — Optimistic Updates](https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates)

### Quick Reference Card

**Core APIs/Patterns:**
- `useQuery({ queryKey, queryFn })` — read
- `useMutation({ mutationFn, onSuccess, onMutate, onError })` — write
- `queryClient.invalidateQueries({ queryKey })` — mark dirty

**Analogy Bridge (what you already know → react-query):**
| You Know | React Query Equivalent |
|---|---|
| Redis TTL | staleTime |
| K8s reconciliation loop | invalidation → refetch |
| Go `context.Context` cancellation | cancelQueries in onMutate |
| HTTP max-age | staleTime |

**Concept Dependencies:**
queries → staleTime/gcTime → invalidation → mutations → optimistic updates
