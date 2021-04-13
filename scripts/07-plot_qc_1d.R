suppressPackageStartupMessages({
    library(dplyr)
    library(tidyr)
})

source(args$fun)
df <-  .read_res(args$res)

if (all(df$group == "global")) {
    x <- "method"
    thm <- theme(axis.text.x = element_blank())
} else {
    x <- "id"
    thm <- theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

height <- 6
width <- 15
y <- "value"
col <- "method"

plt <- ggplot(df, 
    aes_string(x, y, col = col, fill = col)) +
    facet_wrap(~ metric, nrow = 2, scales = "free_y") +
    geom_boxplot(
        alpha = 0.25, width = 0.75, size = 0.25, 
        key_glyph = "point", outlier.size = 0.1) +
    scale_fill_manual(NULL, values = .methods_pal) +
    scale_color_manual(NULL, values = .methods_pal) 
thm <- thm + theme(
    axis.title = element_blank(),
    axis.ticks.x = element_blank())

p <- .prettify(plt, thm)
ggsave(args$fig, p, width = width, height = height, units = "cm")
