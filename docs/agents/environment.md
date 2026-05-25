# Environment & Tooling

Known quirks and setup facts for this machine. Read this before running install commands or editing pnpm config.

## Runtime

- Node 22.18.0, npm 11.5.2
- pnpm 11.3.0 — installed globally via `npm install -g pnpm` (was not pre-installed)
- If pnpm is missing in a fresh session: `npm install -g pnpm`

## Shell

Use the **PowerShell tool** for all pnpm/npm/node commands. The Bash tool does not have pnpm in its PATH on this machine.

## pnpm 11 gotchas

**`package.json` `pnpm` field is deprecated.** pnpm 11 ignores it with a warning. All pnpm settings must go in `pnpm-workspace.yaml`.

**esbuild build scripts must be explicitly approved.** pnpm 11 blocks build scripts by default and runs a dependency status check before every script. If either key is missing, `pnpm install` and all `pnpm run *` commands fail with `ERR_PNPM_IGNORED_BUILDS`. The working fix — both keys are required:

```yaml
# pnpm-workspace.yaml
onlyBuiltDependencies:
  - esbuild

allowBuilds:
  esbuild: true
```

## Active YAML linter

A linter auto-modifies `pnpm-workspace.yaml` on save, injecting:

```yaml
allowBuilds:
  esbuild: set this to true or false   ← placeholder, not valid
```

After any edit to `pnpm-workspace.yaml`, verify this placeholder wasn't reintroduced before running `pnpm install`.
