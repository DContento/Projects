#creating taylor rule with different parameters

#look at site for more info about rules and how they work

#A detailed discussion of the Taylor rule formula is provided in Principles for the Conduct of Monetary Policy. 
#The balanced-approach rule is similar to the Taylor rule except that the coefficient on the resource utilization
#gap is twice as large as in the Taylor rule.3 Thus, this rule puts more weight on stabilizing that gap than does 
#the Taylor rule--a distinction that becomes especially important in situations in which there is a
#conflict between inflation stabilization and output-gap stabilization. 

#The inertial rule prescribes a response of the federal funds rate to economic developments that is spread out over 
#time. For example, the response to a persistent upside surprise to inflation would gradually build over time, and the 
#federal funds rate would ultimately rise to the same level as under the balanced-approach rule.4 This kind of gradual 
#adjustment is a feature often incorporated into policy rules; it damps volatility in short-term interest rates. Some 
#authors have argued that such gradualism describes how the Federal Reserve has implemented adjustments to the federal 
#funds rate historically or how inertial behavior can be advantageous--for example, because it allows stabilizing the 
#economy with less short-term interest rate volatility.5

#https://www.federalreserve.gov/monetarypolicy/policy-rules-and-how-policymakers-use-them.htm

setwd("C:/Users/David/Desktop/Grad school work/403B/Final")
data=read.csv("403datasetremoved.csv")
attach(data)

#creating original (non-balanced taylor rule)
#got GDP Gap data from FRED 
#https://fred.stlouisfed.org/graph/?g=Fbu

#Coreinflation taken from FRED (Personal Consumption Expenditures excluding Food and Energy (chain-type price index)
#https://fred.stlouisfed.org/series/BPCCRO1Q156NBEA

inertial= NULL
baltaylor= NULL
baltaylorsmooth= NULL
ogtaylor=NULL
balogtaylor=NULL

#taylor from excel (inertial Rule)
for (i in 1:237){
  inertial[i]=0*laggedfedfunds[i]+(naturalint[i]+targetinf[i]+(1.5*(InflationPCE[i]-targetinf[i]))+.5*(gdpgap[i]))
}

#taylor rule balanced (inertial Rule)
for (i in 1:237){
  baltaylor[i]=0*laggedfedfunds[i]+(naturalint[i]+targetinf[i]+(.5*(InflationPCE[i]-targetinf[i]))+(gdpgap[i]))
}

#taylor rule balanced with interest rate smoothing parameter (inertial Rule)
for (i in 1:237){
  baltaylorsmooth[i]=.85*laggedfedfunds[i]+.15*(naturalint[i]+targetinf[i]+(.5*(InflationPCE[i]-targetinf[i]))+(gdpgap[i]))
}

#OG taylor rule
for (i in 1:237){
  ogtaylor[i]=Actual.Fed.Funds[i]+InflationPCE[i]+.5*(InflationPCE[i]-targetinf[i])+.5*(gdpgap)
}


#Balanced OG taylor rule
for (i in 1:237){
  balogtaylor[i]=Actual.Fed.Funds[i]+InflationPCE[i]+.5*(InflationPCE[i]-targetinf[i])+(gdpgap)
}



#which has the lowest error?

inertialerror=NULL
for (i in 1:237){
  inertialerror[i]=inertial[i]-Actual.Fed.Funds[i]
}

baltaylorerror=NULL
for (i in 1:237){
  baltaylorerror[i]=baltaylor[i]-Actual.Fed.Funds[i]
}

baltaylorsmootherror=NULL
for (i in 1:237){
  baltaylorsmootherror[i]=baltaylorsmooth[i]-Actual.Fed.Funds[i]
}

ogtaylorerror=NULL
for (i in 1:237){
  ogtaylorerror[i]=ogtaylor[i]-Actual.Fed.Funds[i]
}


balogtaylorerror=NULL
for (i in 1:237){
  balogtaylorerror[i]=balogtaylor[i]-Actual.Fed.Funds[i]
}


inertialerror=mean(abs(inertialerror))
baltaylorerror=mean(abs(baltaylorerror))
baltaylorsmootherror=mean(abs(baltaylorsmootherror))
ogtaylorerror=mean(abs(ogtaylorerror))
balogtaylorerror=mean(abs(balogtaylorerror))

print(inertialerror)
print(baltaylorerror)
print(baltaylorsmootherror)
print(ogtaylorerror)
print(balogtaylorerror)



