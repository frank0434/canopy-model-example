# Canopy-cover curve fitting example

This is a small, standalone R example of the beta and piecewise canopy-cover
models used in the India analysis. It fits both curves to one set of
**synthetic**, not experimental, observations; it does not reproduce the
paper's results or its full preprocessing and bootstrap pipeline.

## Run

Install R and the required packages once:

```r
install.packages(c("minpack.lm", "ggplot2"))
```

From the repository root, run:

```sh
Rscript run_example.R
```

The script prints the fitted parameters, the beta-curve peak and an AIC
comparison. It writes `output/canopy_models.png` and
`output/predictions.csv` (GDD, beta prediction, piecewise prediction).
Run `Rscript tests/test_example.R` to check the example.

## Input and adapting the example

`data/example_canopy.csv` contains one curve with `GDD` (cumulative growing
degree days, in degree-days) and `CC` (canopy cover as a fraction from 0 to
1). The values were generated from the piecewise equation with added small,
seeded random noise; they are illustrative, not field measurements. For the
original analysis, GDD was accumulated from emergence. Calculate GDD
consistently for your own experiment before fitting.

To supply a different CSV and output folder, run from the repository root:

```sh
Rscript run_example.R path/to/your_data.csv path/to/results
```

The script fits **all rows as one curve**. Subset by plot, treatment or season
before fitting when separate curves are needed; it does not group data
automatically. Convert percentages to fractions first. Missing or non-finite
values, negative GDD and cover outside [0, 1] are rejected.

The starting values and parameter bounds in `R/models.R` are chosen for the
included data, **not automatically calibrated** to other experiments. Inspect
your measurements and adjust them for your GDD scale and growth stages.
Nonlinear fits can depend strongly on starting values, data coverage and
parameter bounds; convergence alone does not establish a biologically sensible
fit. Check the fitted curve and parameters, especially for sparse observations
or estimates at a bound. The piecewise bounds here enforce `tm1 < t1 <= t2 <
te`; preserve that ordering when changing them. For the beta curve, keep
positive `alpha` and `beta` and `t1 < te`. AIC compares fits to the same
observations under the models' error assumptions; it is not proof that either
curve is biologically correct.

## Equations and provenance

Here, `GDD` is cumulative growing degree-days from emergence and `CC` is
fractional canopy cover. In the beta equation,
`CC = exp(mu) * (GDD - t1)^alpha * (te - GDD)^beta` for `t1 < GDD < te`
(zero otherwise): `mu` is the log scale, `alpha` and `beta` shape the rise
and decline, and `t1`/`te` are the thermal-time limits. Its peak is at
`t1 + alpha / (alpha + beta) * (te - t1)`.

The piecewise equation describes canopy build-up to `t1`, a plateau at `vmax`
from `t1` to `t2`, and senescence to `te`. `tm1` controls the build-up shape;
`t1`, `t2`, and `te` are thermal-time phase boundaries, and `vmax` is maximum
canopy cover. These meanings follow the source equations and their use in the
referenced canopy analysis; `R/models.R` implements the equations and phase
limits. The plot is built with ggplot2 from observation and prediction data
frames, while the CSV retains one prediction column per model.

The equations and fitting approach were extracted and adapted from
[`scripts/equations.r`](https://github.com/frank0434/ch2_IND/blob/9e3a3b3d768f41cb8b3d97a709848a0999bd1ea2/scripts/equations.r)
and [`scripts/02CanopyCover.r`](https://github.com/frank0434/ch2_IND/blob/9e3a3b3d768f41cb8b3d97a709848a0999bd1ea2/scripts/02CanopyCover.r)
in the original India-analysis repository, which may not be accessible to
recipients. The original source labels the beta equation as Yin (1995) and
references Khan et al., DOI [10.1016/j.fcr.2019.107581](https://doi.org/10.1016/j.fcr.2019.107581)
for a related canopy model.

The beta equation is evaluated only within its valid interval to avoid
fractional powers of negative numbers. Unlike the original combined equation,
the piecewise function explicitly returns zero before GDD 0 and at and after
`te`; within its growth, plateau and senescence phases the equation is the
same. This example uses constrained fits rather than the original exploratory
unconstrained piecewise fit.
