# Lab 17 — Instructor Notes

## Intent
Teach supply-chain basics in a calm, practical way:
- SBOM creation (Syft)
- Vulnerability scanning (Grype)
- Policy gating (fail CRITICAL only)
- Documentation of risk decisions

## Common mistakes
- Learners assume “any vuln = fail”
- Learners don’t understand base image vs dependency findings
- Learners don’t pin versions and use `latest`
- Learners skip documentation (“tool output is enough”)

## Coaching prompts
- “What’s the difference between detection and risk?”
- “What evidence would you show security?”
- “What is your mitigation plan and timeline?”

## Strictness
Fail if:
- SBOM.md / SECURITY_NOTES.md missing or empty
- sbom.json missing/empty
- scanning not performed or policy not followed
