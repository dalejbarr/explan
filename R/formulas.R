#' Create "mgcv style" random effect terms (internal)
#' 
#' This function adds arguments to `s()` term that is use in `{mgcv}` formulas.
#' Better leave this function internal.
#' 
#' @param term the `s()` term that needs to be processed.
#' 
#' @details
#' 
#' The "smooth term" `s()` that enters this function should only contain factors, e.g., `s(id)`, `s(item)`.
#' See [wi_mgcv()] for details of other arguments.
#' 
#' @returns
#' 
#' A new `s()` term with additional parameter
#' 
#' @seealso
#' 
#' [wi_mgcv()]
#' 
#' @examples
#' ## create a 'clean' by-subject random effect term
#' bysubj_int <- quote(s(id))
#' 
#' ## standard by-subject random effect
#' make_mgcvRE(term = bysubj_int,
#'             subj_id = quote(id),
#'             item_id = quote(item_id),
#'             wiggle_subj = FALSE)
#' 
#' ## wiggle by-subject effect
#' make_mgcvRE(term = bysubj_int,
#'             subj_id = quote(id),
#'             item_id = quote(item_id),
#'             wiggle_subj = TRUE, set_k_by = "mgcv",
#'             bs = "tp", k_threshold = 0.25)
#' 
#' ## by-subject random slope
#' make_mgcvRE(term = quote(s(id, A)),
#'             subj_id = quote(id),
#'             item_id = quote(item_id))
#' 
#' @keywords internal
make_mgcvRE <- function(term, subj_id, order_id,
                        wiggle_subj = TRUE,
                        set_k_by = "mgcv",
                        bs = "tp",
                        k_threshold = 0.25,
                        data = NULL){
    requireNamespace("reformulas")
    subj_expr <- deparse(subj_id) |> as.name()
    ## split the term
    termls <- as.list(term)
    ## to detect s(subj_id)
    if(wiggle_subj == TRUE &
       length(termls) == 2 &
       identical(subj_expr, termls[[2]])){
        order_expr <- deparse(order_id) |> as.name()
        fs_args_df <- list(order_expr,
                           bs = "fs", m = 1,
                           xt = list(bs = bs))
        if(set_k_by == "mgcv"){ 
            fs_args_all <- fs_args_df ## using mgcv default
        } else if(set_k_by == "explan"){
            if(is.null(data)){
                stop('argument set_k_by = "explan" requires a data frame.')
            } else { ## explan calculates k based on nRep 
                k_explan <- ceiling(k_threshold *
                                    max(as.integer(data[[as.character(order_expr)]]))
                                    )
                fs_args_all <- c(fs_args_df, k = k_explan)
            }
        } else {
            stop('unsupported option for argument `set_k_by`. Available options: "mgcv", "explan".')
        }
    } else {
        fs_args_all <- list(bs = "re")
    }
    new_term <- c(termls, fs_args_all) |>
        as.call()
    return(new_term)
}

