source(args$fun)

if (isTRUE(is.na(qc))) {
    df <- NA
} else {
    ss <- strsplit(wcs$refset, "\\.")[[1]]
    method <- ifelse(is.null(wcs$method), "ref", wcs$method)
    df <- data.frame(
        datset = ss[1],
        subset = ss[2],
        refset = wcs$refset, 
        type = wcs$type, 
        metric = wcs$metric, 
        method, qc)
    print(head(df))
}
saveRDS(df, args$res)