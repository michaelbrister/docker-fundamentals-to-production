# Scenario 3 — Schema missing (state)

## Intentional break
The database starts, but the schema is missing (notes table never created).

## What success looks like
- You identify schema vs connectivity issues
- You fix schema creation responsibly
- You can explain why init scripts may not run on restart
