#' @title Tabulates breath test parameter differences of groups
#' @description Given a fit to 13C breath test curves, computes between-group confidence
#' intervals and p-values, for examples of the half emptying time \code{t50},
#' with correction for multiple testing.
#'
#' @param fit Object of class \code{breathtestfit}, for example from
#' \code{\link{nlme_fit}}, \code{\link{nls_fit}}
#' @param mcp_group "Tukey" (default) for all pairwise comparisons, "Dunnett" for
#' comparisons relative to the reference group.
#' @param reference_group Used as the first group and as reference group for
#' \code{mcp_group == "Dunnett"}
#' @param ... Not used
#'
#' @return A \code{tibble} of class \code{coef_diff_by_group} with columns
#' \describe{
#'   \item{parameter}{Parameter of fit, e.g. \code{beta, k, m, t50}}
#'   \item{method}{Method used to compute parameter. \code{exp_beta} refers to primary
#'   fit parameters \code{beta, k, m}. \code{maes_ghoos} uses the method from
#'   Maes B D, Ghoos Y F,
#'   Rutgeerts P J, Hiele M I, Geypens B and Vantrappen G 1994 Dig. Dis. Sci. 39 S104-6.
#'   \code{bluck_coward} is the self-correcting method from  Bluck L J C and
#'   Coward W A 2006}
#'   \item{groups}{Which pairwise difference, e.g \code{solid - liquid}}
#'   \item{estimate}{Estimate of the difference}
#'   \item{conf.low, conf.high}{Lower and upper 95% confidence interval of difference.
#'   A comparison is significantly different from zero when both estimates have the same
#'   sign.}
#'   \item{p.value}{p-value of the difference against 0, corrected for multiple testing}
#' }
#' @examples
#' library(dplyr)
#' data("usz_13c")
#' data = usz_13c %>%
#'   dplyr::filter( patient_id %in%
#'     c("norm_001", "norm_002", "norm_003", "norm_004", "pat_001", "pat_002","pat_003")) %>%
#'   cleanup_data()
#' fit = nls_fit(data)
#' coef_diff_by_group(fit)
#' \donttest{
#' fit = nlme_fit(data)
#' coef_diff_by_group(fit)
#' }
#' # TODO: Add example for Stan fit typecast to class \code{breathtestfit} to compute
#' # confidence intervals instead of credible intervals
#' @importFrom stats confint relevel
#' @import multcomp
#' @export
coef_diff_by_group = function(fit, mcp_group = "Tukey", reference_group = NULL, ...) {
  UseMethod("coef_diff_by_group", fit)
}

#' @export
coef_diff_by_group.breathtestfit =
  function(fit, mcp_group = "Tukey", reference_group = NULL, ...) {
  if (!inherits(fit, "breathtestfit")) {
    stop("Function coef_diff_by_group: parameter 'fit' must inherit from class breathtestfit")
  }
  cf = coef(fit)
  if (is.null(cf))
    return(NULL)
  if (! mcp_group %in% c("Dunnett", "Tukey")){
    stop("Function coeff_diff_by_group: mcp_group must be 'Dunnett' or 'Tukey', but is ",
         mcp_group)
  }
  cm = comment(cf)
  # Keep CRAN quite
  . = confint = estimate.x = estimate.y = lhs = method = parameter = rhs = statistic =
    std.error = conf.low = conf.high = p.value = 
    adj.p.value = contrast = estimate= term = NULL
  cf = cf %>%
    mutate( # lme requires factors
      group = as.factor(.$group)
    )
  # No differences if there is only one group
  if (nlevels(cf$group) <=1){
    return(NULL)
  }
  if (!is.null(reference_group) && !(reference_group %in% levels(cf$group))) {
    stop("Function coeff_diff_by_group: reference_group must be a level in coef(fit)$group")
  }
  if (!is.null(reference_group)){
    cf$group = relevel(cf$group, reference_group)
  }
  sig = as.integer(options("digits"))
  cf = cf %>%
    group_by(parameter, method) %>%
    do({
      fit_lme = nlme::lme(value~group, random = ~1|patient_id, data = .)
      glh = multcomp::glht(fit_lme, linfct =  multcomp::mcp(group = mcp_group))
      broom::tidy(confint(glh)) %>%
        left_join(broom::tidy(summary(glh)) %>%
                    select(term, contrast, estimate, p.value=adj.p.value), 
                  by = c("term", "contrast"), copy = TRUE) 
    }) %>%
    mutate(
      estimate.x = signif(estimate.x, sig),
      conf.low = signif(conf.low, sig),
      conf.high = signif(conf.high, sig),
      p.value = signif(p.value, sig),
    ) %>% 
    ungroup() %>%
    dplyr::select(-estimate.y, -std.error, -statistic,-term, 
                  groups = contrast, estimate = estimate.x)
  comment(cf) = cm
  class(cf) = c("coef_diff_by_group", class(cf))
  cf
  }
