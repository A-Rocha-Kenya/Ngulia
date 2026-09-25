# Ring-event curation rules

These CSV files describe annual source workbooks, reviewed corrections and ring-history decisions, species and ringer lookups, measurement ranges, and moult decoding. `01_build_ring_events.R` reads them to create `ring_events.csv` and row-level QA logs.

Edit the relevant rule rather than a raw workbook or generated CSV. Run the builder and inspect its issue and audit outputs after a change. See [processing and validation](../../docs/dataset.md) for the meaning of each rule and output.
