# Branching Workflow

- **main** – production branch. Only merge PRs that have been thoroughly tested.
- **develop** – integration branch. All feature branches are merged here first.
- **feature/*** – short‑lived branches for individual pieces of work (e.g., `feature/k8s`).

### Rules
1. **Never commit directly to `main` or `develop`.** All changes go through a Pull Request.
2. **Every PR must target `develop`.**
3. **Merge `develop` → `main` only after a release tag is created.**
4. **Tagging**
   - `v1.0.0` – after Docker images and `docker‑compose.yml` are verified.
   - `v1.1.0` – after Kubernetes manifests are validated and deployed.
5. **Push tags** with `git push origin <tag>`.

### Example Commands
```bash
# create a feature branch
git checkout -b feature/k8s develop
# work, commit, push
git push -u origin feature/k8s
# open a PR to develop, merge, then delete the branch

# after merging to develop
git checkout develop
git pull
# tag the release
git tag -a v1.1.0 -m "Kubernetes complete"
git push origin v1.1.0
```
