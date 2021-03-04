source(args$fun)
x <- readRDS(args$sce)
y <- fun(x)
saveRDS(y, args$est)