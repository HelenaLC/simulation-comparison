source(args$fun)
x <- readRDS(args$sub)
y <- fun(x)
saveRDS(y, args$est)