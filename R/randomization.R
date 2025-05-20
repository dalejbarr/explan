#' Permuted-subblock randomization (PSR) for one-factor designs
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

#' Arrange stimuli for a 2x2 factorial design, in circular or "eight" patterns.
#'
#' Given two factors and their levels, `walk_2x2()` outputs a sequences of combined
#' conditions and arrange their order in circular or "figure-eight" patterns.
#'
#' When multiple participants are desired, `walk_2x2()` counterbalances sequences
#' across participants.
#' 
#' Original condition order can be inspected with `con_2x2()` function.
#'
#' @param np Number of desired participants.
#' @param nr Number of repetitions of each level.
#' @param facR A vector containing two labels of the first (row) factor.
#' @param facC A vector containing two labels of the second (column) factor.
#' @param method
#'
#' The algorithm to order conditions, `c` represents "circular", `e` represents
#' "figure-8" pattern. Use `con_2x2()` to get an intuitive example.
#' 
#' @returns
#'
#' A list with the length of `np` with each element containing a sequence with
#' the length of `nr`.
#'
#' @seealso
#'
#' [psr_stimuli()] for applying PSR to a table with stimuli in
#' one-factordesign.
#'
#' [psr_2x2_stimuli()] for applying PSR to a table with stimuli in
#' 2x2 factorial design.
#'
#' @examples
#' walk_2x2(np = 1, nr = 4,
#'          facR = c("A", "a"), facC = c("B", "b"),
#'          method = "c")
#' 
#' @export
walk_2x2 <- function(np = 4, nr = 4,
                     facR = c("A", "a"),
                     facC = c("B", "b"),
                     method = "e"){
    if(!length(facR) == 2 | !length(facC) == 2){
        stop("Factors should only contain two levels.")
    }
    
    if(np %% 4 != 0) {
        warning("Sequences are not fully counterbalanced under PSR-C/PSR-E, since n_part is not a multiple of 4.")
    }
    
    labels <- c(
        paste(facR[1], facC[1], sep = "/"),
        paste(facR[1], facC[2], sep = "/"),
        paste(facR[2], facC[1], sep = "/"),
        paste(facR[2], facC[2], sep = "/")
    )
    if (method == "e"){
        ## PSR-E
        walk_seq <- c(1, 2, 3, 4)
    } else if (method == "c") {
        ## PSR-C
        walk_seq  <- c(1, 3, 2, 4)
    } else {
        stop("Algorithm unrecognized.")
    }
    ## counterbalance starting point across subjects.
    startingPt <- sapply(1:np, \(.x) {(.x %% 4) + 1}, simplify = TRUE)
    seqs <- lapply(startingPt, \(.x) {
        labels[rep(walk_seq[sapply((.x - 1):(.x + 2),
                                   \(.y) {.y%%4}) + 1],
                   nr)]
    })
    return(seqs)}

#' Permuted-subblock randomization (PSR) for one-factor designs with stimuli
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

