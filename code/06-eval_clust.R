source("code/utils-plotting.R")

sce <- readRDS(args$sce)
true <- droplevels(factor(sce$cluster))

res <- .read_res(
    unlist(args[c("ref", "sim")]))
    
# for each simulators & clustering method, match prediction w/ truth 
# using Hungarian algorithm & compute precision, recall, F1 score 
res <- group_by(res,
    across(contains("method"))) %>% 
    group_modify(~{
        res <- .hungarian(.x$pred, .x$true)
        data.frame(
            cluster = levels(true),
            res[c("pr", "re", "F1")])
    }) %>% data.frame(wcs)

saveRDS(res, args$res)
