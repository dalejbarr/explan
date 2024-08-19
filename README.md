
<!-- README.md is generated from README.Rmd. Please edit that file -->

# explan

<!-- badges: start -->

<!-- badges: end -->

The goal of `{explan}` is to help researchers design psychology
experiments. Currently package provides an implementation of Permuted
Subblock Randomization (PSR), a restricted randomization approach that
improves power for within-participant study designs. See [Liang & Barr
(2024)](https://osf.io/preprints/psyarxiv/4ums9) for details.

    @article{liang_barr_2024,
     title={Better power by design: Permuted-Subblock Randomization boosts power in repeated-measures experiments},
     url={osf.io/preprints/psyarxiv/4ums9},
     DOI={10.31234/osf.io/4ums9},
     publisher={PsyArXiv},
     author={Liang, Jinghui and Barr, Dale J},
     year={2024}
    }

The long-term goal is to provide a larger set of functions to help with
counterbalancing, Latin Square designs, etc.

## Installation

You can install the development version of explan from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("dalejbarr/explan")
```

## Implementing Permuted Subblock Randomization

The package includes two main functions for implementing PSR, a vector
version (`psr()`) and a data frame version (`psr_stimuli()`).

The vector version, `psr()` creates a vector of condition levels
conforming to PSR given a set of levels corresponding to experimental
conditions, desired number of subblocks, and number of repetitions per
condition.

``` r
library(explan)

psr(c("condition-A", "condition-B", "condition-C"),
    n_subblocks = 6, n_reps = 6)
#>  [1] "condition-A" "condition-C" "condition-B" "condition-A" "condition-C"
#>  [6] "condition-B" "condition-A" "condition-B" "condition-C" "condition-C"
#> [11] "condition-A" "condition-B" "condition-C" "condition-A" "condition-B"
#> [16] "condition-B" "condition-C" "condition-A"
```

To find out the number of possible subblocks for a given number of
repetition, use `possible_subblocks()`:

``` r
possible_subblocks(6)
#> [1] 1 2 3 6
```

The data frame version, `psr_stimuli()`, is a function that makes it
possible to apply PSR to a table of stimuli. As an example, the built-in
table `stroop_stimuli` contains example stimuli for a Stroop experiment,
which has a two-level within participant factor of congruency.

``` r
stroop_stimuli
#>    stimulus_id   word font_color  congruency
#> 1            1   blue       blue   congruent
#> 2            2  green      green   congruent
#> 3            3    red        red   congruent
#> 4            4 yellow     yellow   congruent
#> 5            5   blue       blue   congruent
#> 6            6  green      green   congruent
#> 7            7    red        red   congruent
#> 8            8 yellow     yellow   congruent
#> 9            9   blue       blue   congruent
#> 10          10  green      green   congruent
#> 11          11    red        red   congruent
#> 12          12 yellow     yellow   congruent
#> 13          13   blue       blue   congruent
#> 14          14  green      green   congruent
#> 15          15    red        red   congruent
#> 16          16 yellow     yellow   congruent
#> 17          17   blue       blue   congruent
#> 18          18  green      green   congruent
#> 19          19    red        red   congruent
#> 20          20 yellow     yellow   congruent
#> 21          21   blue       blue   congruent
#> 22          22  green      green   congruent
#> 23          23    red        red   congruent
#> 24          24 yellow     yellow   congruent
#> 25          25   blue      green incongruent
#> 26          26  green        red incongruent
#> 27          27    red     yellow incongruent
#> 28          28 yellow       blue incongruent
#> 29          29   blue        red incongruent
#> 30          30  green     yellow incongruent
#> 31          31    red       blue incongruent
#> 32          32 yellow      green incongruent
#> 33          33   blue     yellow incongruent
#> 34          34  green       blue incongruent
#> 35          35    red      green incongruent
#> 36          36 yellow        red incongruent
#> 37          37   blue      green incongruent
#> 38          38  green        red incongruent
#> 39          39    red     yellow incongruent
#> 40          40 yellow       blue incongruent
#> 41          41   blue        red incongruent
#> 42          42  green     yellow incongruent
#> 43          43    red       blue incongruent
#> 44          44 yellow      green incongruent
#> 45          45   blue     yellow incongruent
#> 46          46  green       blue incongruent
#> 47          47    red      green incongruent
#> 48          48 yellow        red incongruent
```

You can determine the number of replications using `dplyr::count()`:

``` r
stroop_stimuli |>
  dplyr::count(congruency)
#> # A tibble: 2 × 2
#>   congruency      n
#>   <fct>       <int>
#> 1 congruent      24
#> 2 incongruent    24
```

``` r
possible_subblocks(24)
#> [1]  1  2  3  4  6  8 12 24
```

To randomize this stimuli for a study with four participants, you would
use the following code:

``` r
stroop_four <- psr_stimuli(stroop_stimuli, "congruency",
                           n_subblocks = 12, n_part = 4)

stroop_four |>
  head(10)
#> # A tibble: 10 × 6
#>      PID sb_no stimulus_id word   font_color congruency 
#>    <int> <int> <fct>       <fct>  <fct>      <fct>      
#>  1     1     1 8           yellow yellow     congruent  
#>  2     1     1 23          red    red        congruent  
#>  3     1     1 32          yellow green      incongruent
#>  4     1     1 26          green  red        incongruent
#>  5     1     2 39          red    yellow     incongruent
#>  6     1     2 10          green  green      congruent  
#>  7     1     2 34          green  blue       incongruent
#>  8     1     2 3           red    red        congruent  
#>  9     1     3 12          yellow yellow     congruent  
#> 10     1     3 11          red    red        congruent
```

<!-- build the README.md with devtools::build_readme() -->

<!-- TODO: mention vignette -->
