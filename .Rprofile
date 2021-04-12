source("scripts/utils.R")
data.table::setDTthreads(threads = 1)

.get_wcs <- function(wcs) {
	wcs <- gsub("(,)(\\w+=)", ";\\2", wcs)
    ss <- strsplit(wcs, ";")[[1]]
    ss <- sapply(ss, strsplit, "=")
    keys <- sapply(ss, .subset, 1)
    vals <- sapply(ss, .subset, 2)
	wcs <- as.list(vals)
	names(wcs) <- keys
    return(wcs)
}

args <- R.utils::commandArgs(
	trailingOnly = TRUE, 
	asValues = TRUE)
print(args$wcs)
if (!is.null(args$wcs)) {
	wcs <- .get_wcs(args$wcs)
	args$wcs <- NULL
} else wcs <- NULL

args <- lapply(args, function(u) 
	unlist(strsplit(u, ";")))

cat("WILDCARDS:\n\n"); print(wcs); cat("\n")
cat("ARGUMENTS:\n\n"); print(args)
