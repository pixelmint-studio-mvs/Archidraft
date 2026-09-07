# GIT WORKFLOW

This team relies on a simple, safe, and beginner-friendly Git strategy to manage collaboration between multiple human developers and AI agents.

## Branch Strategy

- **`main`**: The primary branch. Code here must always be stable and production-ready.
- **`develop`**: Active integrated development. All feature branches merge here before going to main.

### Feature Branches
Use the `feature/` prefix for all development work.
Examples:
- `feature/authentication`
- `feature/user-profile`
- `feature/project-management`
- `feature/admin-workflow`
- `feature/draughtsman-workflow`
- `feature/file-storage`
- `feature/corrections`

## IMPORTANT GIT RULES
1. **DO NOT directly modify `main`.** All changes must happen in feature branches and merge via Pull Request (PR).
2. **DO NOT mix multiple unrelated features in one branch.** Keep branches scoped to a specific task.
3. **DO NOT overwrite another developer's work.** If a conflict occurs, resolve it carefully.
4. **Pull the latest changes** from `develop` before beginning any new feature work.
5. **Review changed files** before committing (e.g., check `git status` and `git diff`).
6. **Keep commits focused** and atomic.

## COMMIT STANDARD
Use the following conventional commit format to keep history readable:

- `feat:` for new features (e.g., `feat: add authentication foundation`)
- `fix:` for bug fixes (e.g., `fix: correct project state validation`)
- `docs:` for documentation changes (e.g., `docs: update workflow documentation`)
- `refactor:` for code restructuring without changing behavior (e.g., `refactor: improve project model structure`)
- `test:` for adding/fixing tests (e.g., `test: add workflow validation tests`)
