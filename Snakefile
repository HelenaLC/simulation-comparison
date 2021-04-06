import re
import json
import itertools

configfile: "config.yaml"
R = config["R"]

METHODS = json.loads(open("config/methods.json").read())
# METRICS = json.loads(open("config/metrics.json").read())

G_METRICS = glob_wildcards("code/05-gene_qc-{m}.R").m
C_METRICS = glob_wildcards("code/05-cell_qc-{m}.R").m
METRICS = G_METRICS + C_METRICS
TYPE_METRIC = ["gene"] * len(G_METRICS) + ["cell"] * len(C_METRICS)

ex = ["cor", "sil", "pve"]

gene_metrics_pairs = list(itertools.combinations([x for x in G_METRICS if x not in ex], 2))
cell_metrics_pairs = list(itertools.combinations([x for x in C_METRICS if x not in ex], 2))

DATSETS = glob_wildcards("code/00-get_data-{d}.R").d
SUBSETS = json.loads(open("config/subsets.json").read())

REFSETS = {"{}.{}".format(d,s): t \
	for d in SUBSETS.keys() \
	for s in SUBSETS[d].keys() \
	for t in SUBSETS[d][s]["type"]}

SUBSETS = {
	"dat": [d for d in SUBSETS.keys() for s in SUBSETS[d].keys()],
	"sub": [s for d in SUBSETS.keys() for s in SUBSETS[d].keys()]}

RUNS = {
	"ref":[r for r in REFSETS.keys() for m in METHODS.keys() if REFSETS[r] in METHODS[m]], 
	"mid":[m for r in REFSETS.keys() for m in METHODS.keys() if REFSETS[r] in METHODS[m]]}

# ------------------------------------------------------------------------------

qc_ref_dirs = expand(
	expand("results/qc_ref-{{refset}},{type}_{metric}.rds",
		zip, type = TYPE_METRIC, metric= METRICS), 
	refset = REFSETS)

qc_sim_dirs = expand(
	expand("results/qc_sim-{refset},{{type}}_{{metric}},{method}.rds",
		zip, refset = RUNS["ref"], method = RUNS["mid"]),
	zip , type = TYPE_METRIC, metric= METRICS)

dr_ref_dirs = expand("results/dr_ref-{refset}.rds", refset = REFSETS)
dr_sim_dirs = expand("results/dr_sim-{refset},{method}.rds", zip, refset = RUNS["ref"], method = RUNS["mid"])

# one-/two-dimensional tests
stats_1d = glob_wildcards("code/06-stat_1d-{x}.R").x
stats_2d = glob_wildcards("code/06-stat_2d-{x}.R").x

stats_1d_dirs = \
expand(
	expand(
		expand(
			"results/stat_1d,{{{{stat_1d}}}}-{refset},{{type}}_{{metric}},{method}.rds", 
			zip, refset = RUNS["ref"], method = RUNS["mid"]),
		zip, type = TYPE_METRIC, metric= METRICS), 
	stat_1d = stats_1d)

stats_2d_dirs = \
expand(
	expand(
		expand("results/stat_2d,{{{{stat_2d}}}}-{refset},{{{{type}}}}_{{metric1}},{{{{type}}}}_{{metric2}},{method}.rds", 
			zip, refset = RUNS["ref"], method = RUNS["mid"]),
		zip,
		metric1 = [m[0] for m in gene_metrics_pairs],
		metric2 = [m[1] for m in gene_metrics_pairs]),
	stat_2d = stats_2d,
	type = ['gene']) + \
expand(
	expand(
		expand("results/stat_2d,{{{{stat_2d}}}}-{refset},{{{{type}}}}_{{metric1}},{{{{type}}}}_{{metric2}},{method}.rds", 
			zip, refset = RUNS["ref"], method = RUNS["mid"]),
		zip,
		metric1 = [m[0] for m in cell_metrics_pairs],
		metric2 = [m[1] for m in cell_metrics_pairs]),
	stat_2d = stats_2d,
	type = ['cell'])

stats_dr_dirs = expand("results/stat_dr-{datset}.{subset}.rds",zip ,datset = SUBSETS["dat"],subset= SUBSETS["sub"])

plots_1d = glob_wildcards("code/07-plot_1d-{x}.R").x
plots_2d = glob_wildcards("code/07-plot_2d-{x}.R").x

