suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

res <- lapply(args[[1]], readRDS)

# filter out missing results
nan <- vapply(res, function(.) 
  !isTRUE(is.na(.)), logical(1))
res <- res[nan]

res <- bind_rows(res)
print(head(res))

saveRDS(res, args[[2]])