\name{analyzeSurvival}
\alias{analyzeSurvival}

\title{Survival analysis}

\description{
    It first performs Cox analysis to select up to 3 modules that result
    in the best risk group categorization based on network analysis.
    Then, an Accelerated Failure Time (AFT) analyzeSurvival is done
    using the selected modules.}

\usage{
analyzeSurvival(survival, eventCol="Dead", riskCol="Risk1", Data=NULL,
                  excludeSamples=rownames(survival)[as.numeric(survival[,"Time"])<=0],
                  mus, netPath, outPath, favRisk="High", subSet=NULL,
                  doCox=TRUE, eOrMs="e", time2day=1, until=1,
                  xmax1=max(survival[, "Time"]) * (time2day/365), 
                  xmin1=0, minRecall4L=0.2, minRecall4H=0.05, verbose=0, doDebug=FALSE)
}

\arguments{
  \item{survival}{
    A matrix or a data frame with at least four columns: "PatientID", 
    "Time", \code{event}, and \code{riskCol}
    (see the \code{event} and \code{riskCol} arguments).
    The row names are the same as "PatientID".}

  \item{eventCol}{
    The name of the event column in the \code{survival} data.
    Values in this column must be 0 or 1
    (Alternatively, \code{TRUE} and \code{FALSE} values are also supported.)}

  \item{riskCol}{
    The name of the risk column in the \code{survival} data. Values in this
    column must be "High", "Int", or "Low".}

  \item{Data}{
    The feature matrix, e.g., patients on rows and eigengenes on columns. Exactly one of
    \code{netPath} or \code{Data} must not be \code{NULL}.}

  \item{excludeSamples}{
    A character vector of samples that will be excluded from the analysis. Must 
    be a subsets of row names of the feature matrix \code{Data}. With the
    default value, all the samples with a non-positive survival time
    will be excluded.}

  \item{mus}{
    A numeric vector of mu values to be used for analysis.}
    
  \item{netPath}{
    A character string describing path to saved output from
    \code{\link{makeNetwork}} and \code{\link{computEigengenes}} functions. 
     Exactly one of \code{netPath} or \code{Data} must not be \code{NULL}.}

  \item{outPath}{
    A character string describing the path to save plots and output.}

  \item{favRisk}{
    A risk category predicted by the network classifier that shall be compared to the 
    input \code{Labels} risk categories. The value must be one of these three: 
    "High", "Int", or "Low".}

  \item{subSet}{
    A risk category in \code{Labels} that shall be compared to the risk category predicted 
    by network classifier. The value must be one of these three: "High", "Int", or "Low".}

  \item{doCox}{
    Accepts a Boolean value, where \code{TRUE} (default) indicates the Cox analysis will be
    performed for module selection. Otherwise, all modules will be used
    for AFT, which can lead to overfitting.}

  \item{eOrMs}{
    A character vector to determine which eigengenes (already stored at \code{netPath}) 
    to be used as input data.
    E.g., \code{c("m", "e", "em")}, where "e" means
    "only gene expression", "m" means "DNA methylation", and "em" means
    the combination of both data types is used to compute an eigengene
    for a module. See the note below.}

  \item{time2day}{
    A numeric value that aids calculating survival time (in days). E.g., If the "Time" 
    column in \code{survival} data frame is in days, then
    \code{time2day=1},  set it to 30 if "Time" is in months, etc.}

  \item{until}{
    A numeric value describing the minimum survival time (in years) for a
    case to be considered as low risk, e.g., if an AML patient is known
    to be alive for at least 2 years after diagnosis, and not dead at
    the last follow up time, then we can consider this case low--risk.}

  \item{xmax1}{
    A numeric value determining the maximum time (in years) for plotting the K--M curves.}

  \item{xmin1}{
    A numeric value determining the minimum time (in years) for plotting the K--M curves.}

  \item{minRecall4L}{
    A numeric value of the aimed recall cut--off for low--risk
    predictions, which may not be reached exactly. The higher, the more
    low--risk cases would be identified, but the risk may be relatively
    higher. Do not change the default if you are not an expert.}

  \item{minRecall4H}{
    A numeric value of the aimed recall cut--off for high--risk
    predictions, which may not be reached exactly. The higher, the more
    high--risk cases would be identified, but the risk may be relatively
    lower. Do not change the default if you are not an expert.}

  \item{verbose}{
    An integer level of verbosity. \code{0} means silent, and higher values produce 
    more details of the computation.}

  \item{doDebug}{
    A Boolean that aids in code debugging by developers.}
}

\details{
    When \code{Data} is not \code{NULL}, set \code{netPath=NULL}. When 
    \code{netPath} is \code{NULL}, \code{eorMs} value is ignored. 
    In the iNETgrate pipeline, we pass a value to \code{netPath} for training set
    analysis and set it to \code{NULL} for test set (i.e., validation) data.}

