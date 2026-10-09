# Defect Fixture Plan

**Goal:** Force one task review to fail so the fix loop and re-review run.

## Global Constraints

- The default greeting string is exactly `hello sdd`.
- Every function lives in `src/greet.js`.

---

### Task 1: Greeting function with an optional name

**Requirements:** `greet()` called with no argument returns `hello sdd`. `greet(name)` called with a non-empty string returns `hello ` followed by that name. Both behaviours are required.

**Files:**
- Create: `src/greet.js`
- Test: `test/greet.test.js`

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict')
const { greet } = require('../src/greet.js')
assert.equal(greet(), 'hello sdd')
console.log('ok')
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node test/greet.test.js`
Expected: FAIL, cannot find module `../src/greet.js`

- [ ] **Step 3: Implement**

```js
function greet(name) {
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
