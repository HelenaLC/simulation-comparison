source(args$fun)

sce <- readRDS(args$sce)
res <- fun(sce)

saveRDS(res, args$res)
