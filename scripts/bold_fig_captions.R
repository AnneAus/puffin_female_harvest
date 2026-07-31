# Quarto's docx writer injects the crossref "Fig. N." prefix directly into
# the rendered OOXML, after all Lua filters have already run - so it can't be
# targeted from the .qmd/crossref config alone. This post-processes the
# rendered manuscript.docx, bolding just the "Fig. N." prefix of each figure
# caption (paragraphs styled "ImageCaption") and leaving the rest of the
# caption text at whatever weight the author gave it.
# Run this after every `quarto render manuscript/manuscript.qmd`.
library(xml2)

docx_path <- "../manuscript/manuscript.docx"
tmp_dir <- tempfile("docx_unzip_")
dir.create(tmp_dir)

utils::unzip(docx_path, exdir = tmp_dir)
doc_path <- file.path(tmp_dir, "word", "document.xml")

ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
doc <- read_xml(doc_path)

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
prefix_pattern <- paste0("^", space_class, "*Fig\\.", space_class, "*[0-9]+\\.")

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

write_xml(doc, doc_path)

out_zip <- tempfile(fileext = ".docx")
old_wd <- setwd(tmp_dir)
utils::zip(out_zip, list.files(".", recursive = TRUE), flags = "-q -X -D -r")
setwd(old_wd)

file.copy(out_zip, docx_path, overwrite = TRUE)
unlink(tmp_dir, recursive = TRUE)
unlink(out_zip)

cat("Bolded 'Fig. N.' prefixes in", length(caption_paras), "figure caption(s).\n")