plots_qc_1d = glob_wildcards("code/07-plot_qc_1d-{x}.R").x

rule all:
	input:
		"session_info.txt",
# preprocessing
		expand("data/00-raw/{datset}.rds", datset = DATSETS),
		expand("data/01-fil/{datset}.rds", datset = DATSETS),
		expand(
			"data/02-sub/{datset}.{subset}.rds", zip,
			datset = SUBSETS["dat"], subset = SUBSETS["sub"]),
# simulation
		expand(
			"data/03-est/{refset},{method}.rds", zip,
			refset = RUNS["ref"], method = RUNS["mid"]),
		expand(
			"data/04-sim/{refset},{method}.rds", zip,
			refset = RUNS["ref"], method = RUNS["mid"]),
# quality control
		qc_ref_dirs, qc_sim_dirs,
		dr_ref_dirs, dr_sim_dirs,
# evaluation
		stats_1d_dirs, stats_2d_dirs, stats_dr_dirs,
		#expand("results/comb_1d-{stat_1d}.rds", stat_1d = stats_1d),
		#expand("results/comb_2d-{stat_2d}.rds", stat_2d = stats_2d),
# visualization
		expand("plots/qc_1d-{plot_qc_1d},{refset}.pdf", plot_qc_1d = plots_qc_1d, refset = REFSETS),
		# expand(
		# 	expand(
		# 		"plots/qc_{{refset}},{type}_{metric}.pdf",
		# 		zip, type = TYPE_METRIC, metric = METRICS
		# 	), refset = REFSETS),
		expand(
			expand(
				"plots/qc_2d-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.pdf", zip,
				metric1 = [m[0] for m in gene_metrics_pairs],
				metric2 = [m[1] for m in gene_metrics_pairs]),
			type = "gene", refset = REFSETS),
		expand(
			expand(
				"plots/qc_2d-{{refset}},{{type}}_{metric1},{{type}}_{metric2}.pdf", zip,
				metric1 = [m[0] for m in cell_metrics_pairs],
				metric2 = [m[1] for m in cell_metrics_pairs]),
			type = "cell", refset = REFSETS),
		expand("plots/dr-{refset}.pdf", refset = REFSETS),
		expand("plots/stat_1d-{plot_1d},{stat_1d}.pdf", plot_1d = plots_1d, stat_1d = stats_1d),
		expand("plots/stat_2d-{plot_2d},{stat_2d}.pdf", plot_2d = plots_2d, stat_2d = stats_2d),
		expand("plots/stat_dr-{refset}.pdf", refset = REFSETS)

# PREPROCESSING ================================================================

rule get_data:
	priority: 99
	input:	"code/00-get_data-{datset}.R"
	output:	"data/00-raw/{datset}.rds"
	log:	"logs/00-get_data-{datset}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	{output}" {input} {log}'''

rule fil_data:
	priority: 98
	input:	"code/01-fil_data.R",
			raw = rules.get_data.output
	output:	"data/01-fil/{datset}.rds"
	log:	"logs/01-fil_data-{datset}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	raw={input.raw} fil={output}" {input[0]} {log}'''

rule sub_data:
	priority: 97
	input:	"code/02-sub_data.R",
			fil = rules.fil_data.output
	params:	con = "config/subsets.json"
	output:	"data/02-sub/{datset}.{subset}.rds"
	log:	"logs/02-sub_data-{datset}.{subset}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fil={input.fil} con={params.con} sub={output}" {input[0]} {log}'''

# SIMULATION ===================================================================

rule est_pars:
	priority: 96
	input:	"code/03-est_pars.R",
			sce = "data/02-sub/{refset}.rds",
			fun = "code/03-est_pars-{method}.R"
	output:	"data/03-est/{refset},{method}.rds"
	log:	"logs/03-est_pars-{refset},{method}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input.sce} fun={input.fun} est={output}" {input[0]} {log}'''

