# Documentation Governance

## Purpose

As the Finance Foundry grows, documentation can become fragmented and contradictory if the same information is maintained in multiple places.

This document defines the canonical location for each type of information in the project.

## Principle

**Every fact should have exactly one canonical home.**

Other documents may reference that information, but should not duplicate it.

When information changes, only the canonical source should require modification.

---

## Canonical Locations

| Information Type | Canonical Location |
|------------------|-------------------|
| Project purpose, goals, and high-level overview | README.md |
| System architecture and pipeline design | Wiki: Architecture |
| Architectural decisions and lessons learned | Wiki: Lessons Learned |
| Environment setup and installation instructions | docs/ |
| Operational procedures | docs/ |
| Bank onboarding procedures | docs/ |
| Metadata file specifications | docs/ |
| SQL view sequence and responsibilities | Wiki: Architecture |
| Naming conventions | Wiki: Architecture |
| AWS deployment instructions | docs/ |
| Troubleshooting procedures | docs/ |

---

## Documentation Ownership

### README

The README should answer:

- What is this project?
- Why does it exist?
- What problem does it solve?
- Where can I learn more?

The README should remain concise and link to more detailed documentation.

### Architecture Wiki

The Architecture Wiki should answer:

- How does the system work?
- What are the pipeline stages?
- What responsibilities belong to each layer?
- What conventions govern the system?

### Lessons Learned Wiki

The Lessons Learned Wiki should answer:

- Why was a decision made?
- What alternatives were considered?
- What mistakes were discovered?
- What principles emerged from implementation?

### docs/

The docs directory should answer:

- How do I install the system?
- How do I configure the environment?
- How do I operate the system?
- How do I onboard a new bank?
- How do I troubleshoot common issues?

---

## Anti-Pattern

Avoid maintaining the same information in multiple locations.

For example:

- The pipeline architecture should be defined in the Architecture Wiki.
- Other documents should link to the Architecture Wiki rather than reproducing the pipeline diagram.

---

## Rule of Thumb

Before adding documentation, ask:

> Is this the canonical home for this information?

If the answer is no, add a reference rather than a duplicate.
