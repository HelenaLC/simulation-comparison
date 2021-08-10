x <- readRDS(args$sub)

source(args$fun)
y <- fun(x)

saveRDS(y, args$est)