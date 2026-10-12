# Quarto's docx writer injects the crossref "Fig. N." prefix directly into
# the rendered OOXML, after all Lua filters have already run - so it can't be
# targeted from the .qmd/crossref config alone. This post-processes the
# rendered manuscript.docx, bolding just the "Fig. N." prefix of each figure
# caption (paragraphs styled "ImageCaption") and leaving the rest of the
# caption text at whatever weight the author gave it.
# Run this after every `quarto render manuscript/manuscript.qmd`.
#
# It also applies the Marine Ornithology table layout that the template alone
# can't produce: the "Table N" label goes bold on its own line above the title
# (Quarto puts label and title in one paragraph), and a rule is added under the
# last row of each table (the header rules come from the template's "Table"
# style, but a bottom border on that style would also box every figure, since
# Quarto wraps figures and tables in a layout table with the same style).
#
# Optionally pass the docx path: Rscript bold_fig_captions.R path/to/file.docx
library(xml2)

args <- commandArgs(trailingOnly = TRUE)
docx_path <- if (length(args) > 0) args[[1]] else "../manuscript/manuscript.docx"
tmp_dir <- tempfile("docx_unzip_")
dir.create(tmp_dir)

utils::unzip(docx_path, exdir = tmp_dir)
doc_path <- file.path(tmp_dir, "word", "document.xml")

ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
doc <- read_xml(doc_path)

# --- Merge duplicate paragraph properties in captions ---
# Quarto writes two <w:pPr> blocks into caption paragraphs: one centring the
# caption and one with the ImageCaption style and left alignment. That's invalid
# OOXML, and Word resolves it unpredictably. Merge into a single block (keeping
# the centring) with children in schema order.
ppr_order <- c("pStyle", "keepNext", "keepLines", "pageBreakBefore", "framePr",
               "widowControl", "numPr", "suppressLineNumbers", "pBdr", "shd",
               "tabs", "suppressAutoHyphens", "kinsoku", "wordWrap",
               "overflowPunct", "topLinePunct", "autoSpaceDE", "autoSpaceDN",
               "bidi", "adjustRightInd", "snapToGrid", "spacing", "ind",
               "contextualSpacing", "mirrorIndents", "suppressOverlap", "jc",
               "textDirection", "textAlignment", "textboxTightWrap",
               "outlineLvl", "divId", "cnfStyle", "rPr", "sectPr", "pPrChange")

sort_ppr <- function(ppr) {
  kids <- xml_children(ppr)
  if (length(kids) < 2) return(invisible())
  rank <- match(xml_name(kids), ppr_order, nomatch = length(ppr_order))
  for (k in kids[order(rank)]) {
    xml_add_child(ppr, k)  # appends a copy in sorted order
  }
  for (k in kids) xml_remove(k)
}

for (p in xml_find_all(doc, ".//w:p[count(w:pPr) > 1]", ns)) {
  pprs <- xml_find_all(p, "./w:pPr", ns)
  keep <- pprs[[1]]
  have <- xml_name(xml_children(keep))
  for (extra in pprs[-1]) {
    for (k in xml_children(extra)) {
      if (!(xml_name(k) %in% have)) {
        xml_add_child(keep, k)
        have <- c(have, xml_name(k))
      }
    }
    xml_remove(extra)
  }
  sort_ppr(keep)
}

caption_paras <- xml_find_all(
  doc,
  ".//w:p[w:pPr/w:pStyle[@w:val='ImageCaption']]",
  ns
)

# Quarto separates "Fig." and the number with a non-breaking space (U+00A0),
# not a regular space - built via intToUtf8() rather than typed literally so
# it's correct regardless of source-file/locale encoding.
nbsp <- intToUtf8(0xA0)
space_class <- paste0("[ ", nbsp, "]")
prefix_pattern <- paste0("^", space_class, "*Fig\\.", space_class, "*S?[0-9]+\\.")

