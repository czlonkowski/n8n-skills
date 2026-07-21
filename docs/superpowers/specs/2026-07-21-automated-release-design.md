# Automated Release Workflow Design

## Purpose
Automate the GitHub Release process for `n8n-skills` so that every time a new version tag (`v*`) is pushed, the `build.sh` script runs and its output `.zip` files are published automatically.

## Approach
1. **Dynamic Versioning in Build Script**:
   Modify `build.sh` to accept a version argument (defaulting to the current hardcoded version if not provided), and strip the `v` prefix if present.
   ```bash
   VERSION="${1:-1.25.0}"
   VERSION="${VERSION#v}"
   ```

2. **GitHub Actions Workflow**:
   Create `.github/workflows/release.yml`.
   - **Trigger**: `push` on `tags: - 'v*'`
   - **Steps**:
     - `actions/checkout@v4`
     - Run `bash build.sh ${{ github.ref_name }}`
     - Use `softprops/action-gh-release@v2` with `files: dist/*.zip`

## Trade-offs and Constraints
- Modifying `build.sh` means future developers have the flexibility to specify the version manually if needed, while allowing the CI to do it automatically.
- Keeping the default fallback to `1.25.0` (or whatever it will be updated to manually by the maintainer in the future) ensures local development without arguments still works.

## Self-Review
- [x] Placeholders removed.
- [x] Internal consistency checked.
- [x] Scope is focused and single-purpose.
- [x] No ambiguity in requirements.
