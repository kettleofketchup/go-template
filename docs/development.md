# Development

## Testing the Template

Run the end-to-end test to verify the template generates working projects:

```bash
just test.template
```

This will:

1. Generate a test project with hardcoded values
2. Run `just build` in the generated project
3. Run `just test` in the generated project
4. Run `just lint` in the generated project
5. Run `just docker.build` in the generated project
6. Clean up on success, keep artifacts on failure

### Test Values

| Variable | Test Value |
|----------|------------|
| `project_name` | `testproject` |
| `tool_name` | `testtool` |
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
just clean.test
```

## Template File Conventions

### Jinja Templates

Files that need variable substitution use the `.jinja` extension:

- `just/justfile.jinja` → `just/justfile`
- `go.mod.jinja` → `go.mod`
- `.gitlab-ci.yml.jinja` → `.gitlab-ci.yml`

### Static Files

Files without `.jinja` are copied verbatim:

- `docs/includes/abbreviations.md`
- `.gitignore`

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

2. Use it in templates with `{{ new_variable }}`

3. Update documentation in `docs/template-reference.md`

4. Run `just test.template` to verify

## Local Documentation Development

Install dependencies and start the dev server:

```bash
uv sync
uv run mkdocs serve
```

Open http://localhost:8000 to preview changes.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run `just test.template` to verify
4. Submit a merge request
