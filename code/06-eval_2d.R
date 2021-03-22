suppressPackageStartupMessages(library(dplyr))

x <- .read_res(args$x_ref, args$x_sim)
y <- .read_res(args$y_ref, args$y_sim)

if (isTRUE(is.na(x)) || 
    isTRUE(is.na(y)) || 
    nrow(x) != nrow(y)) {
  res <- NA
} else {
  source(args$fun)

  df <- x %>%
    rename(x = paste(wcs$type, wcs$metric1, sep = "_")) %>%
    mutate(y = y[[paste(wcs$type,  wcs$metric2, sep = "_")]])
  xy <- c("x", "y")
  
  sub <- df[sample(nrow(df), 1e3), ]
  
  res <- sub %>% 
      group_by(group, id) %>% 
      group_map(.keep = TRUE, ~{
          df <- group_by(.x, .x$method)
          dfs <- setNames(
              group_split(df),
              group_keys(df)[[1]])
          
          idx <- which(names(dfs) == "reference")
          ref <- dfs[[idx]]
      
          res <- lapply(dfs[-idx], function(sim)
              data.frame(stat = fun(ref[, xy], sim[, xy])))
              
          res <- bind_rows(res, .id = "method")
          cbind(.x[1, c("group", "id")], res)
      }) %>% bind_rows()
}

print(res)
saveRDS(res, args$res)
