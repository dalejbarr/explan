#' Set of possible sub-blocks
#'
#' Calculates the set of possible sub-blocks for given values of
#' `n_reps` (number of repetitions of each factor level).
#'
#' @param n_reps Number of repetitions of each factor level.
#' @returns A vector with the possible number of sub-blocks.
#' @details This is a basic function that wraps the function [numbers::divisors()].
#' @examples
#' possible_subblocks(48)
#' 
#' @export
possible_subblocks <- function(n_reps) {
  numbers::divisors(n_reps)
}

#' Tabulate streaks in a vector
#'
#' Given a vector `x`, produce a frequency table of the number of
#' streaks (i.e., unbroken sequences of the same value).
#'
#' @param data A data frame.
#' @param varname The name of the variable you want to check for streaks.
#' @param pid_name The name of the variable identifying individual participants.
#' @returns A data frame representing a contingency table with two variables,
#'   `streak_length`, the length of the streak, and `n`, the number of times it
#'   occurs for the variable `varname`.
#' 
#' @examples
#'
#' stroop1 <- psr_stimuli(stroop_stimuli, "congruency", 1, 16)
#' streak_table(stroop1, "congruency", "PID")
#'
#' stroop12 <- psr_stimuli(stroop_stimuli, "congruency", 12, 16)
#' streak_table(stroop12, "congruency", "PID")
#' 
#' @export
streak_table <- function(data, varname, pid_name = "PID") {
  if (!inherits(data, "data.frame"))
    stop("'data' must be a data frame")
  
  if (!is.character(varname) || (length(varname) != 1L))
    stop("'varname' must be a character vector of length 1")

  if (!is.character(pid_name) || (length(pid_name) != 1L))
    stop("'pid_name' must be a character vector of length 1")

  if (!(pid_name %in% colnames(data))) {
    stop("variable 'PID' not found in data; use 'pid_name' to specify alternative ID")
  }
  
  x <- data[[varname]]
  
  x2 <- if (is.factor(x)) {
          as.character(x)
        } else {
          x
        }

  if (!is.vector(x2))
    stop("variable '", varname, "' was not a vector")
  
  x2_split <- split(x2, data[, pid_name, drop = FALSE])

  runs <- lapply(x2_split, \(.x) rle(.x)$lengths) |>
    unlist()
    
  rtbl <- table(runs)
  data.frame(streak_length = as.integer(names(rtbl)),
             n = as.integer(rtbl))
}