# --- Supplementary labels: "Fig. S 1." / "Table S 1." -> "Fig. S1." / "Table S1" ---
# Quarto puts a (non-breaking) space between a "Fig. S"/"Table S" title and the
# number, sometimes in the same run and sometimes split across two runs.
label_s_end <- paste0("(Fig\\.|Table)", space_class, "*S$")
label_s_gap <- paste0("((Fig\\.|Table)", space_class, "*S)", space_class, "+([0-9])")
label_paras <- xml_find_all(
  doc,
  paste0(".//w:p[w:pPr/w:pStyle[@w:val='ImageCaption']] | ",
         ".//w:tbl[w:tblPr/w:tblLook[@w:firstRow='0']]/w:tr/w:tc/w:p"),
  ns
)
for (p in label_paras) {
  t_nodes <- xml_find_all(p, "./w:r/w:t", ns)
  if (length(t_nodes) == 0) next
  for (i in seq_along(t_nodes)) {
    txt <- xml_text(t_nodes[[i]])
    new <- sub(label_s_gap, "\\1\\3", txt)
    if (grepl(label_s_end, new) && i < length(t_nodes)) {
      nxt <- xml_text(t_nodes[[i + 1]])
      xml_set_text(t_nodes[[i + 1]], sub(paste0("^", space_class, "+(?=[0-9])"), "", nxt, perl = TRUE))
    }
    if (!identical(new, txt)) xml_set_text(t_nodes[[i]], new)
  }
}

for (p in caption_paras) {
  runs <- xml_find_all(p, "./w:r", ns)
  if (length(runs) == 0) next

  full_text <- paste0(sapply(runs, function(r) {
    t <- xml_find_first(r, "./w:t", ns)
    if (is.na(t)) "" else xml_text(t)
  }), collapse = "")

  m <- regmatches(full_text, regexpr(prefix_pattern, full_text))
  if (length(m) == 0) next
  prefix_len <- nchar(m)

  consumed <- 0
  for (r in runs) {
    if (consumed >= prefix_len) break
    t_node <- xml_find_first(r, "./w:t", ns)
    if (is.na(t_node)) next
    run_text <- xml_text(t_node)
    run_len <- nchar(run_text)

    if (consumed + run_len <= prefix_len) {
      # run lies entirely within the "Fig. N." prefix - make it bold
      rpr <- xml_find_first(r, "./w:rPr", ns)
      if (is.na(rpr)) {
        rpr <- xml_add_child(r, "w:rPr", .where = 0)
      }
      if (is.na(xml_find_first(rpr, "./w:b", ns))) xml_add_child(rpr, "w:b")
      if (is.na(xml_find_first(rpr, "./w:bCs", ns))) xml_add_child(rpr, "w:bCs")
    } else {
      # run straddles the boundary - split it into a bold prefix part and an
      # untouched remainder, preserving the remainder's original formatting
      split_at <- prefix_len - consumed
      prefix_part <- substr(run_text, 1, split_at)
      remainder_part <- substr(run_text, split_at + 1, run_len)

      xml_set_text(t_node, prefix_part)
      rpr <- xml_find_first(r, "./w:rPr", ns)
      if (is.na(rpr)) {
        rpr <- xml_add_child(r, "w:rPr", .where = 0)
      }
      if (is.na(xml_find_first(rpr, "./w:b", ns))) xml_add_child(rpr, "w:b")
      if (is.na(xml_find_first(rpr, "./w:bCs", ns))) xml_add_child(rpr, "w:bCs")

      # the remainder keeps no explicit rPr, matching how these auto-generated
      # runs were originally un-styled (inheriting the paragraph default)
      new_run <- xml_add_sibling(r, "w:r", .where = "after")
      new_t <- xml_add_child(new_run, "w:t", remainder_part)
      xml_set_attr(new_t, "xml:space", "preserve")
    }
    consumed <- consumed + run_len
  }
}

# --- Table captions: "Table N. Title" -> bold "Table N" line + "Title" line ---
tbl_prefix_pattern <- paste0("^", space_class, "*Table", space_class, "*S?[0-9]+")
tbl_full_pattern <- paste0(tbl_prefix_pattern, "\\.?", space_class, "*")

