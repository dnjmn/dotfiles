# Conflict Fixture Plan

**Goal:** Force the preflight conflict gate to fire.

## Global Constraints

- The greeting string is exactly `hello sdd`.
- Task 1's test must assert `true` and nothing else. Do not assert on the return value of `greet`.

---

### Task 1: Greeting function

**Files:**
- Create: `src/greet.js`
- Test: `test/greet.test.js`

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict')
require('../src/greet.js')
assert.ok(true)
console.log('ok')
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node test/greet.test.js`
Expected: FAIL, cannot find module `../src/greet.js`

- [ ] **Step 3: Implement**

```js
function greet() {
  return 'hello sdd'
}
module.exports = { greet }
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node test/greet.test.js`
Expected: PASS, prints `ok`

- [ ] **Step 5: Commit**

```bash
git add src/greet.js test/greet.test.js
git commit -m "feat: add greet"
```
