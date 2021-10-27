x <- readRDS(args$sub)

source(args$fun)
y <- tryCatch(fun(x),
    error = function(e) NA)

saveRDS(y, args$est)