"""Label parsing utilities for ADW workflows."""

from typing import Any


def get_target_branch(issue: Any, default: str = "main") -> str:
    """Extract target branch from issue labels.

    Looks for labels matching 'target:<branch>' pattern.
    Returns the branch name or default if not found.

    Args:
        issue: GitHubIssue object with labels
        default: Branch to return if no target: label found

    Returns:
        Branch name from target: label, or default

    Examples:
        - "target:llm-ui" -> "llm-ui"
        - "target:develop" -> "develop"
        - No target label -> "main" (default)
    """
    for label in issue.labels:
        if label.name.startswith("target:"):
            return label.name.split(":", 1)[1].strip()
    return default
