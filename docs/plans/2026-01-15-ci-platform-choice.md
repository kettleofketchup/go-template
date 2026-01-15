# CI Platform Choice Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add GitLab/GitHub CI platform choice to copier template with shared `just cicd::*` module.

**Architecture:** Single-choice copier question controls which CI files are generated. All build logic lives in `just/cicd.just` module; CI workflow files are thin wrappers calling just recipes.

**Tech Stack:** Copier, Just, GitLab CI, GitHub Actions, MkDocs

---

## Task 1: Add `just/cicd.just` to go-template repo

**Files:**
- Create: `just/cicd.just`
- Modify: `just/justfile:8-9` (add import)

**Step 1: Create the cicd.just module**

Create `just/cicd.just`:

```just
# CI/CD recipes - platform-agnostic build commands
# Call as: just cicd::build, just cicd::test, etc.

# Build the Copier runner Docker image
build:
    @echo "Building Copier runner image..."
    docker build -t go-template:latest -f docker/Dockerfile .

# Test template generation produces working project
test-template:
    @echo "Testing template generation..."
    ./scripts/test-template.sh

# Build documentation to public/
pages:
    @echo "Building documentation..."
    uv sync
    uv run mkdocs build
```

**Step 2: Update just/justfile to import cicd module**

In `just/justfile`, add after line 9:

```just
mod cicd
```

**Step 3: Verify import works**

Run: `just --list`
Expected: Shows `cicd::build`, `cicd::pages`, `cicd::test-template`

**Step 4: Commit**

```bash
git add just/cicd.just just/justfile
git commit -m "feat: add cicd just module for go-template repo"
```

---

## Task 2: Update go-template `.gitlab-ci.yml` to use just recipes

**Files:**
- Modify: `.gitlab-ci.yml`

**Step 1: Update GitLab CI to use just recipes**

Replace `.gitlab-ci.yml` contents:

```yaml
stages:
  - build
  - test
  - pages

variables:
  IMAGE_NAME: go-template
  IMAGE_TAG: latest

# Build the copier runner image
build-image:
  tags:
    - dind
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache curl bash
    - curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
  script:
    - just cicd::build
    - docker save $IMAGE_NAME:$IMAGE_TAG > image.tar
  artifacts:
    paths:
      - image.tar
    expire_in: 1 hour
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# Test template generates working project
test-template:
  stage: test
  tags:
    - dind
  image: docker:latest
  services:
    - docker:dind
  needs:
    - build-image
  before_script:
    - docker load < image.tar
    - apk add --no-cache git go golangci-lint curl bash
    - curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
  script:
    - just cicd::test-template
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# Deploy documentation to GitLab Pages
pages:
  stage: pages
  image: ghcr.io/astral-sh/uv:python3.12-bookworm
  before_script:
    - apt-get update && apt-get install -y curl
    - curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
  script:
    - just cicd::pages
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
```

**Step 2: Commit**

```bash
git add .gitlab-ci.yml
git commit -m "refactor: use just cicd:: recipes in GitLab CI"
```

---

## Task 3: Add GitHub Actions to go-template repo

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/pages.yml`

**Step 1: Create CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main, master]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Build image
        run: just cicd::build

  test-template:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'

      - name: Install golangci-lint
        uses: golangci/golangci-lint-action@v6
        with:
          install-only: true

      - name: Test template
        run: just cicd::test-template
```

**Step 2: Create Pages workflow**

Create `.github/workflows/pages.yml`:

```yaml
name: Pages

on:
  push:
    branches: [main, master]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Build docs
        run: just cicd::pages

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

**Step 3: Commit**

```bash
git add .github/
git commit -m "feat: add GitHub Actions workflows for go-template repo"
```

---

## Task 4: Update copier.yml with platform choice

**Files:**
- Modify: `copier.yml`

**Step 1: Add ci_platform question and make variables conditional**

Replace `copier.yml` contents:

```yaml
_min_copier_version: "9.0.0"
_subdirectory: template
_templates_suffix: .jinja

