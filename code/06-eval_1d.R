suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# read in QC results for reference & simulation
ref <- readRDS(args$ref)
sim <- readRDS(args$sim)

if (is.null(ref) || is.null(sim)) {
  res <- NULL
} else {
  # source test statistic function
  source(args$fun)
  # for each grouping, test simulation vs. reference
  df <- bind_rows(ref, sim) %>% 
    pivot_wider(
      names_from = "method", 
      values_from = "value", 
      values_fn = list) %>% 
    rename(sim = wcs$method)
  df$stat <- apply(df, 1, 
    function(.) fun(.$ref, .$sim))
  # add metadata
  ss <- strsplit(wcs$refset, "\\.")[[1]]
  res <- data.frame(wcs, df) %>% 
    mutate(.before = refset, datset = ss[1], subset = ss[2]) %>% 
    mutate(.after = id, group.id = paste(group, id, sep = ".")) %>% 
    mutate(.after = metric, type.metric = paste(type, metric, sep = "."))
}

print(head(res))
saveRDS(res, args$res)
