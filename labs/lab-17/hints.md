# Lab 17 — Hints

## What is an SBOM (in plain English)?
A list of “what’s inside your image”:
- libraries
- versions
- where they came from

It helps answer: “Are we running a vulnerable version?”

## Don’t overreact to scan noise
Scanners commonly report a lot of HIGH/MEDIUM findings.
Teams usually set a policy (like **CRITICAL only**) so development can continue.

## If Grype fails with CRITICAL findings
Do this:
1) Identify the package name + version
2) Find what pulled it in (base image vs app dependency)
3) Decide:
   - upgrade base image
   - bump a dependency
   - accept temporarily with documented rationale

## Validate your SBOM file
- Must exist
- Must be non-empty
- Must be JSON