project_name:
  type: str
  help: "Project name (used for repo directory and Go module path)"
  validator: "{% if not project_name %}Project name is required{% endif %}"

tool_name:
  type: str
  help: "CLI tool binary name (e.g., 'mytool' produces ./bin/mytool)"
  default: "{{ project_name }}"

ci_platform:
  type: str
  help: "CI/CD platform for automated builds and deployments"
  choices:
    gitlab: "GitLab CI"
    github: "GitHub Actions"

gitlab_url:
  type: str
  when: "{{ ci_platform == 'gitlab' }}"
  help: "GitLab instance URL (e.g., gitlab.example.com)"
  default: "gitlab.lan"

gitlab_registry:
  type: str
  when: "{{ ci_platform == 'gitlab' }}"
  help: "Docker registry path (e.g., gitlab.example.com:5050/group)"
  default: "{{ gitlab_url }}:5050/{{ project_name }}"

github_registry:
  type: str
  when: "{{ ci_platform == 'github' }}"
  help: "GitHub Container Registry path"
  default: "ghcr.io/{{ project_name }}"
```

**Step 2: Commit**

```bash
git add copier.yml
git commit -m "feat: add ci_platform choice to copier questions"
```

---

## Task 5: Create template `just/cicd.just.jinja`

**Files:**
- Create: `template/{{ project_name }}/just/cicd.just.jinja`
- Modify: `template/{{ project_name }}/just/justfile.jinja` (add mod cicd)

**Step 1: Create cicd.just.jinja**

Create `template/{{ project_name }}/just/cicd.just.jinja`:

```just
# CI/CD recipes - platform-agnostic build commands
# Call as: just cicd::lint, just cicd::test, etc.

TOOL_NAME := "{{ tool_name }}"
TOOL_FOLDER := env_var("PWD") + "/src/" + TOOL_NAME
BIN_DIR := env_var("PWD") + "/bin"

VERSION := `git describe --tags --always 2>/dev/null || echo "dev"`
COMMIT := `git rev-parse --short HEAD 2>/dev/null || echo "unknown"`
DATE := `date -u +%Y-%m-%dT%H:%M:%SZ`

{% if ci_platform == 'gitlab' -%}
DOCKER_REGISTRY := "{{ gitlab_registry }}"
{%- else -%}
DOCKER_REGISTRY := "{{ github_registry }}"
{%- endif %}
DOCKER_TAG := DOCKER_REGISTRY + "/" + TOOL_NAME + ":" + VERSION

# Run linter
lint:
    @echo "Running linter..."
    cd {{ '{{' }} TOOL_FOLDER {{ '}}' }} && golangci-lint run --timeout 5m

# Run tests with race detection and coverage
test:
    @echo "Running tests..."
    cd {{ '{{' }} TOOL_FOLDER {{ '}}' }} && go test -race -cover -v ./...

# Build the binary
build:
    @echo "Building binary..."
    @mkdir -p {{ '{{' }} BIN_DIR {{ '}}' }}
    cd {{ '{{' }} TOOL_FOLDER {{ '}}' }} && go build -o {{ '{{' }} BIN_DIR {{ '}}' }}/{{ '{{' }} TOOL_NAME {{ '}}' }} .

# Build docker image
docker tag=DOCKER_TAG:
    @echo "Building Docker image..."
    docker build \
        --build-arg VERSION={{ '{{' }} VERSION {{ '}}' }} \
        --build-arg COMMIT={{ '{{' }} COMMIT {{ '}}' }} \
        --build-arg BUILD_DATE={{ '{{' }} DATE {{ '}}' }} \
        -t {{ '{{' }} tag {{ '}}' }} \
        -f docker/Dockerfile.{{ '{{' }} TOOL_NAME {{ '}}' }} .

# Push docker image
docker-push tag=DOCKER_TAG: (docker tag)
    @echo "Pushing Docker image..."
    docker push {{ '{{' }} tag {{ '}}' }}

