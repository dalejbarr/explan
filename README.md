
<!-- README.md is generated from README.Rmd. Please edit that file -->

# explan

<!-- badges: start -->
<!-- badges: end -->

The goal of `{explan}` is to help researchers design psychology
experiments. Currently this package provides an implementation of
Permuted Subblock Randomization (PSR), a restricted randomization
approach that improves power for within-participant study designs. See
[Liang & Barr (2024)](https://osf.io/preprints/psyarxiv/4ums9) for
details.

    @article{liangBetterPowerDesign2024,
      title = {Better Power by Design: {{Permuted-subblock}} Randomization Boosts Power in Repeated-Measures Experiments},
      author = {Liang, Jinghui and Barr, Dale J.},
      url={osf.io/preprints/psyarxiv/4ums9},
      year = {2024},
      journal = {Psychological methods},
      doi = {10.1037/met0000717}
    }

The long-term goal is to provide a larger set of functions to help with
counterbalancing, Latin Square designs, etc.

## Installation

You can install the development version of explan from
[GitHub](https://github.com/) with:

``` r
## install.packages("remotes")
remotes::install_github("dalejbarr/explan", dependencies = TRUE,
                        build_vignettes = TRUE)
```

## Implementing Permuted Subblock Randomization

### One-factor designs

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
#>  [1] "condition-A" "condition-B" "condition-C" "condition-C" "condition-A"
#>  [6] "condition-B" "condition-A" "condition-C" "condition-B" "condition-A"
#> [11] "condition-B" "condition-C" "condition-C" "condition-B" "condition-A"
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

To randomize these stimuli for a study with four participants, you would
use the following code:

``` r
stroop_four <- psr_stimuli(stroop_stimuli, "congruency",
                           n_subblocks = 12, n_part = 4)

stroop_four |>
  head(10)
#> # A tibble: 10 × 6
#>      PID sb_no stimulus_id word  font_color congruency 
#>    <int> <int> <fct>       <fct> <fct>      <fct>      
#>  1     1     1 10          green green      congruent  
#>  2     1     1 25          blue  green      incongruent
#>  3     1     1 33          blue  yellow     incongruent
#>  4     1     1 17          blue  blue       congruent  
#>  5     1     2 15          red   red        congruent  
#>  6     1     2 34          green blue       incongruent
#>  7     1     2 38          green red        incongruent
#>  8     1     2 5           blue  blue       congruent  
#>  9     1     3 21          blue  blue       congruent  
#> 10     1     3 41          blue  red        incongruent
```

### Two-by-two (2x2) factorial designs

Our PSR algorithms can also be used in 2x2 factorial designs with two
within-participant factors, each factor has two levels. Before
conducting randomization, you would like to construct a 2x2 condition
table with `con_2x2()` to see how factors are combined.

``` r
con_2x2(facR = c("A", "a"), facC = c("B", "b"))
#>   B         b        
#> A "A/B (1)" "A/b (2)"
#> a "a/B (3)" "a/b (4)"
```

According to the resulting 2x2 matrix, conditions were generated by
combining two factors in our design. Notice the numbers followed by,
they determined the relative positions of conditions in the original
sequence. That is, conditions are arranged as “A/B (1), A/b (2), a/B
(3), a/b (4)”.

Instead of choosing the number of subblocks, you can choose three
versions of PSR to randomize your stimuli. All versions are based on the
largest number of possible subblocks in order to match the context of
2x2 factorial designs. The first one is called “PSR-max”. It simply
randomizes all conditions under the largest number of subblocks. This is
identical to the one-factor design situations. The second one is called
“PSR-C” which clockwisly “moving” conditions in the 2x2 matrix. You can
use our `walk_2x2()` to have an intuitive example.

``` r
walk_2x2(np = 4, nr = 3, facR = c("A", "a"), facC = c("B", "b"), method = "c")
#> [[1]]
#>  [1] "a/B" "A/b" "a/b" "A/B" "a/B" "A/b" "a/b" "A/B" "a/B" "A/b" "a/b" "A/B"
#> 
#> [[2]]
#>  [1] "A/b" "a/b" "A/B" "a/B" "A/b" "a/b" "A/B" "a/B" "A/b" "a/b" "A/B" "a/B"
#> 
#> [[3]]
#>  [1] "a/b" "A/B" "a/B" "A/b" "a/b" "A/B" "a/B" "A/b" "a/b" "A/B" "a/B" "A/b"
#> 
#> [[4]]
#>  [1] "A/B" "a/B" "A/b" "a/b" "A/B" "a/B" "A/b" "a/b" "A/B" "a/B" "A/b" "a/b"
```

The list that `walk_2x2()` created contains four vectors within each one
representing the condition sequences for each participant. With PSR-C,
each sequence has a clockwise motion corresponding to the `con_2x2()`
matrix (i.e., 1-2-4-3-1-…). The first condition (starting point) has
been counterbalanced across participants.

The third version of PSR is called “PSR-E”. This algorithm moves
conditions in “nearby-diagonal” pattern (i.e., 1-3-2-4-1-…). The letter
“E” represents such pattern since the motion is similar to horizontally
drawing the number “8” in the 2x2 condition table. We avoid using the
term “PSR-8” to avoid confusion when PSR-8 represents PSR with 8
subblocks.

``` r
walk_2x2(np = 4, nr = 3, facR = c("A", "a"), facC = c("B", "b"), method = "e")
#> [[1]]
#>  [1] "A/b" "a/B" "a/b" "A/B" "A/b" "a/B" "a/b" "A/B" "A/b" "a/B" "a/b" "A/B"
#> 
#> [[2]]
#>  [1] "a/B" "a/b" "A/B" "A/b" "a/B" "a/b" "A/B" "A/b" "a/B" "a/b" "A/B" "A/b"
#> 
#> [[3]]
#>  [1] "a/b" "A/B" "A/b" "a/B" "a/b" "A/B" "A/b" "a/B" "a/b" "A/B" "A/b" "a/B"
#> 
#> [[4]]
#>  [1] "A/B" "A/b" "a/B" "a/b" "A/B" "A/b" "a/B" "a/b" "A/B" "A/b" "a/B" "a/b"
```

Finally, `walk_2x2()` also has a data frame version, `psr_2x2_stimuli()`
to apply PSR to a table of stimuli in 2x2 factorial designs. The
built-in table, `stroop_stimuli_factorial`, is an extension of the
one-factor version `stroop_stimuli`, and additionally contains one more
two-level within-participant factor of responding positions (standing
versus sitting).

``` r
stroop_stimuli_factorial
#> # A tibble: 96 × 5
#>    stimulus_id word  font_color congruency positions
#>    <fct>       <fct> <fct>      <fct>      <fct>    
#>  1 1           blue  blue       congruent  sitting  
#>  2 2           blue  blue       congruent  standing 
#>  3 3           brown brown      congruent  sitting  
#>  4 4           brown brown      congruent  standing 
#>  5 5           green green      congruent  sitting  
#>  6 6           green green      congruent  standing 
#>  7 7           red   red        congruent  sitting  
#>  8 8           red   red        congruent  standing 
#>  9 9           blue  blue       congruent  sitting  
#> 10 10          blue  blue       congruent  standing 
#> # ℹ 86 more rows
```

To randomize these stimuli for a study with four participants, you would
use the following code:

``` r
stroop_fac_four <- psr_2x2_stimuli(
    stim_table = stroop_stimuli_factorial,
    IVs= c("congruency", "positions"),
    algorithm = "circular",
    n_part = 4L)
    
stroop_fac_four |> 
    head(10)
#> # A tibble: 10 × 7
#>      PID sb_no stimulus_id word  font_color congruency  positions
#>    <int> <int> <fct>       <fct> <fct>      <fct>       <fct>    
#>  1     1     1 46          green green      congruent   standing 
#>  2     1     1 54          blue  red        incongruent standing 
#>  3     1     1 91          red   blue       incongruent sitting  
#>  4     1     1 21          green green      congruent   sitting  
#>  5     1     2 14          green green      congruent   standing 
#>  6     1     2 72          red   green      incongruent standing 
#>  7     1     2 53          blue  red        incongruent sitting  
#>  8     1     2 23          red   red        congruent   sitting  
#>  9     1     3 28          brown brown      congruent   standing 
#> 10     1     3 94          red   brown      incongruent standing
```

<!-- build the README.md with devtools::build_readme() -->

## Further information

Please see the included vignette entitled “randomization”. Make sure you
have installed the package from github using `build_vignettes = TRUE`
(see above) and then use the following command to see the vignette.

``` r
browseVignettes(package = "explan")
```