n_tbl_captions <- 0
# only caption paragraphs sitting directly in Quarto's layout wrapper tables
wrapper_paras <- xml_find_all(
  doc,
  ".//w:tbl[w:tblPr/w:tblLook[@w:firstRow='0']]/w:tr/w:tc/w:p",
  ns
)
for (p in wrapper_paras) {
  runs <- xml_find_all(p, "./w:r", ns)
  if (length(runs) == 0) next
  run_texts <- sapply(runs, function(r) {
    t <- xml_find_first(r, "./w:t", ns)
    if (is.na(t)) "" else xml_text(t)
  })
  full_text <- paste0(run_texts, collapse = "")
  m <- regmatches(full_text, regexpr(tbl_full_pattern, full_text))
  if (length(m) == 0) next
  label <- regmatches(full_text, regexpr(tbl_prefix_pattern, full_text))
  label <- trimws(gsub(nbsp, " ", label))

  # new label paragraph, same paragraph properties, kept with the title
  label_p <- xml_add_sibling(p, "w:p", .where = "before")
  ppr <- xml_find_first(p, "./w:pPr", ns)
  if (!is.na(ppr)) xml_add_child(label_p, ppr)
  label_ppr <- xml_find_first(label_p, "./w:pPr", ns)
  if (is.na(label_ppr)) label_ppr <- xml_add_child(label_p, "w:pPr")
  if (is.na(xml_find_first(label_ppr, "./w:keepNext", ns))) {
    xml_add_child(label_ppr, "w:keepNext")
    sort_ppr(label_ppr)
  }
  label_r <- xml_add_child(label_p, "w:r")
  label_rpr <- xml_add_child(label_r, "w:rPr")
  xml_add_child(label_rpr, "w:b")
  xml_add_child(label_rpr, "w:bCs")
  xml_add_child(label_r, "w:t", label)

  # strip "Table N. " from the start of the original paragraph's runs
  to_remove <- nchar(m)
  for (i in seq_along(runs)) {
    if (to_remove <= 0) break
    t_node <- xml_find_first(runs[[i]], "./w:t", ns)
    if (is.na(t_node)) next
    run_text <- xml_text(t_node)
    if (nchar(run_text) <= to_remove) {
      to_remove <- to_remove - nchar(run_text)
      xml_remove(runs[[i]])
    } else {
      xml_set_text(t_node, substr(run_text, to_remove + 1, nchar(run_text)))
      xml_set_attr(t_node, "xml:space", "preserve")
      to_remove <- 0
    }
  }
  n_tbl_captions <- n_tbl_captions + 1
}

# --- Bottom rule under the last row of each data table ---
# Data tables are the ones with a header row (tblLook firstRow = 1); Quarto's
# layout wrappers around figures and tables have firstRow = 0.
data_tbls <- xml_find_all(doc, ".//w:tbl[w:tblPr/w:tblLook[@w:firstRow='1']]", ns)
tcpr_before_borders <- c("cnfStyle", "tcW", "gridSpan", "hMerge", "vMerge")
for (tbl in data_tbls) {
  rows <- xml_find_all(tbl, "./w:tr", ns)
  if (length(rows) < 2) next
  for (tc in xml_find_all(rows[[length(rows)]], "./w:tc", ns)) {
    tcpr <- xml_find_first(tc, "./w:tcPr", ns)
    if (is.na(tcpr)) tcpr <- xml_add_child(tc, "w:tcPr", .where = 0)
    borders <- xml_find_first(tcpr, "./w:tcBorders", ns)
    if (is.na(borders)) {
      kids <- xml_children(tcpr)
      pos <- sum(cumprod(xml_name(kids) %in% tcpr_before_borders))
      borders <- xml_add_child(tcpr, "w:tcBorders", .where = pos)
    }
    old <- xml_find_first(borders, "./w:bottom", ns)
    if (!is.na(old)) xml_remove(old)
    xml_add_child(borders, "w:bottom", "w:val" = "single", "w:sz" = "4",
                  "w:space" = "0", "w:color" = "auto")
  }
}

write_xml(doc, doc_path, options = "as_xml")  # no pretty-printing

out_zip <- tempfile(fileext = ".docx")
old_wd <- setwd(tmp_dir)
# all.files = TRUE is essential: without it "_rels/.rels" (a dot-file) is left
# out of the zip and Word reports the document as unreadable
utils::zip(out_zip, list.files(".", recursive = TRUE, all.files = TRUE),
           flags = "-q -X -D -r")
setwd(old_wd)

file.copy(out_zip, docx_path, overwrite = TRUE)
unlink(tmp_dir, recursive = TRUE)
unlink(out_zip)

cat("Bolded 'Fig. N.' prefixes in", length(caption_paras), "figure caption(s).\n")
cat("Split", n_tbl_captions, "table label(s) onto their own line;",
    "added bottom rules to", length(data_tbls), "table(s).\n")
