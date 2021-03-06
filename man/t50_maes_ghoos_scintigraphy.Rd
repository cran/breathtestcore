% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/breathtest_parameters.R
\name{t50_maes_ghoos_scintigraphy}
\alias{t50_maes_ghoos_scintigraphy}
\title{Half-emptying time t50 from Maes/Ghoos fit with scintigraphic correction}
\usage{
t50_maes_ghoos_scintigraphy(cf)
}
\arguments{
\item{cf}{named vector of coefficients; only \code{k} and \code{beta} are required}
}
\value{
Time where value is 1/2 of maximum, i.e. t50 in minutes.
}
\description{
Half-emptying time t50 in minutes from beta exponential function fit,
with linear and rather arbitrary correction for 
scintigraphic values. This is given for comparison with published data only;
there is little justification to use it, even if it is closer to real gastric
emptying times as determined by MRI or scintigraphy.
Ghoos YF, Maes BD, Geypens BJ, Mys G, Hiele MI, Rutgeerts PJ, Vantrappen G. 
Measurement of gastric emptying rate of solids by means of a carbon-labeled 
octanoic acid breath test. Gastroenterology. 1993;104:1640-1647.
}
\seealso{
\code{\link{exp_beta}}, and \code{\link{t50_bluck_coward}} for an example.
}
