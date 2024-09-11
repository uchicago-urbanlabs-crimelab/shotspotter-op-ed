# Shotspotter Op-Ed Replication Code

This repository provides replication code for the regression discontinuity numbers provided in the op-ed published by the Crime Lab in the Chicago Tribune (insert link when published).

## Data and Files

To generate these results, the Lab used publicly available data from (add details about Violence Reduction Dashboard, how it was developed, etc). 

Specifically, the repository includes the necessary data and a replication script that processes the data, and produces the estimates of interest. Specifically, three data files are included: 

-`homicides_nfs_vics_20240904.feather`: The aforementioned shooting incident data.
-`location_description_lookup.csv`: A crosswalk of locations in the above data to whether they are outdoors, indoors, or at exterior locations (locations that cannot be clearly classified into either category, such as inside cars or parking buildings).
-`Police Districts (current).geojson`: A shapefile that delineates the area of each police district in the Chicago Police Department.

The specific data snapshot from the Violence Reduction Dashboard is included in the repository because the data is live—including the exact snapshot used ensures the results are replicable as the data changes over time.

The script, `shotspotter_op_ed_replication.R`, carries out the following tasks to arrive at the reported numbers:

1. Loads the data snapshot and carries out some basic processing: filter the data to shootings resulting in any gunshot injury, to shootings that were either outdoors or in exterior locations, and flags whether the incident happened after Shotspotter was fully rolled out, using the implementation dates from Topper and Ferrazares (2024). It also filters the data to incidents occuring inside police districts where there is a district with Shotspotter that neighbors a non-Shotspotter district, and vice-versa.
2. Creates the running variable, distance to the border. In particular, the district shapefile and the treatment area (Districts 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 15, 25) create a discontinuous jump in Shotspotter and non-Shotspotter installation across the city. Given the geography of Chicago and where shooting incidents are most common, two separate non-overlapping boundaries are produced, a north and south border. For each incident, the minimum straight line distance to that border is calculated, and negative distances are assigned to control areas without loss of generality.
3. Estimates the baseline regression discontinuity (RD) model: Using `rdrobust` (Calonico, Cattaneo and Titiunik, 2015), the script estimates a baseline regression discontinuity model using the default recommended settings. In particular, this uses a local linear regression, optimally selected bandwidth (Imbens and Kalyanaraman, 2012), bias-corrected robust standard errors with a quadratic order estimate (Calonico, Cattaneo and Titiunik, 2014), and triangular kernel weights. Two estimates mentioned in the op-ed are produced, one in the post-treatment period (the baseline average treatment effect at the cutoff provided in the op-ed), and a placebo pre-treatment period estimate.

## Research Design

The regression discontinuity design relies on certain basic assumptions. The main identifying assumption required for the RD to provide an unbiased estimate is that on average, potential outcomes in lethality with and without Shotspotter are continuous at the district boundary. Put plainly, lethality likelihood would not discretely jump at the police district boundary in the absence of Shotspotter. This assumption need not hold if for example, police or medical personnel response times to shootings are discontinuously changing between neighboring police districts right at their border for reasons other than Shotspotter (Topper and Ferrazares, 2024), or if officers in neighboring districts have different procedures for rendering first aid to shooting victims. 

The estimate created on pre-treatment data provides a partial test of this assumption, as there is no pre-existing difference in lethality rates across treatment and control police districts at the boundary.

A working paper with a full set of analyses, including estimates using a variety of additional specifications, standard regression discontinuity robustness checks, and more is forthcoming. A more complete detailing of the policy context, data and research design details and caveats, and discussion of results will be included.

# References
- Calonico, S., Cattaneo, M.D., and Titiunik, R. (2014). Robust Nonparametric Confidence Intervals for Regression-Discontinuity Designs. Econometrica 82(6): 2295-2326.
- Calonico, Cattaneo and Titiunik (2015). rdrobust: An R Package for Robust Nonparametric Inference in Regression-Discontinuity Designs. R Journal 7(1): 38-51.
- Imbens, G. and Kalyanaraman, K. (2012). Optimal Bandwidth Choice for the Regression Discontinuity Estimator. The Review of Economic Studies 79(3): 933–959. https://doi.org/10.1093/restud/rdr043
- Topper, M. and Ferrazares, T. (2024). The Unintended Consequences of Policing Technology: Evidence from ShotSpotter. Working Paper.
