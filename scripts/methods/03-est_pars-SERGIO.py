from SERGIO.SERGIO import sergio
# from SERGIO import sergio
import numpy as np
import pandas as pd

# import sys
# print(sys.path)
# DEMO
def simulate():
    sim = sergio.sergio(number_genes=100,
                 number_bins=9,
                 number_sc=300,
                 noise_params=1,
                 decays=0.8,
                 sampling_state=15,
                 noise_type='dpd')


    sim.build_graph(input_file_taregts="/Users/sarahmorillo/anaconda3/envs/sim_comp/lib/python3.8/site-packages/SERGIO/Demo/steady-state_input_GRN.txt",
                    input_file_regs='/Users/sarahmorillo/anaconda3/envs/sim_comp/lib/python3.8/site-packages/SERGIO/Demo/steady-state_input_MRs.txt',
                    shared_coop_state=2)
    sim.simulate()
    expr = sim.getExpressions()
    expr_clean_ss = np.concatenate(expr, axis=1)
    return expr_clean_ss

