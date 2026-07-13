### metadata/

# R Source Code

## comment

Each directory answers a different question:

commands — What can the user ask the Foundry to do?
execution — How does the Foundry carry out work?
platform — How does the Foundry talk to its execution environment?
reporting — How does the Foundry present information?
privacy — How does the Foundry protect sensitive information?
utils — General-purpose support that doesn't yet belong elsewhere.

This directory contains the R implementation of Finance Foundry.

The repository may eventually become an R package. This directory follows the
standard R package convention of organizing reusable source code rather than
interactive scripts.

## Directory Structure

### commands/

User-facing entry points for the Finance Foundry command-line interface.

Examples include:

- `ff run`
- `ff metadata validate`
- `ff metadata build`
- `ff metadata publish`

Command functions should be thin wrappers that delegate work to the rest of the
codebase.

---

Functions that read, validate, transform, and publish Finance Foundry metadata.

Typical responsibilities include:

- reading metadata source files
- validating metadata
- generating deployment artifacts
- loading metadata into execution environments

This directory contains code that operates on metadata. The metadata itself
lives under `/metadata`.

---

### execution/

Coordinates execution of the Finance Foundry pipeline.

Responsibilities include:

- pipeline orchestration
- execution sequencing
- selecting the execution backend
- progress reporting
- error handling

This layer coordinates work but should contain little business logic.

---

### platform/

Interfaces to cloud services.

Examples include:

- Amazon S3
- AWS Glue
- Amazon Athena

Cloud-specific implementation details should remain isolated here whenever
possible.

---

### utils/

General-purpose helper functions shared across the R codebase.

This directory should remain small. Functionality that grows into a coherent
subsystem should be moved into its own directory.

## Design Principles

- Organize code by responsibility rather than technology.
- Keep Finance Foundry business rules in metadata whenever possible.
- Keep SQL responsible for relational transformation.
- Keep R responsible for orchestration, validation, metadata management, and tooling.
- Keep cloud-specific code isolated from domain logic.# empty readme file
