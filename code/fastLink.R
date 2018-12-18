#################################################################
###                                                           ###
###            Accuracy Tests MI Voter - birthyear            ###
###                                                           ###
#################################################################
#adapted from: https://cran.r-project.org/web/packages/fastLink/index.html

library(fastLink)
library(stringi)
setwd("Data Linking")

#Read in datasets
dfA=read.csv("2015_byear.csv", stringsAsFactors = F)
dfB=read.csv("2017_byear.csv", stringsAsFactors = F)

#Trim white space from fields to be used for matching
dfA$fname=stri_trim_both(dfA$fname)
dfA$mname=stri_trim_both(dfA$mname)
dfA$lname=stri_trim_both(dfA$lname)
dfA$byear=stri_trim_both(dfA$byear)
dfA$gender=stri_trim_both(dfA$gender)
dfA$streetnum=stri_trim_both(dfA$streetnum)
dfA$street=stri_trim_both(dfA$street)
dfA$city=stri_trim_both(dfA$city)
dfA$zip=stri_trim_both(dfA$zip)

dfB$fname=stri_trim_both(dfB$fname)
dfB$mname=stri_trim_both(dfB$mname)
dfB$lname=stri_trim_both(dfB$lname)
dfB$byear=stri_trim_both(dfB$byear)
dfB$gender=stri_trim_both(dfB$gender)
dfB$streetnum=stri_trim_both(dfB$streetnum)
dfB$street=stri_trim_both(dfB$street)
dfB$city=stri_trim_both(dfB$city)
dfB$zip=stri_trim_both(dfB$zip)

#set 2 match thresholds: .85 and .99; specify fields to link on: 
thresh=c(.85, .99)
for (x in thresh){
  matches.out = fastLink(
    dfA = dfA, dfB = dfB,
    varnames = c("lname", "fname", "mname", "byear", "gender", "streetnum", "street", "city", "zip"),
    stringdist.match = c("lname", "fname", "mname", "byear", "gender", "streetnum", "street", "city", "zip"),
    threshold.match = x, dedupe.matches = T, verbose = T
  )

  dfA.pair <- dfA[matches.out$matches$inds.a,]
  names=colnames(dfA.pair)
  names_A=paste(names, "A", sep = "_")
  colnames(dfA.pair)=names_A

  dfB.pair <- dfB[matches.out$matches$inds.b,]
  names_B=paste(names, "B", sep = "_")
  colnames(dfB.pair)=names_B

#output matches: 
  match_pairs = cbind(dfA.pair, dfB.pair)
  match_pairs$true_match=match_pairs$voterid_A==match_pairs$voterid_B
  match_pairs$false_positive=match_pairs$voterid_A!=match_pairs$voterid_B
  match_pairs=cbind(match_pairs,matches.out$posterior)
  colnames(match_pairs)[colnames(match_pairs) == "matches.out$posterior"] <- "posterior"
  write.csv(match_pairs, paste("fastLink/20181211MIbyear_match_pairs_", x,".csv", sep=""))
}
