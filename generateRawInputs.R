
library(data.table)
library(plyr)
library(fasttime)

# Method used to generate a raw_input dataset compatible with the deepforex RNN
# from a given input folder
generateRawInputs <- function(path = "2015_12",symbols=NULL, suffix = "", startOffset=NULL, period=NULL)
{
  if(is.null(symbols)) {
    print("Using default input symbol list.")
    symbols = c("EURUSD","AUDUSD","GBPUSD","NZDUSD","USDCAD","USDCHF","USDJPY")
    #symbols = c("EURUSD","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD")
    #symbols = c("EURUSD")
  }
  # period to consider:
  if(is.null(period))
  {
    period <- "M1"  
  }

  result <- NULL
  
  for(sym in symbols)
  {
    dpath <- paste0("inputs/",path,"/",sym,"_",period,suffix,".csv")
    
    # load the dataset:
    print(paste0("Loading dataset ",dpath,"..."))
    
    # Note that we discard the volume column here:
    data <- fread(dpath,select=c(1,2,6))
    
    # rename the columns of the dataset:
    sname <- tolower(sym)
    
    names(data) <- c("date","time",paste0(sname,"_close"))
  
    nrows <- dim(data)[1]
    print(paste0("Read ", nrows," for symbol ", sym))
    
    if(is.null(result)) 
    {
      result <- data
    }
    else
    {
      print("Merging datasets...")
      result <- merge(result,data,by=c("date","time"))
    }
  }
  
  # Add the timetags:
  datetimes <- paste(result$date,result$time)
  
  # convert the date time cols:
  data <- finalizeDataset(result)
  
  data$date <- as.numeric(as.POSIXct(datetimes,format = "%Y.%m.%d %H:%M"))
  
  names(data)[1] <- "timetag"
  
  #setcolorder(data,c(1,nc,2:(nc-1)))
  
  len <- dim(data)[1]

    # discard some rows if requested:
  if(!is.null(startOffset))
  {
    data <- data[startOffset:len,]  
  }
  
  len <- dim(data)[1]
  
  # Write the data file:
  # write the input dataset:
  # Note that we do not write the dates in this file:
  #write.csv(data[,-c("date"),with=F],paste0("inputs/",path,"/raw_inputs.csv"),row.names=F)
  write.csv(data,paste0("inputs/",path,"/raw_inputs.csv"),row.names=F)
  
  
  cfgfile <- paste0("inputs/",path,"/","dataset.lua") 
  cat("return {", file=cfgfile, sep="\n")
  cat(paste0("\tnum_samples = ",len,","), file=cfgfile, sep="\n", append=T)
  cat(paste0("\tnum_inputs = ",(dim(data)[2]-1),","), file=cfgfile, sep="\n", append=T)
  cat("}", file=cfgfile, sep="\n", append=T)
  
  data
}