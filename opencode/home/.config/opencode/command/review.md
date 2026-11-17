---
description: Review code changes
---

# Review

Review the code changes.

## Summary

What changed? (affected modules/layers, functional vs technical changes, overall
intent).

Unless instructed otherwise, only consider the working tree's diff. If you find
none, ask the user for clarification.

## The actual review

### Critical Issues (if any)

- Bugs or security gaps
- Breaking changes for existing consumers: call sites elsewhere in the codebase,
  and external clients of an API, library, or CLI
- Logic errors or edge cases not handled

### Architecture & Design

- Changes that don't align with the codebase patterns
- Better approaches or refactoring opportunities
- Performance/algorithmic improvements

### Code Quality

- Clarity/readability improvements
- Type safety or validation gaps
- Error handling issues

### Housekeeping

- TODOs, commented code, or debug statements
- Missing tests or documentation
- Code duplication
- Anything that seems out of place

### Documentation

- Point out updates (if any) that should be made to this projects docs (README,
  CONTRIBUTING...)

## Additional instructions

- Put a number in front of every finding so it can be referenced easily
- Include code examples for non-obvious recommendations
- Focus on issues introduced or made worse by the current changes. If you find
  pre-existing problems, mention them briefly at the end
