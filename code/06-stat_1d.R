suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(tidyr)
})

# read in QC results for reference (ref) & simulation (sim)
ref <- readRDS(args$ref)
sim <- readRDS(args$sim)

# check that QC is available for reference & simulation
res <- if (!(is.null(ref) || is.null(sim))) {
  # source test statistic function
  source(args$fun)
  # test ref vs. sim for each grouping
  bind_rows(ref, sim) %>% 
    pivot_wider(
      names_from = "method", 
      values_from = "value", 
      values_fn = list) %>% 
    rename(
      ref = "NA", 
      sim = wcs$method) %>% 
    rowwise() %>% 
    mutate(stat = fun(ref, sim)) %>% 
    ungroup() %>% 
    select(negate(is.list)) %>% 
    mutate(.before = 1, data.frame(wcs))
}

print(head(res))
saveRDS(res, args$res)
