suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(tidyr)
})

df <- readRDS(args$res)
df <- df %>% gather(-dr_method, 
                    -dimensionality,
                    -method, 
                    -group, 
                    -id, 
                    -refset, 
                    key = "stat_method", 
                    value = "stat" )


p <- ggplot(df, aes(x = method, y = stat, color=method)) +
        geom_point() +
        facet_wrap(~ stat_method, scales = "free") +
        .prettify()+
        ggtitle(wcs$refset)+
        theme(axis.text.x = element_blank())

ggsave(args$fig, p, width = 15, height = 15, units = "cm")