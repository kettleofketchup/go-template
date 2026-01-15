# CI Platform Choice Design

## Overview

Add support for choosing between GitLab CI and GitHub Actions in the copier template, with a shared `just cicd::*` module to keep build logic platform-agnostic.

## Requirements

- Single-choice question: GitLab OR GitHub
- CI files only created for the selected platform
- Platform-specific variables (registry URLs) only asked when relevant
- All CI logic lives in `just/cicd.just` module
- CI workflow files are thin wrappers calling just recipes
- Apply same pattern to both go-template repo and generated projects

## Copier Questions

### New `ci_platform` question

```yaml
ci_platform:
  type: str
  help: "CI/CD platform for automated builds and deployments"
  choices:
    gitlab: "GitLab CI"
    github: "GitHub Actions"
```

### Conditional variables

```yaml
gitlab_url:
  type: str
  when: "{{ ci_platform == 'gitlab' }}"
  help: "GitLab instance URL"
  default: "gitlab.lan"

gitlab_registry:
  type: str
  when: "{{ ci_platform == 'gitlab' }}"
  help: "Docker registry path"
  default: "{{ gitlab_url }}:5050/{{ project_name }}"

github_registry:
  type: str
  when: "{{ ci_platform == 'github' }}"
  help: "GitHub Container Registry path"
  default: "ghcr.io/{{ project_name }}"
```

## Just CICD Module

New file `just/cicd.just` with recipes:

| Recipe | Purpose |
|--------|---------|
| `cicd::lint` | Run golangci-lint |
| `cicd::test` | Run go test with race/coverage |
| `cicd::build` | Build binary to bin/ |
| `cicd::docker tag push="false"` | Build docker image, optionally push |
| `cicd::pages` | Build mkdocs documentation |

## File Structure

### Conditional file creation

Use Jinja conditionals in file/directory names per copier docs:

```
template/{{ project_name }}/
├── {% if ci_platform == 'gitlab' %}.gitlab-ci.yml{% endif %}.jinja
├── {% if ci_platform == 'github' %}.github{% endif %}/
│   └── workflows/
│       ├── ci.yml.jinja
│       └── pages.yml.jinja
└── just/
    └── cicd.just.jinja
```

### GitLab CI structure

Thin wrapper calling just recipes:

```yaml
stages: [test, build, docker, pages]

lint:
  stage: test
  image: golangci/golangci-lint:latest
  script: just cicd::lint

test:
  stage: test
  image: golang:1.23
  script: just cicd::test

build:
  stage: build
  image: golang:1.23
  script: just cicd::build

docker:
  stage: docker
  image: docker:latest
  script: just cicd::docker $TAG true

pages:
  stage: pages
  image: ghcr.io/astral-sh/uv:python3.12-bookworm
  script: just cicd::pages
```

### GitHub Actions structure

Split into two workflows:

**ci.yml** - runs on PRs and tags:
- lint, test, build jobs
- docker job (tags only)

**pages.yml** - runs on main branch:
- builds and deploys to GitHub Pages

## Implementation Tasks

1. Update `copier.yml` with new questions and conditional variables
2. Create `just/cicd.just` for go-template repo
3. Add GitHub Actions workflows to go-template repo
4. Update go-template's `.gitlab-ci.yml` to use just recipes
5. Create `template/.../just/cicd.just.jinja` for generated projects
6. Rename template GitLab CI to conditional filename
7. Create template GitHub Actions with conditional directory
8. Update template justfile to import cicd module
9. Test both platform choices generate correct files