# Build documentation to public/
pages:
    @echo "Building documentation..."
    uv sync
    uv run mkdocs build
```

**Step 2: Update justfile.jinja to import cicd module**

In `template/{{ project_name }}/just/justfile.jinja`, add after line 15 (after `mod testing`):

```just
mod cicd
```

**Step 3: Commit**

```bash
git add "template/{{ project_name }}/just/cicd.just.jinja" "template/{{ project_name }}/just/justfile.jinja"
git commit -m "feat: add cicd just module to template"
```

---

## Task 6: Rename GitLab CI template to conditional filename

**Files:**
- Rename: `template/{{ project_name }}/.gitlab-ci.yml.jinja` → `template/{{ project_name }}/{% if ci_platform == 'gitlab' %}.gitlab-ci.yml{% endif %}.jinja`
- Modify: The renamed file (update to use just recipes)

**Step 1: Rename the file**

```bash
cd /home/kettle/git_repos/go-template
git mv "template/{{ project_name }}/.gitlab-ci.yml.jinja" "template/{{ project_name }}/{% if ci_platform == 'gitlab' %}.gitlab-ci.yml{% endif %}.jinja"
```

**Step 2: Update contents to use just recipes**

Replace contents of `template/{{ project_name }}/{% if ci_platform == 'gitlab' %}.gitlab-ci.yml{% endif %}.jinja`:

```yaml
stages:
  - test
  - build
  - docker
  - pages

variables:
  TOOL_NAME: {{ tool_name }}
  GO_VERSION: "1.23"

# Cache Go modules between jobs
.go-cache:
  variables:
    GOPATH: $CI_PROJECT_DIR/.go
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .go/pkg/mod/

.just-setup:
  before_script:
    - curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Test stage
lint:
  stage: test
  image: golangci/golangci-lint:latest
  extends: [.go-cache, .just-setup]
  script:
    - just cicd::lint
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG

test:
  stage: test
  image: golang:${GO_VERSION}
  extends: [.go-cache, .just-setup]
  script:
    - just cicd::test
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG

# Build stage
build:
  stage: build
  image: golang:${GO_VERSION}
  extends: [.go-cache, .just-setup]
  script:
    - just cicd::build
  artifacts:
    paths:
      - bin/
    expire_in: 1 hour
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG

# Docker stage
docker:
  stage: docker
  image: docker:latest
  services:
    - docker:dind
  variables:
    DOCKER_TAG: ${CI_REGISTRY_IMAGE}/${TOOL_NAME}:${CI_COMMIT_TAG}
    DOCKER_LATEST: ${CI_REGISTRY_IMAGE}/${TOOL_NAME}:latest
  before_script:
    - apk add --no-cache curl bash
    - curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - just cicd::docker $DOCKER_TAG
    - docker push $DOCKER_TAG
    - |
      if echo "$CI_COMMIT_TAG" | grep -qE '^v[0-9]+\.[0-9]+'; then
        docker tag $DOCKER_TAG $DOCKER_LATEST
        docker push $DOCKER_LATEST
      fi
  rules:
    - if: $CI_COMMIT_TAG

# Pages stage
pages:
  stage: pages
  image: ghcr.io/astral-sh/uv:python3.12-bookworm
  before_script:
    - apt-get update && apt-get install -y curl
    - curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
  script:
    - just cicd::pages
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
```

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: make GitLab CI conditional and use just recipes"
```

---

## Task 7: Create GitHub Actions template files

**Files:**
- Create: `template/{{ project_name }}/{% if ci_platform == 'github' %}.github{% endif %}/workflows/ci.yml.jinja`
- Create: `template/{{ project_name }}/{% if ci_platform == 'github' %}.github{% endif %}/workflows/pages.yml.jinja`

**Step 1: Create directory structure**

```bash
mkdir -p "template/{{ project_name }}/{% if ci_platform == 'github' %}.github{% endif %}/workflows"
```

**Step 2: Create CI workflow template**

