# Mini Fixture Plan

**Goal:** Exercise the SDD workflow end to end against a throwaway repository.

## Global Constraints

- The greeting string is exactly `hello sdd`.
- Every function lives in `src/greet.js`.

---

### Task 1: Greeting function

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

---

### Task 2: Shout function

**Files:**
- Modify: `src/greet.js`
- Test: `test/shout.test.js`

**Interfaces:**
- Consumes: `greet(): string` from Task 1.
- Produces: `shout(): string`.

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict')
const { shout } = require('../src/greet.js')
assert.equal(shout(), 'HELLO SDD')
console.log('ok')
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node test/shout.test.js`
Expected: FAIL, `shout is not a function`

- [ ] **Step 3: Implement**

```js
function shout() {
  return greet().toUpperCase()
}
module.exports = { greet, shout }
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node test/shout.test.js`
Expected: PASS, prints `ok`

- [ ] **Step 5: Commit**

```bash
git add src/greet.js test/shout.test.js
git commit -m "feat: add shout"
```
