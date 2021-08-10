suppressPackageStartupMessages({
    library(dplyr)
    library(purrr)
    library(tidyr)
})

x <- lapply(args$x, readRDS) %>% bind_rows()
y <- lapply(args$y, readRDS) %>% bind_rows()

# check that QCs are available for reference & simulation
res <- if (!(all(is.na(x$method)) || all(is.na(y$method)))) {
    # source evaluation function
    source(args$fun)
    # for each grouping, test simulation vs. reference
    list(x = x, y = y) %>% 
    bind_rows(.id = "dim") %>% 
    pivot_wider(
        id_cols = c("group", "id"),
        names_from = c("dim", "method"),
        values_from = "value",
        values_fn = list) %>% 
    rename_at(
        vars(contains("NA")),
        function(.) gsub("NA", "ref", .)) %>% 
    rename_at(
        vars(contains(wcs$method)), 
        function(.) gsub(wcs$method, "sim", .)) %>% 
    rowwise() %>% 
    mutate(stat = fun(
        cbind(x_ref, y_ref),
        cbind(x_sim, y_sim))) %>% 
    ungroup() %>% 
    select_if(negate(is.list)) %>% 
    mutate(.before = 1, data.frame(wcs))
}

print(head(res))
saveRDS(res, args$res)
