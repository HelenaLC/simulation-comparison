x <- readRDS(args$est)
if (is.null(x))
    x <- readRDS(args$sub)

source(args$fun)
y <- fun(x)

saveRDS(y, args$sim)