source(args$fun)
fns <- readLines(args$txt)
res <- .read_res(fns)
saveRDS(res, args$rds)