rule sim_data:
	priority: 95
	input:	"code/04-sim_data.R",
			est = rules.est_pars.output,
			sub = "data/02-sub/{refset}.rds",
			fun = "code/04-sim_data-{method}.R"
	output:	"data/04-sim/{refset},{method}.rds"
	log:	"logs/04-sim_data-{refset},{method}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	est={input.est} sub={input.sub}\
	fun={input.fun} sim={output}" {input[0]} {log}'''

# QUALITY CONTROL ==============================================================

rule qc_ref:
	priority: 94
	input: "code/05-calc_qc.R",
			sce = "data/02-sub/{refset}.rds",
			fun = "code/05-{type}_qc-{metric}.R"
	output: "results/qc_ref-{refset},{type}_{metric}.rds"
	log: "logs/05-qc_ref-{refset},{type}_{metric}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input.sce} fun={input.fun} res={output}" {input[0]} {log}'''

rule qc_sim:
	priority: 94
	input: "code/05-calc_qc.R",
			sce = rules.sim_data.output,
			fun = "code/05-{type}_qc-{metric}.R"
	output: "results/qc_sim-{refset},{type}_{metric},{method}.rds"
	log: "logs/05-qc_sim-{refset},{type}_{metric},{method}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	sce={input.sce} fun={input.fun} res={output}" {input[0]} {log}'''

# DIMENSIONALITY REDUCTION =====================================================

rule dr_ref:
	priority: 94
	input: 	"code/05-calc_dr.R",
			"data/02-sub/{refset}.rds"
	output:	"results/dr_ref-{refset}.rds"
	log:	"logs/05-dr_ref-{refset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	sce={input[1]} res={output}" {input[0]} {log}'''

rule dr_sim:
	priority: 94	
	input: 	"code/05-calc_dr.R",
			rules.sim_data.output
	output:	"results/dr_sim-{refset},{method}.rds"
	log:	"logs/05-dr_sim-{refset},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	sce={input[1]} res={output}" {input[0]} {log}'''

# EVALUATION ===================================================================

# one-dimensional test for each gene & cell metric
rule eval_1d:
	priority: 93
	input: "code/06-eval_1d.R",
			fun = "code/06-stat_1d-{stat_1d}.R",
			ref = rules.qc_ref.output,
			sim = rules.qc_sim.output
	output: "results/stat_1d,{stat_1d}-{refset},{type}_{metric},{method}.rds"
	log: "logs/06-eval_1d,{stat_1d}-{refset},{type}_{metric},{method}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	fun={input.fun} ref={input.ref} sim={input.sim} res={output}" {input[0]} {log}'''

