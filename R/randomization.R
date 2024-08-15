#' Permuted-subblock randomization (PSR)
#'
#' Given a vector of condition labels, `psr()` outputs a
#' permuted-subblock randomization for a single participant.
#'
#' @param levels Set of condition levels (labels).
#' @param n_subblocks Number of desired subblocks.
#' @param n_reps Number of repetitions of each level.
#' @returns A character vector of length `n_reps` times `length(levels)`.
#' @seealso [psr_stimuli()] for applying PSR to a table with stimuli.
#' @examples
#' psr(c("A", "B", "C"), 6, 12)
#'
#' ## do the same but for four participants
#' lapply(seq_len(4),
#'        \(.x) psr(c("A", "B", "C"), 6, 12))
#' 
#' @export
psr <- function(levels, n_subblocks, n_reps) {
  ## step 1: split labels into subblocks
  numbers::divisors(n_reps)
  
  subblocks <- replicate(n_subblocks,
                       rep(levels, each = n_reps / n_subblocks),
                       simplify = FALSE)
  ## step 2: permute the labels in each subblock
  subblocks_p <- lapply(subblocks,
                      \(.x) .x[sample.int(length(.x))])
  ## step 3: concatenate results into a single vector
  unlist(subblocks_p)
}

#' Permuted-subblock randomization (PSR) with stimuli
#'
#' Given a table with a list of the stimuli presented to each participant,
#' outputs a table with stimuli organized into subblocks.
#'
#' @param stim_table Table containing the stimuli for the experiment.
#' @param IVs Vector with quoted names of the variables in `stim_table`
#'   corresponding to the independent variables in the study.
#' @param n_subblocks Number of desired subblocks.
#' @param n_part Number of desired participants.
#' @param sb_varname Name to give the subblocks variable in the output.
#' @param part_varname Name to give the participant variable in the output.
#' @returns
#' 
#' A data frame with `nrow(stim_table) * n_part` rows representing 
#' permuted-subblock randomization applied to `stim_table`. Output includes
#' variables `PID` identifying individual participants and `sb_no`
#' identifying subblocks within participants.
#' 
#' @examples
#'
#' psr_stimuli(stroop_stimuli, "congruency", 12)
#'
#' psr_stimuli(stroop_stimuli, c("font_color", "congruency"), 3)
#' 
#' @export
psr_stimuli <- function(stim_table,
                        IVs,
                        n_subblocks,
                        n_part = 1L,
                        sb_varname = "sb_no",
                        part_varname = "PID") {
  
  all_levels <- lapply(IVs, \(.x) stim_table[, .x, drop = TRUE] |>
                                  unique() |>
                                  as.character())

  rn <- seq_len(nrow(stim_table))

  rn_split <- split(rn, stim_table[, IVs, drop = FALSE])

  ## dat_split <- split(stim_table, stim_table[, IVs, .drop = FALSE])

  rn_count <- sapply(rn_split, \(.x) length(.x))

  if (length(unique(rn_count)) != 1L) {
    stop("check your data: unequal number of stimuli across cells of the design")
  }

  n_k <- length(rn_count)
  n_r <- rn_count[[1]]

  if (!(n_subblocks %in% possible_subblocks(n_r))) {
    stop("\n  with ", n_k, " cells in the design and ", n_r,
         " repetitions per cell,\n  '", n_subblocks, "' is not ",
         "a legal value for the number of subblocks.\n",
         "  possible values are: ",
         paste(possible_subblocks(n_r), collapse = ", "))
  }

  sb_seq <- rep(seq_len(n_subblocks), each = n_r / n_subblocks)

  pall <- lapply(seq_len(n_part), \(.pid) {
    sb_num <- replicate(n_k, sb_seq[sample.int(length(sb_seq))],
                      simplify = FALSE) |>
      unlist()

    psr_seq <- lapply(split(rn, sb_num), \(.x) .x[sample.int(length(.x))])

    psr_table <- lapply(psr_seq, \(.x) stim_table[.x, ])

    res <- do.call("rbind", psr_table)
    res[[sb_varname]] <- rep(seq_len(n_subblocks),
                             each = nrow(stim_table) / n_subblocks)
    res[[part_varname]] <- .pid
    .v <- c(part_varname, sb_varname)
    .rest <- setdiff(names(stim_table), .v)

    res[, c(.v, .rest)]
  })

  result <- do.call("rbind", pall)
  rownames(result) <- NULL

  result
}
