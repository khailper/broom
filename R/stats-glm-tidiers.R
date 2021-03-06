#' @templateVar class glm
#' @template title_desc_tidy_lm_wrapper
#'
#' @param x A `glm` object returned from [stats::glm()].
#'
#' @export
#' @family lm tidiers
#' @seealso [stats::glm()]
tidy.glm <- tidy.lm

#' @templateVar class glm
#' @template title_desc_augment
#'
#' @param x A `glm` object returned from [stats::glm()].
#' @template param_data
#' @template param_newdata
#' @param type.predict Passed to [stats::predict.glm()] `type`
#'   argument. Defaults to `"link"`.
#' @param type.residuals Passed to [stats::residuals.glm()] and
#'   to [stats::rstandard.glm()] `type` arguments. Defaults to `"deviance"`.
#' @template param_se_fit
#' @template param_unused_dots
#' 
#' @evalRd return_augment(
#'   ".se.fit",
#'   ".hat",
#'   ".sigma",
#'   ".std.resid",
#'   ".cooksd"
#' )
#'
#' @details If the weights for any of the observations in the model
#'   are 0, then columns ".infl" and ".hat" in the result will be 0
#'   for those observations.
#'   
#'   A `.resid` column is not calculated when data is specified via
#'   the `newdata` argument.
#'
#' @export
#' @family lm tidiers
#' @seealso [stats::glm()]
#' @include stats-lm-tidiers.R
augment.glm <- function(x, 
  data = model.frame(x),
  newdata = NULL,
  type.predict = c("link", "response", "terms"),
  type.residuals = c("deviance", "pearson"),
  se_fit = FALSE, ...) {
  
  type.predict <- match.arg(type.predict)
  type.residuals <- match.arg(type.residuals)
  
  df <- if (is.null(newdata)) data else newdata
  df <- as_broom_tibble(df)
  
  # don't use augment_newdata here; don't want raw/response residuals in .resid
  if (se_fit) {
    pred_obj <- predict(x, newdata, type = type.predict, se.fit = TRUE)
    df$.fitted <- pred_obj$fit
    df$.se.fit <- pred_obj$se.fit
  } else {
    df$.fitted <- predict(x, newdata, type = type.predict)
  }
  
  if (is.null(newdata)) {
    
    tryCatch({
      infl <- influence(x, do.coef = FALSE)
      df$.resid <- residuals(x, type = type.residuals)
      df$.std.resid <- rstandard(x, infl = infl, type = type.residuals)
      df <- add_hat_sigma_cols(df, x, infl)
      df$.cooksd <- cooks.distance(x, infl = infl)
    }, error = data_error)
  }
  
  df
}



#' @templateVar class glm
#' @template title_desc_glance
#'
#' @param x A `glm` object returned from [stats::glm()].
#' @template param_unused_dots
#'
#' @evalRd return_glance(
#'   "null.deviance",
#'   "df.null",
#'   "logLik",
#'   "AIC",
#'   "BIC",
#'   "deviance",
#'   "df.residual"
#' )
#'
#' @examples
#'
#' g <- glm(am ~ mpg, mtcars, family = "binomial")
#' glance(g)
#'
#' @export
#' @family lm tidiers
#' @seealso [stats::glm()]
glance.glm <- function(x, ...) {
  s <- summary(x)
  ret <- unrowname(as.data.frame(s[c("null.deviance", "df.null")]))
  finish_glance(ret, x)
}