# two-dimensional test for each pair of gene / cell metrics
rule eval_2d:
	priority: 93
	input:	"code/06-eval_2d.R",
			fun = "code/06-stat_2d-{stat_2d}.R",
			x_ref = "results/qc_ref-{refset},{type}_{metric1}.rds",
			y_ref = "results/qc_ref-{refset},{type}_{metric2}.rds",
			x_sim = "results/qc_sim-{refset},{type}_{metric1},{method}.rds",
			y_sim = "results/qc_sim-{refset},{type}_{metric2},{method}.rds"
	output:	"results/stat_2d,{stat_2d}-{refset},{type}_{metric1},{type}_{metric2},{method}.rds"
	log:	"logs/06-eval_2d,{stat_2d}-{refset},{type}_{metric1},{type}_{metric2},{method}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	x_ref={input.x_ref} y_ref={input.y_ref}\
	x_sim={input.x_sim} y_sim={input.y_sim}\
	fun={input.fun} res={output}" {input[0]} {log}'''

rule eval_dr:
	priority: 93
	input: "code/06-eval_dr.R",
			sce_ref = "data/02-sub/{datset}.{subset}.rds",
			dr_ref= "results/dr_ref-{datset}.{subset}.rds",
			dr_sim = lambda wc: [x for x in dr_sim_dirs \
				if "{}.{}".format(wc.datset, wc.subset) in x]
	params: lambda wc, input: ";".join(input.dr_sim)
	output: "results/stat_dr-{datset}.{subset}.rds"
	log: "logs/06-eval_dr-{datset}.{subset}.Rout"
	shell: '''
		{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
		dr_ref={input.dr_ref} dr_sim={params} sce_ref={input.sce_ref}\
		res={output}" {input[0]} {log}'''


# for each statistic, combine results across datasets & methods
rule comb_1d:
	priority: 92
	input:	"code/06-comb_1d.R",
			res = lambda wc: [x for x in stats_1d_dirs \
				if "stat_1d,{}-".format(wc.stat_1d) in x]
	params:	lambda wc, input: ";".join(input.res)
	output:	"results/comb_1d-{stat_1d}.rds"
	log:	"logs/06-comb_1d-{stat_1d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	{params} {output}" {input[0]} {log}'''

rule comb_2d:
	priority: 92
	input:	"code/06-comb_2d.R",
			res = lambda wc: [x for x in stats_2d_dirs \
				if "stat_2d,{}-".format(wc.stat_2d) in x]
	params:	lambda wc, input: ";".join(input.res)
	output:	"results/comb_2d-{stat_2d}.rds"
	log:	"logs/06-comb_2d-{stat_2d}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	{params} {output}" {input[0]} {log}'''

# VISUALIZATION ================================================================

rule plot_qc_1d:
	input: "code/07-plot_qc_1d-{plot_qc_1d}.R",
			utils = "code/utils-plotting.R",
	 		ref = lambda wc: [x for x in qc_ref_dirs if wc.refset in x],
	  		sim = lambda wc: [x for x in qc_sim_dirs if wc.refset in x]
	params: ref = lambda wc, input: ";".join(input.ref),
			sim = lambda wc, input: ";".join(input.sim)
	output: "plots/qc_1d-{plot_qc_1d},{refset}.pdf"
	log: "logs/07-plot_qc_1d-{plot_qc_1d},{refset}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	utils={input.utils} ref={params.ref} sim={params.sim} fig={output}" {input[0]} {log}'''

rule plot_qc_2d:
	input: "code/07-plot_qc_2d-by_refset.R",
			x_ref = "results/qc_ref-{refset},{type}_{metric1}.rds",
			y_ref = "results/qc_ref-{refset},{type}_{metric2}.rds",
			x_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset, wc.type, wc.metric1) in x],
			y_sim = lambda wc: [x for x in qc_sim_dirs \
				if "{},{}_{}".format(wc.refset, wc.type, wc.metric2) in x]
	params: x_sim = lambda wc, input: ";".join(input.x_sim),
			y_sim = lambda wc, input: ";".join(input.y_sim)
	output: "plots/qc_2d-{refset},{type}_{metric1},{type}_{metric2}.pdf"
	log: "logs/07-plot_qc_2d-{refset},{type}_{metric1},{type}_{metric2}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	x_ref={input.x_ref} y_ref={input.y_ref}\
	x_sim={params.x_sim} y_sim={params.y_sim}\
	fig={output}" {input[0]} {log}'''

rule plot_dr:
	input:	"code/07-plot_dr.R",
			ref = rules.dr_ref.output,
			sim = lambda wc: [x for x in dr_sim_dirs if wc.refset in x]
	params:	lambda wc, input: ";".join(input.sim)
	output:	"plots/dr-{refset}.pdf"
	log:	"logs/07-plot_dr-{refset}.Rout"
	shell:	'''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	ref={input.ref} sim={params} fig={output}" {input[0]} {log}'''

rule plot_1d:
	input:	"code/07-plot_1d-{plot_1d}.R",
			res = rules.comb_1d.output
	params: lambda wc, input: ";".join(input.res)
	output:	"plots/stat_1d-{plot_1d},{stat_1d}.pdf"
	log:	"logs/07-plot_1d-{plot_1d},{stat_1d}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	res={params} fig={output}" {input[0]} {log}'''

rule plot_2d:
	input:	"code/07-plot_2d-{plot_2d}.R",
			res = rules.comb_2d.output
	params:	lambda wc, input: ";".join(input.res)
	output:	"plots/stat_2d-{plot_2d},{stat_2d}.pdf"
	log: 	"logs/07-plot_2d-{plot_2d},{stat_2d}.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save "--args\
	res={params} fig={output}" {input[0]} {log}'''

rule plot_dr_eval:
	input: "code/07-plot_dr_eval.R",
			res = "results/stat_dr-{refset}.rds"
	output: "plots/stat_dr-{refset}.pdf"
	log:    "logs/07-plot_dr-{refset}.Rout"
	shell: '''
	{R} CMD BATCH --no-restore --no-save "--args wcs={wildcards}\
	res={input.res} fig={output}" {input[0]} {log}'''

# SESSION INFO =================================================================

rule session_info:
	priority: 100
	input:	"code/10-session_info.R"
	output:	"session_info.txt"
	log:	"logs/10-session_info.Rout"
	shell: 	'''
	{R} CMD BATCH --no-restore --no-save\
	"--args {output}" {input[0]} {log}'''