Create `template/{{ project_name }}/{% if ci_platform == 'github' %}.github{% endif %}/workflows/ci.yml.jinja`:

```yaml
name: CI

on:
  pull_request:
  push:
    tags: ['v*']

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'

      - name: Install golangci-lint
        uses: golangci/golangci-lint-action@v6
        with:
          install-only: true

      - name: Lint
        run: just cicd::lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'

      - name: Test
        run: just cicd::test

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23'

      - name: Build
        run: just cicd::build

      - name: Upload binary
        uses: actions/upload-artifact@v4
        with:
          name: {{ tool_name }}
          path: bin/

  docker:
    runs-on: ubuntu-latest
    needs: [lint, test, build]
    if: startsWith(github.ref, 'refs/tags/v')
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: {{ '${{ github.actor }}' }}
          password: {{ '${{ secrets.GITHUB_TOKEN }}' }}

      - name: Build and push
        run: |
          TAG="{{ github_registry }}/{{ tool_name }}:${GITHUB_REF_NAME}"
          just cicd::docker $TAG
          docker push $TAG
          if echo "${GITHUB_REF_NAME}" | grep -qE '^v[0-9]+\.[0-9]+'; then
            LATEST="{{ github_registry }}/{{ tool_name }}:latest"
            docker tag $TAG $LATEST
            docker push $LATEST
          fi
```

**Step 3: Create Pages workflow template**

Create `template/{{ project_name }}/{% if ci_platform == 'github' %}.github{% endif %}/workflows/pages.yml.jinja`:

```yaml
name: Pages

on:
  push:
    branches: [main, master]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Build docs
        run: just cicd::pages

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: public

  deploy:
    environment:
      name: github-pages
      url: {{ '${{ steps.deployment.outputs.page_url }}' }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add GitHub Actions templates with conditional directory"
```

---

## Task 8: Update template docker.just for platform choice

**Files:**
- Modify: `template/{{ project_name }}/just/docker.just.jinja`

**Step 1: Update docker.just.jinja to support both platforms**

Replace `template/{{ project_name }}/just/docker.just.jinja` contents:

```just
# Docker build and push recipes
# Call as: just docker::build, just docker::push, etc.

TOOL_NAME := "{{ tool_name }}"
PROJECT_ROOT := env_var("PWD")
VERSION := `git describe --tags --always 2>/dev/null || echo "dev"`
COMMIT := `git rev-parse --short HEAD 2>/dev/null || echo "unknown"`
DATE := `date -u +%Y-%m-%dT%H:%M:%SZ`

{% if ci_platform == 'gitlab' -%}
DOCKER_REGISTRY := "{{ gitlab_registry }}"
{%- else -%}
DOCKER_REGISTRY := "{{ github_registry }}"
{%- endif %}
DOCKER_TAG := DOCKER_REGISTRY + "/" + TOOL_NAME + ":" + VERSION
DOCKER_LATEST := DOCKER_REGISTRY + "/" + TOOL_NAME + ":latest"
DOCKERFILE := PROJECT_ROOT + "/docker/Dockerfile." + TOOL_NAME

{% if ci_platform == 'gitlab' -%}
# Login to GitLab registry
login:
    @echo "Logging into GitLab registry..."
    docker login {{ gitlab_url }}:5050
{%- else -%}
# Login to GitHub Container Registry
login:
    @echo "Logging into GitHub Container Registry..."
    @echo "Use: echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
{%- endif %}

# Build Docker image
build:
    @echo "Building Docker image..."
    cd {{ '{{' }} PROJECT_ROOT {{ '}}' }} && docker build \
        --build-arg VERSION={{ '{{' }} VERSION {{ '}}' }} \
        --build-arg COMMIT={{ '{{' }} COMMIT {{ '}}' }} \
        --build-arg BUILD_DATE={{ '{{' }} DATE {{ '}}' }} \
        -t {{ '{{' }} DOCKER_TAG {{ '}}' }} \
        -f {{ '{{' }} DOCKERFILE {{ '}}' }} .
    docker tag {{ '{{' }} DOCKER_TAG {{ '}}' }} {{ '{{' }} DOCKER_LATEST {{ '}}' }}
    @echo "Built: {{ '{{' }} DOCKER_TAG {{ '}}' }}"

# Push Docker image to registry
push: build
    @echo "Pushing Docker image..."
    docker push {{ '{{' }} DOCKER_TAG {{ '}}' }}
    docker push {{ '{{' }} DOCKER_LATEST {{ '}}' }}
```

