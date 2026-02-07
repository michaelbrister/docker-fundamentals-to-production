# Security Notes (Lab 17)

Keep this practical. Think like a team member writing notes for review.

## Policy
- Our policy is to fail CI on: **CRITICAL** vulnerabilities only.
- HIGH/MEDIUM/LOW are allowed for now, but should be reviewed on a schedule.

## Findings (summarize)
If there were CRITICAL findings:
- Package:
- Version:
- Source (base image vs app dependency):
- Fix available? (yes/no)
- Mitigation plan:

If there were no CRITICAL findings:
- State that clearly and note that “no critical” ≠ “no risk”.

## Risk decision
What risk are we accepting by shipping this image today? (2–5 bullets)
-

## Next improvements (backlog)
What would you improve next?
- Pin base image digests
- Reduce packages in builder
- Add SBOM + scan to CI
- Etc.
