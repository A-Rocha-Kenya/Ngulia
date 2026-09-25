# Scripts

Run R scripts from the repository root so `here::here()` resolves the project. Scripts are linear and expose intermediate objects for interactive work. Install required packages with [`setup/`](setup/README.md), then use the run order in [the dataset guide](../docs/dataset.md).

| Folder | Role |
| --- | --- |
| [`curated/`](curated/README.md) | Build canonical CSVs from source material. |
| [`intermediate/`](intermediate/README.md) | Assemble daily context, model mist, and stage geolocator paths. |
| [`diagnostics/`](diagnostics/README.md) | Inspect source reconciliation and data quality. |
| [`exploration/`](exploration/README.md) | Describe the dataset without fitting question-specific models. |
| [`exports/`](exports/README.md) | Build citation, website, Zenodo, and GBIF deliveries. |
| [`helpers/`](helpers/README.md) | Shared code sourced by the runnable scripts. |

Question-specific modeling is maintained in [ngulia-analysis](https://github.com/A-Rocha-Kenya/ngulia-analysis).
