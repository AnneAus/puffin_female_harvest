# Pre-breeding Atlantic puffins (*Fratercula arctica*) are disappearing from Faroese colonies

Research compendium for a study of a 20-year (1989–2008) dataset of legally harvested Atlantic puffins from Nólsoy and Mykines, Føroyar (the Faroe Islands), testing whether birds of confirmed breeding age were increasingly represented in the harvest over time.

## Abstract

Ongoing climate change and increasing human-induced environmental change are causing substantial declines in seabirds. The Atlantic puffin (*Fratercula arctica*; hereafter puffin) is one such species, experiencing declines across its north Atlantic range. While much of the decline in puffins is indirect, for example due to reduced food availability causing large-scale breeding failure, direct threats such as hunting may push already struggling populations over the edge. At the same time, samples from harvested puffins provide a unique opportunity to dissect and analyse a healthy segment of the population. Here, we analysed 13 years (1995–2008) of data on female puffins harvested in *Føroyar* to determine whether the ratio of confirmed breeders (i.e., those females with 'convoluted' oviducts, indicating that they had laid an egg at least once in their lifetime) in the harvested sample increased over time. We also scored brood patch as a proxy for ongoing breeding in the sample year, as the harvest was carried out well into the chick-rearing period and hormonal brood patches (without an active breeding attempt) should have disappeared. We found that the ratio of confirmed breeders increased from approximately 15% in the earlier study years to 78% in 2008, and that within birds without a brood patch, the ratio of confirmed breeders increased as well. Together, we showed that young, pre-breeding birds disappeared from the sample, suggesting a severe lack of recruitment. While the hunt is unlikely to be the main driver of the population decline in *Føroyar*, even reduced harvesting is likely unsustainable under current conditions.

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
│   └── bold_fig_captions.R
├── references.bib          # bibliography
├── Marine_Ornithology.csl  # citation style for the target journal
└── MO_reference_doc.docx / MO_Styles_Template_APA.docx  # Marine Ornithology submission templates
```

## Data

`data/data.rds` (and its plain-text equivalent `data/data.csv`) contain per-individual records for 5,472 puffins sampled from the harvest (1989–2008): sampling `date`, `sex`, breeding status (`bred`, from oviduct examination, scored from 1995 onward), brood patch presence (`brood.spot`), and `year`. `data/harvest.csv` holds the annual estimated total harvest size and the number of individuals sampled per year.

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

If you use this code or data, please cite the associated manuscript (details to be added on publication) and/or this repository — see `CITATION.cff` (GitHub's "Cite this repository" button uses this automatically), or the archived Zenodo record: [10.5281/zenodo.21780561](https://doi.org/10.5281/zenodo.21780561).

## License

Code and data are released under the [MIT License](LICENSE).
