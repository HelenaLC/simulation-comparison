fns <- basename(args[[1]])
pat <- ".*-(.*),(.*),(.*)\\.rds"
refset  <- gsub(pat, "\\1", fns)
metric1 <- gsub(pat, "\\2", fns)
metric2 <- gsub(pat, "\\3", fns)

res <- lapply(args[[1]], readRDS)
ns <- vapply(res, function(.) 
    ifelse(isTRUE(is.na(.)), 0, nrow(.)), 
    numeric(1))

df <- do.call(rbind, res)
df <- df[rowSums(is.na(df)) != ncol(df), ]

df$refset <- rep(refset, ns)
df$metric1 <- rep.int(metric1, ns)
df$metric2 <- rep.int(metric2, ns)

saveRDS(df, args[[2]])