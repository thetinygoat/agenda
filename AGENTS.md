This file provides instructions and guidelines for automated agents interacting with this repository.

## 1. Read Swift Version from Package.swift
Agents must detect the Swift tools version from the top of Package.swift. Example:

swift
Copy
Edit
// swift-tools-version:5.9
This version declaration must be used as the authoritative source for:

Swift toolchain selection

Compatibility checks

Linting and formatting rules, if version-dependent

Do not hardcode the version elsewhere.

## 2. Do Not Modify Files Unless Explicitly Asked
Agents must not make any file modifications unless:

Explicit instructions are given in a specific commit, PR, or comment.

The changes are part of an approved workflow (e.g., bumping version on release with git tag).

Unauthorized changes will be reverted, and the agent may be disabled.

## 3. Use Git Tags to Determine Available Versions
To find available versions:

List annotated or lightweight Git tags using:

sh
Copy
Edit
git tag
Tags follow semantic versioning (e.g., v1.0.0, v1.2.1-beta).

Use tags instead of scanning file contents to infer version history.

Do not assume the latest commit on main is the latest release.

## 4. Respect .gitignore and .gitattributes
Agents must:

Never commit files listed in .gitignore

Respect .gitattributes settings (e.g., line endings, linguist overrides)

## 5. Commit Metadata and Authoring
All automated commits must:

Use a clear, consistent author (e.g., bot@example.com)

Include meaningful commit messages

Include a [bot] or [agent] marker in the subject or body

Example:

vbnet
Copy
Edit
chore: regenerate docs from source [bot]
## 6. Avoid Overwriting Human Work
If a file is edited manually by a human in a recent commit, the agent must not overwrite it without review.

Use git log to check author metadata before modifying any files.

## 7. Pull Request Etiquette
When creating pull requests:

Include a summary of what was changed and why

Link to the context (task, issue, instruction)

Add appropriate labels (e.g., automation, chore)
