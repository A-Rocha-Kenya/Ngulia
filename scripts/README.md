# Scripts

Run scripts from the repository root so `here::here()` resolves this project. The R workflow is linear and exposes intermediate objects for interactive inspection. Install packages with `Rscript scripts/setup/01_install_dependencies.R`; the full run order is in the [dataset guide](../docs/dataset.md).

| Folder | Role |
| --- | --- |
| `curated/` | Build the canonical CSV tables from source material. |
| `intermediate/` | Assemble daily context, model mist, and stage geolocator paths. |
| `diagnostics/` | Inspect source reconciliation and data quality without altering curated tables. |
| `exploration/` | Describe the dataset without fitting question-specific models. |
| `exports/` | Build citation, website, Zenodo, and GBIF deliveries. |
| `helpers/` | Shared code sourced by runnable scripts. |
| `setup/` | Install declared R dependencies. |

Question-specific modeling is maintained in [ngulia-analysis](https://github.com/A-Rocha-Kenya/ngulia-analysis). Generated results are described in [`outputs/`](../outputs/README.md) and [`exports/`](../exports/README.md).
