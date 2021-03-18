suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})
res <- lapply(args$ref, readRDS)
# filter out results that are non existent, i.e. are NA
res <- res[vapply(res, function(.) 
  !isTRUE(is.na(.)), logical(1))]

res <- bind_rows(res)
print(res)

saveRDS(res, args$res)