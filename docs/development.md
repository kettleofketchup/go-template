# Development

## Testing the Template

Run the end-to-end test to verify the template generates working projects:

```bash
just testing::test-template
```

This will:

1. Build the Copier Docker image
2. Generate a test project with hardcoded values
3. Run `just build` in the generated project
4. Run `just test` in the generated project
5. Run `just lint` in the generated project
6. Run `just docker::build` in the generated project
7. Execute `config show` and `config path` commands
8. Clean up on success, keep artifacts on failure

### Test Values

| Variable | Test Value |
|----------|------------|
| `project_name` | `testproject` |
| `tool_name` | `testtool` |
| `ci_platform` | `gitlab` |
| `gitlab_url` | `gitlab.example.com` |
| `gitlab_registry` | `gitlab.example.com:5050/testproject` |

### Debugging Failures

If the test fails, artifacts remain in `output/test/` for inspection:

```bash
cd output/test/testproject
just build  # Re-run the failing step
```

Clean up manually after debugging:

```bash
just testing::clean-test
```

## CI/CD Development

The `cicd` module contains platform-agnostic build commands:

```bash
# Run locally what CI runs
just cicd::lint
just cicd::test
just cicd::build
just cicd::pages
```

These recipes are called by both GitLab CI and GitHub Actions, ensuring consistent behavior across platforms.

## Pre-commit Hooks (Lefthook)

Generated projects include [Lefthook](https://github.com/evilmartians/lefthook) for pre-commit validation.

### Setup

Lefthook is automatically installed and configured when you run:

```bash
just dev
```

This installs `lefthook` via `go install` (if not already present) and runs `lefthook install` to set up git hooks.

### Configured Hooks

| Hook | Trigger | What It Checks |
|------|---------|----------------|
| `config-schema` | Files matching `src/*/config/*.go` | Runs `just config::check` to verify schema.json is current |

### Manual Checks

```bash
# Run the config schema check manually
just config::check

# Regenerate schema after changing config struct
just config::schema
```

## Template File Conventions

### Jinja Templates

Files that need variable substitution use the `.jinja` extension:

- `justfile.jinja` → `justfile`
- `go.mod.jinja` → `go.mod`
- `cicd.just.jinja` → `cicd.just`

### Conditional Files

Files that should only be created for certain CI platforms use Jinja conditionals in the filename:

- `{% if ci_platform == 'gitlab' %}.gitlab-ci.yml{% endif %}.jinja` → `.gitlab-ci.yml` (GitLab only)
- `{% if ci_platform == 'github' %}.github{% endif %}/workflows/ci.yml.jinja` → `.github/workflows/ci.yml` (GitHub only)

### Static Files

Files without `.jinja` are copied verbatim:

- `docs/includes/abbreviations.md`
- `.gitignore`
- `just/copier.just`
- `just/git.just`

### Directory Names

Directory names can include template variables:

- `template/{{ project_name }}/` → `myproject/`
- `src/{{ tool_name }}/` → `src/myctl/`

## Adding Template Variables

1. Add the variable to `copier.yml`:

```yaml
new_variable:
  type: str
  help: "Description of the variable"
  default: "default_value"
```

2. For conditional variables, add a `when` clause:

```yaml
new_variable:
  type: str
  when: "{{ ci_platform == 'gitlab' }}"
  help: "Only shown for GitLab"
```

3. Use it in templates with `{{ new_variable }}`

4. Update documentation in `docs/template-reference.md`

5. Run `just testing::test-template` to verify

## Just Module Structure

The project uses just modules with explicit paths for tab completion:

```just
# Root justfile
mod cicd 'just/cicd.just'      # cicd::build, cicd::test
mod config 'just/config.just'  # config::schema, config::check
mod copier 'just/copier.just'  # copier::update, copier::diff
mod git 'just/git.just'        # git::version
mod testing 'just/testing.just' # testing::test-template

import 'just/dev.just'  # Merged into root namespace
```

**Key patterns:**

- Use `mod name 'path'` for namespaced modules
- Use `import 'path'` only for `dev.just` (merged into root)
- Add `[group('name')]` attributes for recipe organization
- Use `[no-cd]` for recipes that need project root directory

## Local Documentation Development

Install dependencies and start the dev server:

```bash
uv sync
uv run mkdocs serve
```

Or use just:

```bash
just docs-serve
```

Open http://localhost:8000 to preview changes.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run `just testing::test-template` to verify
4. Submit a merge request
