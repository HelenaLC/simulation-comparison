pat <- paste0("^", wcs$pat)
fns <- list.files("outs", pat, full.names = TRUE)
writeLines(fns, args$txt)