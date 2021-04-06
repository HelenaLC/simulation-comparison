res <- lapply(args[[1]], readRDS)
df <- dplyr::bind_rows(res)
print(head(df))
saveRDS(df, args[[2]])