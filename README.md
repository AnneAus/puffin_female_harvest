# Pre-breeding Atlantic Puffins *Fratercula arctica* are disappearing from Faroese colonies

Research compendium for a study of a 20-year (1989–2008) dataset of legally harvested Atlantic puffins from Nólsoy and Mykines, Føroyar (the Faroe Islands), testing whether birds of confirmed breeding age were increasingly represented in the harvest over time.

## Abstract

Ongoing climate change and increasing human-induced environmental change are causing substantial declines in seabirds. The Atlantic Puffin *Fratercula arctica* (hereafter puffin) is one such species, experiencing declines across its North Atlantic range. While much of the declines in puffins are indirect, for example due to reduced food availability causing large-scale breeding failure, direct threats such as hunting may push already struggling populations over the edge. At the same time, samples from harvested puffins provide a unique opportunity to dissect and analyse a healthy segment of the population. Here, we analysed 13 yr (1995–2008) of data on female puffins harvested in *Føroyar* (Eng. the Faroe Islands) to determine whether the proportion of confirmed breeders (i.e., those females with 'convoluted' oviducts, indicating that they had laid an egg at least once in their lifetime) in the harvested sample increased over time. We also scored brood patch presence as a proxy for ongoing breeding in the sample year, as the harvest was carried out well into the chick rearing period and hormonal brood patches (without active breeding attempt) should have disappeared. We found that the observed proportion of confirmed breeders increased from approximately 15% in the earlier study years to 78% in 2008, and that within birds without brood patches, the proportion of confirmed breeders increased as well. Together, we showed that the representation of young, pre-breeding female birds declined in the sample, suggesting a substantial decline in recruitment. While the hunt is unlikely to be the main driver of the population decline in *Føroyar*, even reduced harvesting is likely unsustainable under current global conditions.

**Key words:** demographics, seabirds, traditional harvest, recruitment, brood patch, seabird conservation

## Repository structure

```
├── manuscript/
│   ├── manuscript.qmd      # main manuscript (Quarto), renders to manuscript.docx
│   ├── appendix.qmd        # supplementary information, renders to appendix.docx
│   └── *.docx              # rendered output (tracked so reviewers can open without Quarto)
├── data/
│   ├── data.rds            # individual-level records used in the analysis (n = 5472, 1989-2008)
│   ├── data.csv            # same records, plain-text/CSV form
│   ├── harvest.csv         # annual estimated harvest totals and sample sizes
│   └── faroe_coastline.gpkg # cached high-resolution coastline for the study-site map
├── output/                 # cached brms model fits (.rds); re-used on render unless inputs change
├── figures/                # rendered figure files
├── scripts/
│   ├── get_faroe_coastline.R  # (re-)fetches the coastline from OpenStreetMap; not run on render
│   ├── bold_fig_captions.R
│   └── flag_uncertain_dates.R  # adds date_uncertain/date_note flags to data/data.rds and data.csv
├── references.bib          # bibliography
├── Marine_Ornithology.csl  # citation style for the target journal
└── MO_reference_doc.docx / MO_Styles_Template_APA.docx  # Marine Ornithology submission templates
```

## Data

`data/data.rds` (and its plain-text equivalent `data/data.csv`) contain per-individual records for 5,472 puffins sampled from the harvest (1989–2008): sampling `date`, `sex`, breeding status (`bred`, from oviduct examination, scored from 1995 onward), brood patch presence (`brood.spot`), and `year`.

**Uncertain sampling dates.** For 45 records the day and month of sampling are uncertain; these are flagged with `date_uncertain = TRUE`, with the reason in `date_note`. The sampling **year** is correct for all records, and the analyses in this repository use year only, so they are not affected. Check these flags if you use the full date:

- **08 June 2006** (9 birds): before the start of the hunting season (02 July); a confirmed data-entry error, but the true date is unknown.
- **05 July 1998** (8 birds) and **10 July 2005** (28 birds): Sundays, when there was no puffin hunting.

The flags were added with `scripts/flag_uncertain_dates.R`; the dates themselves were left unchanged.

`data/harvest.csv` holds the annual estimated total harvest size and the number of individuals sampled per year.

## Reproducing the analysis

1. Open `puffin_female_harvest.Rproj` in RStudio.
2. Install dependencies:
   ```r
   install.packages(c("tidyverse", "brms", "bayesplot", "knitr",
                       "sf", "rnaturalearth", "rnaturalearthhires",
                       "ggrepel", "ggspatial", "patchwork"))
   remotes::install_github("grwhumphries/seabiRd")
   ```
   `brms` requires a working Stan toolchain (RStan or cmdstanr) — see the
   [brms installation guide](https://paul-buerkner.github.io/brms/) if you don't already have one set up.
3. Render the manuscript and supplementary appendix:
   ```r
   quarto::quarto_render("manuscript/manuscript.qmd")
   quarto::quarto_render("manuscript/appendix.qmd")
   ```
   Model fits are cached in `output/*.rds` and are only refit if the data or model specification changes (`file_refit = "on_change"`), so re-rendering after a text-only edit is fast.

## Citation

If you use this code or data, please cite the associated manuscript (details to be added on publication) and/or this repository — see `CITATION.cff` (GitHub's "Cite this repository" button uses this automatically), or the archived Zenodo record: [10.5281/zenodo.21780560](https://doi.org/10.5281/zenodo.21780560). This DOI always resolves to the latest version; each release also has its own DOI, listed on the Zenodo record (v1.0.0, the submitted manuscript: [10.5281/zenodo.21780561](https://doi.org/10.5281/zenodo.21780561)).

## License

Code and data are released under the [MIT License](LICENSE).
