## Isha wrote this script on 2020/03/24 to get sample data for the iNETgrate vignette.
## Habil improved it a little bit before submitting the package to Bioconductor on 2023-03-24.


## Library:
library(TCGAbiolinks)
library(beepr)
library(Pigengene)
library(SummarizedExperiment)
library(GenomicRanges)
library(minfi)
library(igraph)
library(Homo.sapiens)
library(WGCNA)
if(!require(iNETgrate)){ ## It may not have been built yet! 
    ## However iNETgrate package cannot be compiled without sample data. So sourcing "sample.data.R"
    source("~/proj/genetwork/code/Ghazal/Packing/update.R")
}

## Settings
starTime <- Sys.time()
cat("Data sampling started at:\n")
print(starTime)
dataProject <- "TCGA-LAML"
print(paste("Project:", dataProject))
savePath <- "~/proj/genetwork/data/AML/GDC_portal/TCGA"
dir.create(savePath)
samplePath <- file.path(savePath, "sampleData")
dir.create(samplePath)
print(paste("Data will be saved at:", savePath))
netPath <- file.path(savePath, "net")
dir.create(netPath)
iNETgrateDataPath <- "~/proj/genetwork/code/Ghazal/Packing/default_config/data"

seed <- 1
set.seed(seed)

## Download data
print("Downloading and preparing data...")
downloaded <- download.data(dataProject=dataProject, savePath=savePath)
print("Downloading completed!!")

## Clean data
print("Cleaning and preparing all data...")
riskCatCol <- "acute_myeloid_leukemia_calgb_cytogenetics_risk_category"
riskFactorCol <- "cytogenetic_abnormalities"

cleaned <- clean.allData(genExpr=downloaded$genExpr,
                         genExprSampleInfo=downloaded$genExprSampleInfo, 
                         rawDnam=downloaded$rawDnam, savePath=savePath, 
                         annLib="Auto", clinical=downloaded$clinical, 
                         riskCatCol=riskCatCol, riskFactorCol=riskFactorCol, 
                         riskHigh="Poor", riskLow="Favorable", otherLabel=NULL, 
                         verbose=1)

print("Cleaning data done!!")

## Prepare toy data
print("Creating sample of data!!")
toyData <- sample.data(Data=downloaded, cleanData=cleaned)

cleanedS <- toyData$cleaned

rawS <- toyData$rawData

cleanToy <- clean.allData(genExpr=rawS$genExpr,
                          genExprSampleInfo=rawS$genExprSampleInfo, 
                          rawDnam=rawS$rawDnam, savePath=savePath, 
                          annLib="Auto", clinical=rawS$clinical, 
                          riskCatCol=riskCatCol, riskFactorCol=riskFactorCol, 
                          riskHigh="Poor", riskLow="Favorable", otherLabel=NULL, 
                          verbose=1)

print("Electing genes...")
elected <- elect.genes(genExpr=cleanToy$genExpr, dnam=cleanToy$dnam,
                       survival=cleanToy$survival, savePath=samplePath, event="Dead", 
                       locus2gene=cleanToy$locus2gene, doAlLoci=FALSE, verbose=1)

print("Computing eigenloci!!")
patientLabel <- setNames(as.character(cleanToy$survival$Risk1),
                         nm=rownames(cleanToy$survival))
inBoth <- intersect(colnames(cleanToy$dnam), names(patientLabel))
computedEloci <- compute.eigenloci(dnam=cleanToy$dnam[ ,inBoth], 
                                   geNames=elected$unionGenes,
                                   locus2gene=cleanToy$locus2gene, 
                                   Labels=patientLabel[names(patientLabel) %in% inBoth], 
                                   plotPath=samplePath, Label1="High", Label2="Low",
                                   genesColName="Gene_Symbol",
                                   coordinatesColName="Genomic_Coordinate",
                                   lociColName="probeID", dnamGene=NULL, 
                                   doDebug=FALSE, verbose=1)

eigenloci <- computedEloci$eigenloci
madeNetwork <- make.network(genExpr=cleanToy$genExpr, eigenloci=eigenloci,
                            geNames=elected$unionGenes, mus=0.6, 
                            doRemoveTOM=TRUE, outPath=netPath, 
                            minModuleSize=5, corMethod="pearson",
                            doReturNetworks=FALSE,  RsquaredCut=0.75, 
                            verbose=1)

eGenes <- combined.eigengenes(genExpr=cleanToy$genExpr, eigenloci=eigenloci, 
                              netPath=netPath, geNames=elected$unionGenes,
                              Labels=patientLabel, Label1="High", Label2="Low", 
                              mus=c(0.6), combiningMu=NA, 
                              survival=cleanToy$survival, event="Dead", 
                              verbose=1, mu2modules=madeNetwork$mu2modules)


if(dataProject=="TCGA-LAML"){
    toyRawAml <- toyData$rawData
    save.if(toyRawAml, file=file.path(iNETgrateDataPath, "toyRawAml.RData"))
    toyCleanedAml <- toyData$cleaned
    save.if(toyCleanedAml, file=file.path(iNETgrateDataPath, "toyCleanedAml.RData"))
    toyComputEloci <- computedEloci
    save.if(toyComputEloci, file=file.path(iNETgrateDataPath, "toyComputEloci.RData"))
    toyEigengenes <- get(load(file.path(netPath, "mu0.6/Pigen_e/eigengenes.RData")))
    save.if(toyEigengenes, file=file.path(iNETgrateDataPath, "toyEigengenes.RData"))
    packageData <- c("toyRawAml", "toyCleanedAml", "toyEigengenes", "toyEigenloci")
}

print(paste("Clinical and toy data will be saved at:", iNETgrateDataPath))

print(paste("Data sampling took:", Sys.time()-starTime))
beep(sound=8)