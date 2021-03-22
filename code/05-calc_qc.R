source(args$fun)

if (is.na(qc)) {
    df <- NA
} else {
    method <- ifelse(is.null(wcs$method), "ref", wcs$method)
    df <- data.frame(
        refset = wcs$refset, 
        subset = names(wcs)[2], 
        type = wcs$type, 
        metric = wcs$metric, 
        method, qc)
    print(head(df))
}
saveRDS(df, args$res)