**Step 2: Commit**

```bash
git add "template/{{ project_name }}/just/docker.just.jinja"
git commit -m "refactor: update docker.just to support both GitLab and GitHub registries"
```

---

## Task 9: Update template go.just for platform choice

**Files:**
- Modify: `template/{{ project_name }}/just/go.just.jinja`

**Step 1: Update VERSION_PKG to use correct module path**

In `template/{{ project_name }}/just/go.just.jinja`, change line 10-11 from:

```just
VERSION_PKG := "{{ gitlab_url }}/{{ project_name }}/src/{{ tool_name }}/version"
```

To:

```just
{% if ci_platform == 'gitlab' -%}
VERSION_PKG := "{{ gitlab_url }}/{{ project_name }}/src/{{ tool_name }}/version"
{%- else -%}
VERSION_PKG := "github.com/{{ github_registry | replace('ghcr.io/', '') }}/src/{{ tool_name }}/version"
{%- endif %}
```

**Step 2: Commit**

```bash
git add "template/{{ project_name }}/just/go.just.jinja"
git commit -m "refactor: update go.just VERSION_PKG for platform choice"
```

---

## Task 10: Test template generation for both platforms

**Step 1: Test GitLab platform**

```bash
cd /home/kettle/git_repos/go-template
rm -rf /tmp/test-gitlab
mkdir -p /tmp/test-gitlab
copier copy . /tmp/test-gitlab --data project_name=testproj --data tool_name=testtool --data ci_platform=gitlab --data gitlab_url=gitlab.example.com --data gitlab_registry=gitlab.example.com:5050/testproj
```

**Step 2: Verify GitLab files exist**

```bash
ls -la /tmp/test-gitlab/testproj/.gitlab-ci.yml
ls /tmp/test-gitlab/testproj/.github 2>/dev/null && echo "ERROR: .github should not exist" || echo "OK: .github not created"
ls /tmp/test-gitlab/testproj/just/cicd.just
```

**Step 3: Test GitHub platform**

```bash
rm -rf /tmp/test-github
mkdir -p /tmp/test-github
copier copy . /tmp/test-github --data project_name=testproj --data tool_name=testtool --data ci_platform=github --data github_registry=ghcr.io/testproj
```

**Step 4: Verify GitHub files exist**

```bash
ls -la /tmp/test-github/testproj/.github/workflows/ci.yml
ls -la /tmp/test-github/testproj/.github/workflows/pages.yml
ls /tmp/test-github/testproj/.gitlab-ci.yml 2>/dev/null && echo "ERROR: .gitlab-ci.yml should not exist" || echo "OK: .gitlab-ci.yml not created"
ls /tmp/test-github/testproj/just/cicd.just
```

**Step 5: Verify just recipes work**

```bash
cd /tmp/test-github/testproj
just --list | grep "cicd::"
```

Expected: Shows `cicd::lint`, `cicd::test`, `cicd::build`, `cicd::docker`, `cicd::docker-push`, `cicd::pages`

**Step 6: Commit any fixes if needed and final commit**

```bash
git add -A
git commit -m "test: verify template generation for both CI platforms" --allow-empty
```

---

## Summary

After completing all tasks:

1. go-template repo has both GitLab CI and GitHub Actions using `just cicd::*`
2. Generated projects get only the selected platform's CI files
3. All CI logic lives in `just/cicd.just` module
4. Platform-specific variables (registry URLs) are conditional
5. Both platforms tested and working
