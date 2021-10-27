suppressPackageStartupMessages({
    library(dplyr)
    library(tidyr)
})

source(args$uts)

sce <- readRDS(args$sce)
true <- droplevels(factor(sce$cluster))

res <- args[c("ref", "sim")] %>% 
    unlist() %>% 
    lapply(readRDS) %>% 
    bind_rows() %>% 
    replace_na(list(method = "ref"))
    
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
