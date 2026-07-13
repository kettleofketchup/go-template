# Fang CLI styling for the cobra template — Design

**Date:** 2026-07-13
**Status:** Approved (pending spec review)
**Topic:** Replace the hand-rolled cobra `Execute()` with Charmbracelet **Fang** to give every
generated project styled help/usage/errors, an automatic `--version`, shell completions, man
pages, and a per-project brand accent color — plus a coordinated dependency/CI upgrade.

## Background

The user asked to use Fang (`charm.land/fang/v2`) to add "better and cleaner coloration/setup for
cobra", referencing hookshot MR !26 as prior art.

**Finding:** MR !26 does **not** use Fang. It migrated hookshot's whole Charm stack to v2
(`charm.land/*/v2`, forcing Go 1.25.8) and built a bespoke `src/shared/ui` design-system package
for an interactive DNS-takeover preview. That is far heavier than a starter template needs, and it
is hookshot-specific. This design instead uses **Fang**, which is the purpose-built library for
"make a cobra CLI look good with one call", and keeps everything generic — **no hookshot code or
references are copied in.**

This repository is a **copier template**. All Go changes are `.jinja` files under
`template/src/{{ tool_name }}/…` and render per generated project. There is no top-level Go module,
so the build is verified by rendering the template to a temp dir and building the generated project.

## Goals

- One-call styled cobra via `fang.Execute` (help, usage, errors, `--version`, completions, manpages).
- A per-project **brand accent color**, chosen at scaffold time, defaulting to Fang's own default.
- Human-facing command output (`version`, `config path`, config-load notices) styled consistently.
- Coordinated upgrade: Go, cobra, viper, and CI Go version bumped to satisfy the v2 Charm stack.
- Generated projects compile and vet cleanly for **both** `ci_platform` values (github, gitlab).

## Non-goals

- No bespoke `ui` design-system package (no tokens/layout/diff/Bubble Tea preview). That is
  hookshot's scope, not a template's.
- **No coloring of machine-readable output.** `config show` (YAML) and `config schema` (JSON)
  stay raw so pipes/redirects are not corrupted. Lipgloss already degrades under `NO_COLOR` and
  non-TTY, but data output is left entirely unstyled regardless.

## Dependencies & versions

Fang v2 is `charm.land/fang/v2`; its `go.mod` requires **Go 1.25.0** and pulls
`charm.land/lipgloss/v2`. To stay coherent with that stack:

| Item | From | To |
|------|------|-----|
| `go` directive (`go.mod.jinja`) | `1.23` | `1.25` |
| CI Go version (gitlab `GO_VERSION`, github `go-version` ×3) | `1.23` | `1.25` |
| `github.com/spf13/cobra` | `1.8.1` | `1.10.1` |
| `github.com/spf13/viper` | `1.19.0` | `1.21.0` |
| `charm.land/fang/v2` | — | pinned from rendered `go mod tidy` |
| `charm.land/lipgloss/v2` | — | pinned from rendered `go mod tidy` |

`github.com/invopop/jsonschema` and `gopkg.in/yaml.v3` are unchanged. Exact minor/patch versions
for the two new Charm deps are pinned from the prototype build (Prototype step), not guessed.

> **CI reachability note (carried from MR !26):** runners must reach `charm.land/*/v2` modules via
> `GOPROXY`. If a runner is mirror-restricted, mirror `charm.land/*` first. Documented in the
> generated project's docs, not enforced here.

## New copier question

```yaml
accent_color:
  type: str
  help: "Brand accent color for CLI help/output (hex, e.g. #6B50FF)"
  default: "#6B50FF"   # Fang's default Title accent (charmtone "Charple")
```

`#6B50FF` is exactly `charmtone.Charple`, the color Fang's `DefaultColorScheme` uses for `Title`.
With the default unchanged, styled output is pixel-identical to stock Fang. The answer auto-flows
into `.copier-answers.yml` (that template already dumps `_copier_answers`).

## Components

All paths under `template/src/{{ tool_name }}/`.

### `cmd/root.go.jinja` — entrypoint (changed)

`Execute()` is rewritten to delegate to Fang:

```go
func Execute() {
    if err := fang.Execute(
        context.Background(),
        rootCmd,
        fang.WithVersion(version.Version),
        fang.WithCommit(version.Commit),
        fang.WithColorSchemeFunc(brandColorScheme),
    ); err != nil {
        os.Exit(1)
    }
}
```

New imports: `context`, `charm.land/fang/v2`, and the project's `version` package. The
`cobra.OnInitialize(initConfig)` + viper wiring in `init()`/`initConfig()` is unchanged.

### `cmd/style.go.jinja` — theme + shared styles (new)

Single home for the accent and the Fang color scheme:

```go
const accentColor = "{{ accent_color }}"

// brandColorScheme starts from Fang's default and swaps in the project accent.
// With accent_color at its default (#6B50FF) this reproduces Fang's default exactly.
func brandColorScheme(c lipgloss.LightDarkFunc) fang.ColorScheme {
    cs := fang.DefaultColorScheme(c)
    cs.Title = lipgloss.Color(accentColor)
    return cs
}

// Reused by styled command output.
var (
    accentStyle = lipgloss.NewStyle().Foreground(lipgloss.Color(accentColor)).Bold(true)
    labelStyle  = lipgloss.NewStyle().Faint(true)
)
```

Only `Title` is overridden by the accent, so the default is faithful; a comment notes that
`Command`/`ErrorHeader`/etc. can be themed the same way. `lipgloss` here is `charm.land/lipgloss/v2`.

### `cmd/version.go.jinja` — styled `version` subcommand (changed)

Kept (it shows commit + build date, which Fang's one-line `--version` does not). Output is routed
through `accentStyle`/`labelStyle` via `lipgloss.Println`/`Fprintln` so it downsamples correctly.

### `cmd/config.go.jinja` — partial styling (changed)

`config path`'s human-facing lines ("No config file loaded…", the path) get light styling.
`config show` (YAML) and `config schema` (JSON) remain **raw** — data, not decoration.

### `cmd/root.go.jinja` `initConfig` — config notices (changed)

"Using config file: …" (stderr) and the config-load error line are lightly styled (error in a red
style). Behavior/streams unchanged.

### Docs / skill (changed)

- `template/.claude/skills/golang-cobra-development/SKILL.md.jinja` — document the Fang entrypoint,
  the accent color, and where theming lives.
- `template/CLAUDE.md.jinja` — note that CLI UX is Fang-powered and how to change the accent.

## Data flow

`main() → cmd.Execute() → fang.Execute(ctx, rootCmd, opts…)`. Fang owns arg parsing, help/error
rendering, and version/completion/manpage subcommands. Individual command `Run` funcs still write
their own output; human-facing lines use the shared styles, machine output stays raw.

## Error handling

- Fang renders cobra/command errors in its styled error format; `Execute()` maps a non-nil return
  to `os.Exit(1)` (same contract as today).
- Data-marshaling errors in `config`/`version` keep their existing `Fprintf(os.Stderr, …)` +
  `os.Exit(1)` behavior.

## Testing / verification

1. **Prototype:** render to a temp dir (self_update on, one ci_platform), wire Fang, `go mod tidy`
   → `go build ./...` → `go vet ./...`. Pin the two new dep versions from the resulting `go.mod`.
2. **Cross-platform render:** after porting into `.jinja`, render **both** `ci_platform=github`
   and `ci_platform=gitlab` (imports branch on it) and build+vet each.
3. **Smoke the UX:** run `<tool> --help`, `<tool> --version`, `<tool> version`, `<tool> config
   path` in a rendered project; confirm styled help/errors and that `--version`/completions exist.
4. **Existing suite:** run the template's own `test-template` flow / `just` test recipes if they
   render + build; fix any breakage from the version bumps.

## Risks

- **Go 1.25 requirement** is a hard floor from fang v2. Anyone generating a project needs Go ≥1.25;
  CI images are bumped to match. Accepted — it is the cost of the v2 Charm stack.
- **`charm.land` proxy reachability** in restricted CI (see note above) — documented, not solved here.
- **`-v` shorthand**: Fang binds `-v`/`--version`. The template defines no conflicting `-v`, so no
  collision; noted for downstream authors.
