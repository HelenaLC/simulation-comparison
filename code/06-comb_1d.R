suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

res <- lapply(args[[1]], readRDS)

# filter out missing results
nan <- vapply(res, function(.) 
  !isTRUE(is.na(.)), logical(1))
res <- res[nan]

res <- bind_rows(res) %>% 
    rowwise() %>% 
    mutate(
        datset = strsplit(refset, "\\.")[[1]][1],
        subset = strsplit(refset, "\\.")[[1]][2]) %>% 
    ungroup() %>% 
    mutate(
        group_id = paste(group, id, sep = "_"),
        type_metric = paste(type, metric, sep = "_"))
    
print(head(res))

saveRDS(res, args[[2]])