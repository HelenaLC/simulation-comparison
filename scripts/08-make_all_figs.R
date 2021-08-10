figs <- list.files("scripts", "fig_", full.names = TRUE)
for (s in figs) { print(basename(s)); source(s) }
