suppressPackageStartupMessages(library(dplyr))

x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)

if (isTRUE(is.na(x)) || 
    isTRUE(is.na(y))) {
  res <- NA
} else {
  source(args$fun)

  df <- x %>%
    rename(x = paste(wcs$type, wcs$metric1, sep = "_")) %>%
    mutate(y = y[[paste(wcs$type,  wcs$metric2, sep = "_")]])
  xy <- c("x", "y")
  
  sub <- df[sample(nrow(df), min(1e3, nrow(df))), ]
  
  res <- df %>% 
      group_by(group, id) %>% 
      group_map(.keep = TRUE, ~{
          df <- group_by(.x, .x$method)
          dfs <- setNames(
              group_split(df),
              group_keys(df)[[1]])
          
          idx <- which(names(dfs) == "ref")
          ref <- dfs[[idx]]
          
          res <- lapply(dfs[-idx], function(sim) {
              stat <- tryCatch(
                  error = function(e) NA,
                  fun(ref[, xy], sim[, xy]))
              data.frame(stat)
          })
          res <- bind_rows(res, .id = "method")
          cbind(.x[1, c("group", "id")], res)
      }) %>% bind_rows()
  res <- data.frame(wcs, res)
}

print(res)
saveRDS(res, args$res)
