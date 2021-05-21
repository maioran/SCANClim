####################################################################################################
# EFSA Koppen-Geiger climate suitability tool
# This script connect to the EPPO REST-API to download pest host and distribution tables
# If a file is present in the REVIEW.Distribution table, then the file is used
####################################################################################################

# test if any file is present in the REVIEW.Distribution and in the REVIEW.Climates folder. 
if(length(list.files(paste(review.dir,"REVIEW.Climate\\",sep="")))!=0)
{
  climate.available <- TRUE
}else
{
  climate.available <- FALSE
}

# check if any file present in Distribution folder. Otherwise it connects to EPPO
if(length(list.files(paste(review.dir,"\\REVIEW.Distribution\\",sep="")))==0)
{
  # Connect to EPPO server and retrieve EPPO pest code
  path.eppo.code    <- "https://data.eppo.int/api/rest/1.0/tools/names2codes"
  response          <- httr::POST(path.eppo.code, body=list(authtoken=i.EPPO.thoken,intext=pest.name))
  pest.eppo.code    <- strsplit(httr::content(response)[[1]], ";")[[1]][2]
  
  if(pest.eppo.code == "****NOT FOUND*****")
  {
    print("****** WARNING: PEST NAME NOT FOUND IN THE EPPO DATABASE ******")
    distr.table <- FALSE
    
  }else
  {
    ########### DISTRIBUTION ################
    # retrieve EPPO pest distribution table
    eppo.pest.distr.url <- RCurl::getURL(paste("https://gd.eppo.int/taxon/", pest.eppo.code,"/distribution", sep=""))#, .opts = list(ssl.verifypeer = FALSE))
    # tables <- XML::readHTMLTable(eppo.pest.distr.url) %>%
    #   rlist::list.clean(fun = is.null, recursive = FALSE)
    tables <- XML::readHTMLTable(eppo.pest.distr.url)
    tables <- rlist::list.clean(tables, fun = is.null, recursive = FALSE)
    if(length(tables) != 0)
    {
      # clean EPPO table
      # select according to Status
      # save full table from EPPO
      write.csv(tables$dttable, row.names = FALSE, paste(output.dir, "\\Distribution\\Full.distribution.table_",actual.date,".csv", sep=""))
      # keep only records including only relevant EPPO pest status 
      pest.kg.table     <- tables$dttable[which(tables$dttable$Status %in% i.pest.status),]
      pest.kg.table <- pest.kg.table[order(pest.kg.table$Country),]
      # In the case of big countries (e.g. US, Canada, Australia, China...), if many entries exist 
      # with further indication of states (e.g. Alabama in US) remove the first record
      # with only the name of the country 
      record.remove <- c()
      for(i in 2:nrow(pest.kg.table))
      {#i=8
        if(pest.kg.table$Country[i] == pest.kg.table$Country[i-1] &
           pest.kg.table$State[i-1]=="")
        {
          record.remove <- c(record.remove, i-1)
        }
        
      }
      # remove records (see above)
      pest.kg.table <- pest.kg.table[-record.remove,]
      # be sure that columns are type "character"
      pest.kg.table     <- data.frame(lapply(pest.kg.table, as.character), stringsAsFactors=FALSE)[,1:4]
      pest.kg.table$Observation <- NA
      pest.kg.table[which(pest.kg.table$State!=""),"Observation"] <- paste(pest.kg.table$Country[which(pest.kg.table$State!="")],
                                                                            pest.kg.table$State[which(pest.kg.table$State!="")],
                                                                            sep="-")
      pest.kg.table[which(pest.kg.table$State==""),"Observation"] <- pest.kg.table$Country[which(pest.kg.table$State=="")]
      
      # # add supporting column for countries/states
      # pest.kg.table$Observation                               <- pest.kg.table$State
      # pest.kg.table$Observation[which(pest.kg.table$Observation=="")] <- pest.kg.table$Country[which(pest.kg.table$Observation=="")]
      # 
      # # filter info according to states of big countries
      # big.countries <- c("United States of America", "Brazil", "Russia", "China", "India", "Canada", "Australia")
      # if(any(big.countries %in% pest.kg.table$Observation))
      # {
      #   pest.kg.table     <- pest.kg.table[-which(pest.kg.table$Observation %in% big.countries),]
      # }
      
      # add columns including administrative boundary source and level. This is needed especially in the phase of review of climates
      pest.kg.table$admin.level  <- "0"
      pest.kg.table$admin.source <- "EPPO"
      pest.kg.table$admin.code   <- NA
      pest.kg.table$lat          <- NA
      pest.kg.table$long         <- NA
      
      # save table including list of filtered distribution
      write.csv(pest.kg.table, row.names = FALSE, paste(output.dir, "\\Distribution\\Filtered.distribution.table_",actual.date,".csv", sep=""))
      
      rm(path.eppo.code, response, eppo.pest.distr.url, tables, record.remove)
      distr.table <- TRUE
    }else
    {
      print(paste0("****** WARNING: Distribution table for ", pest.name, " not available in the EPPO database"))
      distr.table <- FALSE
    }
    
  }
  
  
}else
{
  # if table with reviewed distribution is available it is loaded
 rev.distr      <- list.files(paste(review.dir,"\\REVIEW.Distribution\\",sep=""))
 pest.kg.table  <- read.csv(paste(review.dir,"\\REVIEW.Distribution\\", rev.distr, sep=""), stringsAsFactors = FALSE, na.strings = c("na", "NA", ""))
 
 if(any(grepl('ï..', colnames(pest.kg.table), fixed = TRUE)))
 {
   colnames(pest.kg.table) <- gsub('ï..', '', colnames(pest.kg.table))
 }
 distr.table <- TRUE
 
  rm(rev.distr)
}


