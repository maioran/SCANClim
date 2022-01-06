####################################################################################################
# SCAN-Clim
# Check if needed R packages are already installed and install them if needed
# The dplyr package is loaded anyway
####################################################################################################

#options("install.lock"=FALSE)

pkg <- c(#"cellranger",
         "httr",
         #"jpeg",
         "knitr",
         "lattice",
         "latticeExtra",
         "markdown",
         "raster",
         "rasterVis",
         "rgdal",
         #"RCurl",
         "readxl",
         #"RColorBrewer",
         "rlist",
         "rmarkdown",
         "sp",
         #"stringr",
         #"utf8",
         #"viridisLite",
         "XML")

for(current.pkg in pkg)
{
  if (!current.pkg %in% installed.packages())    
  {
    install.packages(current.pkg,   dependencies = TRUE) #, INSTALL_opts = '--no-lock')
  }
}