#' Translate `{lme4}` formula to `{mgcv}` style and specify a wiggly by-subject random intercept
#' 
#' This function translates a `{lme4}` mixed-effect formula (whose random effects are defined by `|` notations)
#' and translate it to a {mgcv} mixed-effect formula (whose random effects are defined by `s()`).
#' 
#' @param formula a `{lme4}`-style formula
#' @param subj_id the column in data (or its name) to identify unique subjects
#' @param order_id the column in data (or its name) to identify trial orders. Required only when `wiggle_subj = TRUE`.
#' @param wiggle_subj whether 'wiggly by_subject random intercept' should be included; default is `TRUE`
#' @param set_k_by how the number of basis function `k` is determined. Can be either `"mgcv"` or `"explan"`. See details for further description.
#' @param bs 'basis smooth' used to specify 'wigglyness' of factor smooth. This argument follows [mgcv::s()] settings and works only when `wiggle_subj = TRUE`; the default value is `"tp"`
#' @param k_threshold A value to determine the number of basis functions. This argument works only when `wiggle_subj = TRUE`, `set_k_by = "explan"`, and `data` is specified; the default value is 0.25. See details.
#' @param data a formula-relevant data frame that contains corresponding variable names in `formula`.
#' 
#' @details
#' 
#' [wi_mgcv()] is mainly used to efficiently convert a {lme4} mixed-effect formula (which usually does not support wiggly by-subject random intercept) to a {mgcv} mixed-effect formula (does). By specifying subject (participant) id column and order id column, `wi_mgcv()` identifies static by-subject random intercept and convert it to 'factor smooths'. By doing so, by-subject random intercept can wiggle over time (specified by `order_id`).
#' 
#' Note that, during conversion, any correlated random effect structure (e.g., correlated random slopes and random intercepts such as `(1 + dv | id)`) would be forced to uncorrelated to meet the requirements in `{mgcv}` context. It is recommended to use double-bar notations to specify uncorrelated random effects in your `{lme4}` formula, such as `(dv1 * dv2 || id)`.
#' 
#' Only when `wiggle_subj = TRUE`, arguments `set_k_by = "explan"` and `k_threshold` become meaningful. When `wiggle_subj = FALSE`, the function simply produces a formula that fits Linear Mixed-Effect Model in `{mgcv}.`
#' 
#' If `set_k_by = "mgcv"`, the number of basis functions `k` is determined by package `{mgcv}` default settings; if `set_k_by = "explan"`, argument `data` is required, as `"explan"` uses data information (maximal trial number) to determine number of basis function. The default is 25% of trials of each subject.
#' 
#' @returns
#' 
#' a new formula that is appropriate in [`mgcv::bam()`] or [`mgcv::gam()`] with expanded random effect specification.
#' 
#' @examples
#' 
#' ## 1: one-factor design
#' n_part <- 4
#' dat_1f <- psr_stimuli(stroop_stimuli, "congruency",
#'                       n_subblocks = 1, n_part = n_part) |>
#'     cbind(order = rep(1:nrow(stroop_stimuli),
#'                       times = n_part),
#'           dv = rnorm(n = nrow(stroop_stimuli) * n_part))
#' 
#' ## both lme4::lmer() and mgcv::bam() are coding-sensitive
#' dat_1f[["PID"]] <- factor(dat_1f[["PID"]])
#' dat_1f[["congruency"]] <- ifelse(dat_1f[["congruency"]] == "congruent",
#'                                  yes = -1/2, no = 1/2)
#' mod_1f <- dv ~ congruency +
#'     (congruency || PID)
#' 
#' ## default settings: GAMMs with 'wiggly intercept' (factor smooth)
#' mod_mgcv <- wi_mgcv(formula = mod_1f, subj_id = PID,
#'                     order_id = order, data = dat_1f)
#' mgcv::bam(mod_mgcv, data = dat_1f) |> summary()
#' 
#' ## equivalent to the original lme4 model, but available for `mgcv::gam()`
#' mod_mgcv_e <- wi_mgcv(formula = mod_1f, subj_id = PID,
#'                       wiggle_subj = FALSE)
#' lme4::lmer(mod_1f, data = dat_1f) |> summary()
#' mgcv::bam(mod_mgcv_e, data = dat_1f) |> summary()
#' 
#' ## `data` is ignored when using default mgcv sttings to determine k...
#' wi_mgcv(formula = mod_1f, subj_id = PID,
#'         order_id = order,
#'         set_k_by = "mgcv")
#' ## ... but not when using `explan` method
#' wi_mgcv(formula = mod, subj_id = PID,
#'         order_id = order,
#'         set_k_by = "explan",
#'         data = dat_1f)
#' 
#' ## 2: two-factor design, both within-subject
#' dat_2f_ww <- psr_2x2_stimuli(
#'     stim_table = stroop_stimuli_factorial,
#'     IVs= c("congruency", "positions"),
#'     algorithm = "circular",
#'     n_part = n_part) |>
#'     cbind(order = rep(1:nrow(stroop_stimuli_factorial),
#'                       times = n_part),
#'           dv = rnorm(n = nrow(stroop_stimuli_factorial) * n_part))
#' dat_2f_ww[["PID"]] <- factor(dat_2f_ww[["PID"]])
#' dat_2f_ww[["congruency"]] <- ifelse(dat_2f_ww[["congruency"]] == "congruent",
#'                                     yes = -1/2, no = 1/2)
#' dat_2f_ww[["positions"]] <- ifelse(dat_2f_ww[["positions"]] == "standing",
#'                                    yes = -1/2, no = 1/2)
#' 
#' mod_2f_ww <- dv ~ congruency * positions +
#'     (congruency * positions || PID)
#' mod_mgcv_2f_ww <- wi_mgcv(formula = mod_2f_ww, subj_id = PID,
#'                        order_id = order, data = dat_2f_ww)
#' mgcv::bam(mod_mgcv_2f_ww, data = dat_2f_ww) |> summary()
#' 
#' 
#' mod_mgcv_2f_ww_e <- wi_mgcv(formula = mod_2f_ww, subj_id = PID,
#'                             order_id = order, wiggle_subj = FALSE)
#' 
#' ## equivalent
#' lme4::lmer(mod_2f_ww, data = dat_2f_ww) |> summary()
#' mgcv::bam(mod_mgcv_2f_ww_e, data = dat_2f_ww) |> summary()
#' 
#' ## 3: two-factor design, one within-subject and one between-subject
#' dat_2f_wb <- psr_stimuli(stroop_stimuli, "congruency",
#'                          n_subblocks = 1, n_part = n_part) |>
#'     cbind(group = factor(rep(1:2, each = nrow(stroop_stimuli) * 2)),
#'           order = rep(1:nrow(stroop_stimuli),
#'                       times = n_part),
#'           dv = rnorm(n = nrow(stroop_stimuli) * n_part))
#' dat_2f_wb[["PID"]] <- factor(dat_2f_wb[["PID"]])
#' dat_2f_wb[["group"]] <- factor(dat_2f_wb[["group"]])
#' dat_2f_wb[["congruency"]] <- ifelse(dat_2f_wb[["congruency"]] == "congruent",
#'                                     yes = -1/2, no = 1/2)
#' 
#' mod_2f_wb <- dv ~ congruency * group +
#'     (congruency * group || PID) +
#'     (group || stimulus_id)
#' 
#' mod_mgcv_2f_wb <- wi_mgcv(formula = mod_2f_wb, subj_id = PID,
#'                           order_id = order, data = dat_2f_wb)
#' mgcv::gam(mod_mgcv_2f_wb, data = dat_2f_wb) |> summary()
#' 
#' mod_mgcv_2f_wb_e <- wi_mgcv(formula = mod_2f_wb,
#'                             subj_id = PID, wiggle_subj = FALSE,
#'                             order_id = order,
#'                             data = dat_2f_wb)
#' 
#' ## use gam() when experiencing "non-conformable arrays" error as it is a known bug
#' lme4::lmer(mod_2f_wb, data = dat_2f_wb) |> summary()
#' mgcv::bam(mod_mgcv_2f_wb_e, data = dat_2f_wb, method = "REML") |> summary()
#' 
#' ## 4. formulae
#' ## these formulae are acceptable...
#' dv ~ A + (1 | id) ## random-intercept-only model
#' dv ~ A + (1 | id) + (0 + A | id)
#' dv ~ A + (A || id)
#' dv ~ A * B + (A * B || id)
#' dv ~ A * B + (A * B || id) + (B || order)
#' 
#' ## ...while these produce warnings
#' dv ~ A + (A | id) ## correlated ran int/slp
#' dv ~ A + (0 + A | id) ## ran-slp only model
#' dv ~ A + (-1 + A | id) ## ran-slp only model, alternative
#' dv ~ A * B + (A * B | id) + (B | order)
#' dv ~ A * B + (A * B | id) + (B || order)
#' dv ~ A * B + (A * B || id) + (B | order)
#' dv ~ A * B + (0 + A * B | id) + (B | order)
#' @export
wi_mgcv <- function(formula, subj_id, order_id,
                    wiggle_subj = TRUE,
                    set_k_by = "explan",
                    bs = "tp",
                    k_threshold = 0.25,
                    data = NULL){
    if(!is.null(data) &&
       any(is.na(sapply(all.vars(formula), match, colnames(data))))){
        stop("mismatched variable name(s) was found，revise the formula")
    }
    subj_expr <- substitute(subj_id)
    order_expr <- if(wiggle_subj == TRUE){
                      substitute(order_id)
                  } else {
                      NA_real_
                  }
    f_main <- reformulas::nobars(formula) |>
        reformulas::RHSForm() ## extract main-effect-only formula
    re_raw <- reformulas::findbars(formula) ## decompose random effects
    if(is.null(re_raw)){ ## scenario 1: no random effect
        formula_final <- formula
    } else {
        if(reformulas::inForm(formula, quote(`|`))){
            ## scenario 2: no random intercept / correlated random effects
            if(!any(sapply(re_raw, identical, substitute(1 | subj_id)))){
                warning("Correlated or no-random-intercept structures were forced to be uncorrelated\n unless by-subj random intercept was suppressed.\nTo suppress this warning, use double-bar notation `||` to specify uncorrelated random effects.")
            }
            formula_used <- reformulas::replaceForm(formula,
                                                    quote(`|`),
                                                    quote(`||`))
            re_used <- reformulas::findbars(formula_used)
        } else {
            ## scenario 3: correct random effect specification
            formula_used <- formula
            re_used <- re_raw
        }
        ## quote random effects using s()
        new_re <- lapply(1:length(re_used), \(.x){
            re_tmp <- re_used[[.x]] |>
                as.character() |>
                gsub(pattern = "[0|1] \\+ ",
                     replacement = "") |>
                gsub(pattern = ":",
                     replacement = ",") |>
                rev() |>
                setdiff(c("|", "1", "0")) |>
                strsplit(",") |> unlist() |> 
                sapply(as.symbol, USE.NAMES = FALSE, simplify = "list")
            tmp_ls <- c(quote(s), unlist(re_tmp)) |> as.call()
            ## new_term <- if(length(re_tmp) == 1){
            ##                 reformulas::makeOp(as.name(re_tmp[1]),
            ##                                    quote(s))
            ##             } else {
            ##                 reformulas::makeOp(as.name(re_tmp[1]),
            ##                                    as.name(re_tmp[2]),
            ##                                    op = quote(s))
            ##             }
            ## new_term
            tmp_ls
        })
        ## using internal fn make_mgcvRE() to add args
        new_s <- lapply(new_re, \(.x) {make_mgcvRE(.x,
                                                   subj_id = as.symbol(subj_expr),
                                                   order_id = as.symbol(order_expr),
                                                   wiggle_subj = wiggle_subj,
                                                   set_k_by = set_k_by,
                                                   bs = bs,
                                                   k_threshold = k_threshold,
                                                   data = data)
        })
        ## connect main-effect-only formula with new random effects
        new_terms_raw <- list(f_main, unlist(new_s)) |>
            unlist()
        terms_final <- new_terms_raw |> reformulas::sumTerms()
        formula_final <- formula_used
        reformulas::RHSForm(formula_final) <- terms_final
    }
    return(formula_final)
}
