# Shared helpers

R and Python helpers in this folder are sourced by the runnable scripts; they are not a separate pipeline. `data_paths.R` defines local input and output paths, the ring-event files hold source parsing and QA logic, and the publication files assemble citation and reference metadata.

Keep shared logic here only when several scripts use it or it is a clear conceptual unit. Run workflows from [`scripts/`](../README.md) rather than executing these helpers alone.
