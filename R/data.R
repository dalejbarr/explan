#' Sample stimuli for a Stroop experiment
#'
#' Description of a set of stimuli that could be used in a
#' Stroop-style cognitive experiment.
#'
#' @format ## `stroop_stimuli`
#' A data frame with 48 rows and 4 columns.
#' \describe{
#'   \item{stimulus_id}{A factor uniquely identifying each stimulus in the dataset.}
#'   \item{word}{Identity of the printed word (blue, green, red, or yellow).}
#'   \item{font_color}{Font color of the word (blue, green, red, or yellow).}
#'   \item{congruency}{Whether the word and font color are congruent or incongruent.}
#' }
"stroop_stimuli"

#' Sample stimuli for a factorial Stroop experiment
#'
#' Description of a set of stimuli that could be used in a
#' Stroop-style cognitive experiment.
#'
#' @format ## `stroop_stimuli_factorial`
#' A data frame with 48 rows and 5 columns.
#' \describe{
#'   \item{stimulus_id}{A factor uniquely identifying each stimulus in the dataset.}
#'   \item{word}{Identity of the printed word (blue, green, red, or brown).}
#'   \item{font_color}{Font color of the word (blue, green, red, or brown).}
#'   \item{congruency}{Whether the word and font color are congruent or incongruent.}
#'   \item{positions}{Whether this stimuli requires participants to stand or sit.}
#' }
"stroop_stimuli_factorial"