#' Permuted-subblock randomization (PSR) for 2x2 factorial designs with stimuli
#'
#' Given a table with a list of the stimuli presented to each participant,
#' outputs a table with stimuli organized into subblocks.
#'
#' @param stim_table Table containing the stimuli for the experiment.
#' @param IVs Vector with quoted names of the variables in `stim_table`
#'   corresponding to the independent variables in the study.
#' @param algorithm
#'
#' The algorithm to order conditions, `max` uses PSR-max, `circular`
#' uses PSR-C, and "eight" uses PSR-E. Use `con_2x2()` to get an intuitive
#' example of how orders are arranged by PSR-C and PSR-E.
#' 
#' @param n_part Number of desired participants.
#' @param sb_varname Name to give the subblocks variable in the output.
#' @param part_varname Name to give the participant variable in the output.
#'
#' @details
#'
#' When `algorithm = c("c", "e")` and `np` is not a multiple of 4, sequences
#' would still be randomized, but a warning message would be generated reminding
#' this is not a fully counterbalanced design.
#' 
#' @returns
#' 
#' A data frame with `nrow(stim_table) * n_part` rows representing 
#' permuted-subblock randomization applied to `stim_table`. Output includes
#' variables `PID` identifying individual participants and `sb_no`
#' identifying subblocks within participants.
#' 
#' @examples
#'
#' psr_stimuli(stim_table = stroop_stimuli_factorial,
#'             IVs = c("font_color", "congruency"),
#'             algorithm = "circular",
#'             n_part = 4L,
#'             sb_varname = "sb_no",
#'             part_varname = "PID")
#' 
#' @export
psr_2x2_stimuli <- function(stim_table,
                            IVs,
                            algorithm = c("max", "circular", "eight"),
                            n_part = 1L,
                            sb_varname = "sb_no",
                            part_varname = "PID") {
    tmp_cl <- "fac-cond"
    stim_table[[tmp_cl]] <- do.call("paste", c(stim_table[IVs], sep = "."))

    all_levels <- unique(stim_table[[tmp_cl]])
    
    rn <- seq_len(nrow(stim_table))

    ## Grouping stimuli conditions
    rn_split <- split(rn, stim_table[, IVs, drop = FALSE])[all_levels]
    
    rn_count <- sapply(rn_split, \(.x) length(.x))

    if (length(unique(rn_count)) != 1L) {
        stop("check your data: unequal number of stimuli across cells of the design")
    }

    n_k <- length(rn_count)
    n_r <- rn_count[[1]]
    n_subblocks <- unique(rn_count)
    
    sb_seq <- rep(seq_len(n_subblocks), each = n_r / n_subblocks)

    if(algorithm == "max"){
        pall <- lapply(seq_len(n_part), \(.pid) {
            ## randomize stimuli and assign subblock numbers
            sb_num <- replicate(n_k, sb_seq[sample.int(length(sb_seq))],
                                simplify = FALSE) |>
                unlist()

            psr_seq <- lapply(split(rn, sb_num), \(.x) .x[sample.int(length(.x))])

            ## reassamble tables based on randomized sequences
            psr_table <- lapply(psr_seq, \(.x) stim_table[.x, ])

            res <- do.call("rbind", psr_table)

            ## re-assign subblock ID and participant ID 
            res[[sb_varname]] <- rep(seq_len(n_subblocks),
                                     each = nrow(stim_table) / n_subblocks)
            res[[part_varname]] <- .pid

            ## get final dataset
            .v <- c(part_varname, sb_varname)
            .rest <- setdiff(names(stim_table), tmp_cl) |>
                setdiff(.v)
            res[, c(.v, .rest)]
        })
        result <- do.call("rbind", pall)
    } else if(algorithm %in% c("circular", "eight")){
        if(n_part %% 4 != 0) {
            warning("Sequences are not fully counterbalanced under PSR-C/PSR-E, since n_part is not a multiple of 4.")
        }
        
        ## counterbalance starting points for each subject
        startingPt <- sapply(1:n_part, \(.x) {(.x %% 4) + 1}, simplify = TRUE)
        walk_seq <- if(algorithm == "circular"){
                        c(1, 2, 4, 3) ## clockwise, AB-Ab-ab-aB
                    } else {
                        c(1, 3, 2, 4) ## fig-8, AB-aB-Ab-ab
                    }

        ## counterbalance sequences for each subject
        seqs_balance <- sapply(startingPt, \(.x) {
            rep(all_levels[walk_seq[sapply((.x - 1):(.x + 2),
                                           \(.y) {.y%%4}) + 1]], 1)
        }, simplify = FALSE)

        psr_seq <- lapply(seqs_balance, \(.x){
            ## shuffle sequences per condition per subject
            rn_rand <- lapply(rn_split, \(.y) sample(.y, length(.y)))[all_levels]
            
            ## take one element per condition per subblock, following walk-seq
            rand_seqs <- lapply(1:length(sb_seq), \(.z){
                sapply(.x, \(.j) rn_rand[[.j]][.z],
                       USE.NAMES = FALSE)
            }) |> unlist()
        })

        psr_table <- lapply(psr_seq, \(.x) stim_table[.x, ])
        res <- do.call("rbind", psr_table)
        res[[sb_varname]] <- rep(seq_len(n_subblocks),
                                 each = nrow(stim_table) / n_subblocks) |>
            rep(n_part)
        res[[part_varname]] <- rep(1:n_part, each = sum(rn_count))

        .v <- c(part_varname, sb_varname)
        .rest <- setdiff(names(stim_table), tmp_cl) |>
            setdiff(.v)
        result <- res[, c(.v, .rest)]
    } else {
        stop("Algorithm unrecognized.")
    }
    
    rownames(result) <- NULL
    result
}
