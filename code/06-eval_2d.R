suppressPackageStartupMessages({
    library(dplyr)
    library(purrr)
    library(tidyr)
})

x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)

if (is.null(x) || is.null(y)) {
    res <- NULL
} else {
    # source evaluation function
    source(args$fun)
    # for each grouping, test simulation vs. reference
    df <- list(x = x, y = y) %>% 
        bind_rows(.id = "dim") %>% 
        pivot_wider(
            id_cols = c("group", "id"),
            names_from = c("dim", "method"),
            values_from = "value",
            values_fn = list) %>% 
        rename_at(
            vars(contains(wcs$method)), 
            function(.) gsub(wcs$method, "sim", .))
    stat <- apply(df, 1, function(.)
        fun(cbind(.$x_ref, .$y_ref),
            cbind(.$x_sim, .$y_sim)))
    df <- mutate(df, stat) %>% 
        select_if(negate(is.list)) %>% 
        mutate(select(x[1, ], -c(method, value)))    
    # add metadata
    ss <- strsplit(wcs$refset, "\\.")[[1]]
    res <- data.frame(wcs, df) %>% 
        mutate(.before = refset, datset = ss[1], subset = ss[2]) %>% 
        mutate(.after = id, group.id = paste(group, id, sep = ".")) %>% 
        mutate(.after = metric1, type.metric1 = paste(type, metric1, sep = ".")) %>% 
        mutate(.after = metric2, type.metric2 = paste(type, metric2, sep = "."))
}

print(head(res))
saveRDS(res, args$res)
