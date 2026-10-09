# spec-kit (vendored)

GitHub Spec Kit's Claude integration, vendored instead of installed via the
`specify` CLI. Version in `VERSION`.

## Layout

| Path | Role |
|---|---|
| `../skills/speckit-*/SKILL.md` | The 10 upstream skills — global, available in every project |
| `../skills/speckit-init/SKILL.md` | Local addition: bootstraps a project |
| `seed/` | The `.specify/` payload (scripts, templates, workflows) |
| `bootstrap.sh` | Copies `seed/` to `<project>/.specify` |

## Why the split

The skills are global, but their bodies call `.specify/scripts/bash/*.sh` and
read `.specify/templates/`. Both resolve against the project root that
`seed/scripts/bash/common.sh` finds by walking up for a `.specify/` directory —
no env var redirects them elsewhere. So the prompts can be global; the runtime
cannot.

## Use

```bash
/speckit-init            # once per project
/speckit-constitution    # then the normal flow
/speckit-specify
/speckit-plan
/speckit-tasks
/speckit-implement
```

## Upgrading

No CLI is installed, so there is no `specify self upgrade`. Regenerate:

```bash
git clone --depth 1 --branch <tag> https://github.com/github/spec-kit.git
python3 -m venv .venv && ./.venv/bin/pip install -e ./spec-kit
mkdir ref && cd ref && git init .
../.venv/bin/specify init --here --force --integration claude --script sh --ignore-agent-tools
# then: ref/.claude/skills/. -> config/claude/skills/
#       ref/.specify/.       -> config/claude/speckit/seed/
```

Keep `skills/speckit-init/` — it is not upstream. Update `VERSION`.
