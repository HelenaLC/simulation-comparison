suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

df <- .read_res(args$ref, args$sim)
type_metric <- paste(wcs$type, wcs$metric, sep = "_")

if (isTRUE(is.na(df))) {
  res <- NA
} else {
  source(args$fun)
  df <- group_by(df, group, id)
  res <- group_map(df, ~{
    df <- group_by(.x, method)
    dfs <- setNames(
      group_split(df), 
      group_keys(df)[[1]])
    i <- which(names(dfs) == "ref")
    vapply(dfs[-i], function(sim) 
      fun(sim[[type_metric]], 
          dfs[[i]][[type_metric]]),
      numeric(1))
  })
  res <- data.frame(
    group_keys(df), 
    t(data.frame(res))) %>% 
    pivot_longer(
      cols = -c(group, id), 
      names_to = "method", 
      values_to = "stat")
  res <- data.frame(wcs, res)
}

print(head(res))
saveRDS(res, args$res)