\value{
A list with following components:
  \item{mus}{A vector of \code{mu} values same as the input.}
  \item{bestPvalues}{A data frame with three columns namely: "p-values", "mu", 
                     and "features". The best p--value and module names are
                     identified for each mu value.}
  \item{bestModules}{A matrix of ranked eigengenes from high to low based on Cox 
                     analysis for each mu.}
  \item{kmPVals}{A vector of best p--values for each mu.}
  \item{concordanceV}{A vector of best concordance for each mu.}
  \item{bestPvaluePlot}{A plot of best p--values for each mu.}
  \item{afts}{The result of accelFailAnalysis for each mu values.}
  \item{aftPaths}{A vector of characters named with mus.}
  \item{baseCriteria}{A named vector as the same as the input.}
  \item{timeTaken}{The time to complete analyzeSurvival.}
}

\references{
R Core Team (2019). R: A language and environment for statistical
computing. R Foundation for Statistical Computing, Vienna, Austria.
\href{https://www.R-project.org/}{stats}.

Therneau, T. (2020). A Package for Survival Analysis in R. R package
version 3.1-12, \href{https://CRAN.R-project.org/package=survival}{survival}.

Therneau, T.M., Grambsch, P.M., (2000). Modeling Survival Data: Extending the
Cox Model. \emph{Springer, New York. ISBN 0-387-98784-3}.
}

\note{
  If \code{computEigengene} is ran with \code{genExpr=NULL},
  then "e" and "em" cannot be used here.
  Similarly, if \code{computEigengene(eigenloci=NULL, ...)},
  then "m" and "em" cannot be used here.
  If in the next step of the analysis the eigengenes will be combined
  in a linear combination (common), then the "em" eigengene is redundant
  and not needed.
}

\seealso{
\code{\link{makeNetwork}}, \code{\link{computEigengenes}},
\code{\link{prepareSurvival}}, \code{\link{inferEigengenes}}, 
\code{\link{accelFailAnalysis}}, \code{\link{plotKM}}
}

\examples{

## Preparing data:
data(toyCleanedAml)
data(toyComputEloci)
eigenloci <- toyComputEloci$eigenloci

patientLabel <- as.matrix(toyCleanedAml$survival)[,"Risk1"]
dimnames1 <- list(c("High", "Low"), c("Risk1", "Risk2"))
netPath <- file.path(tempdir(), "net")
dir.create(netPath, showWarnings=FALSE)
print(paste("Results will be saved in:", netPath))
print(Sys.time())

## Make the network:
madeNetwork <- makeNetwork(genExpr=toyCleanedAml$genExpr, eigenloci=eigenloci,
                            geNames=colnames(eigenloci), mus=c(0.6), 
                            outPath=netPath, verbose=1)

## Compute eigengenes:
## More samples maybe included if eigenloci=NULL below. See the note in ?computEigengenes.
eigengenes <- computEigengenes(genExpr=toyCleanedAml$genExpr, 
                                  eigenloci=eigenloci, netPath=netPath, 
                                  geNames=colnames(eigenloci), Labels=patientLabel, 
                                  Label1="Low", Label2="High", 
                                  mus=c(0.6), survival=toyCleanedAml$survival,
                                  mu2modules=madeNetwork$mu2modules)

## Survival analysis:
survRes <- analyzeSurvival(survival=toyCleanedAml$survival, 
                             favRisk="High", subSet="Int", mus=0.6, 
                             netPath=netPath, outPath=netPath, 
                             eOrMs="e", xmax1=15, xmin1=0, verbose=1)

## Getting the best inetgrator:
bestPval <- survRes$bestPvalues ## Best p-values per mu value
## Alternatively, it can be read from the saved csv file:
bestPval <- read.csv(file=file.path(netPath, "bestPvalues_e.csv"), header=TRUE)

inetgrator <- bestInetgrator(bestPvalues=bestPval, 
                              usefuLoci=toyComputEloci$usefuLoci, 
                              lociPigen=toyComputEloci$lociPigen, netPath=netPath)

## Infer eigengenes for a validation dataset:
valExpr <- t(toyCleanedAml$genExpr)[1:10, ]
##^ In a real applications, the validation data must be independent from the train data.
inferred <- inferEigengenes(inetgrator=inetgrator, expr=valExpr)

## Plot the inferred eigengenes:
toPlot <- inferred$eigengeneS
plToPlot <- as.data.frame(patientLabel[rownames(toPlot)])
Pigengene::pheatmap.type(Data=scale(toPlot), annRow=plToPlot, cluster_cols=FALSE)

print(Sys.time())
}
\keyword{survival} 
