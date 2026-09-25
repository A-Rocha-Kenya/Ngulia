# Generated delivery files

This folder contains local, regenerable exports and is excluded from Git except for this README. Build them with the export scripts listed in [`scripts/`](../scripts/README.md).

| Folder | Contents |
| --- | --- |
| `website/` | Files consumed by the separate Ngulia website. |
| `zenodo/` | Six upload files, checksum manifest, deposit worksheet, and dataset README. The builder replaces this folder's contents. |
| `gbif/` | Darwin Core Archive and its event, occurrence, measurement, and metadata files. |

Review [publication status and order](../docs/publication.md) before uploading or registering any export.

## Website export

`01_build_website_exports.R` reads curated daily counts, the manually curated recovery table, and taxonomy mappings, then writes JSON to `exports/website/`.

For local website syncing, point the website preprocessing configuration to this project's `exports/website/` directory.

## Related resources

The GBIF export in `exports/gbif/` uses confirmed capture dates as the Event core, individual ringing records as the Occurrence extension, and biometric and moult observations as bird-level ExtendedMeasurementOrFact rows. Resolved `ringer_name` values are exported as the Darwin Core `recordedBy` field. Daily species counts and environmental variables are excluded; the EML description links to the complete Zenodo research dataset.
