suppressPackageStartupMessages({
  library(dyngen)
})

fun <- function(x){
   
  backbone <- backbone_bifurcating_loop()
  num_cells <- ncol(x)
  num_feats <- nrow(x)
  num_tfs <- nrow(backbone$module_info)
  num_tar <- round((num_feats - num_tfs) / 2)
  num_hks <- num_feats - num_tfs - num_tar
  
  config <-
    initialise_model(
      backbone = backbone,
      num_cells = num_cells,
      num_tfs = num_tfs,
      num_targets = num_tar,
      num_hks = num_hks,
      gold_standard_params = gold_standard_default(),
      simulation_params = simulation_default(
        total_time = 1000,
        experiment_params = simulation_type_wild_type(num_simulations = 1)
      ),
      experiment_params = experiment_snapshot(
        realcount = counts(x)
      ),
      verbose = FALSE
    )
  return(config)
}