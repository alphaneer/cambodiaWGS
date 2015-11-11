## R script to plot LD by CP group, and bootstraps for CI
## Started 5 November 2015
## Christian Parobek

####################################
######### DEFINE FUNCTIONS #########
####################################

# Function calculates distance, plots a decay line
plot.bin <- function(LDdf, nbins, binsize, color) {
  
  offset <- binsize - 1
  
  LDdf$diff <- LDdf$POS2-LDdf$POS1 # calculate the distance for each SNP
  #sorted <- LDdf[order(LDdf$diff),] # sort it
  
  xline <- NULL
  yline <- NULL
  
  for (window in 1:nbins*binsize) {
    xline <- append(xline, window)
    yline <- append(yline, mean(LDdf[LDdf$diff >= offset & LDdf$diff < window,]$R.2, na.rm = TRUE))
  }
  lines(xline, yline, col = color, lwd = 2)
}

# Function calculates distance, sorts, fits a regression, and plots
plot.fit <- function(LDdf, deg_poly, color) {
  
  LDdf$diff <- LDdf$POS2-LDdf$POS1 # calculate the distance for each SNP
  sorted <- LDdf[order(LDdf$diff),] # sort it
  fit <- lm(sorted$R.2 ~ poly(sorted$diff, deg_poly, raw=TRUE))
  lines(sorted$diff, predict(fit, data.frame(x=sorted$diff)), col=color)
  
} 

# Function plots a shaded curve following min and max boot values
plot.boot <- function(bootstrap_files, nbins, binsize, shadecolor) {
  
  bootvalues <- unlist(lapply(bootstrap_files, function(x) mean(x$R.2, na.rm = TRUE)))
  the_max <- which.max(bootvalues)
  the_min <- which.min(bootvalues)
  
  xline <- NULL
  for (window in 1:nbins*binsize) {
    xline <- append(xline, window)
  }
  
  upper <- boot.outline(bootstrap_files[[the_max]], nbins, binsize)
  lower <- boot.outline(bootstrap_files[[the_min]], nbins, binsize)
  
  polygon(c(xline, rev(xline)), c(upper, rev(lower)), col = shadecolor, border = NA)
}

# Accessory function to plot.boot - returns a vector of r2 values
boot.outline <- function(LDdf, nbins, binsize) {
  
  offset <- binsize - 1
  
  LDdf$diff <- LDdf$POS2-LDdf$POS1 # calculate the distance for each SNP
  #sorted <- LDdf[order(LDdf$diff),] # sort it
  
  yline <- NULL
  
  for (window in 1:nbins*binsize) {
    yline <- append(yline, mean(LDdf[LDdf$diff >= offset & LDdf$diff < window,]$R.2, na.rm = TRUE))
  }
  return(yline)
}


####################################
############ INPUT DATA ############
####################################

ld1 <- read.table("pointestimates/ld/cp1.ld.1-20000.hap.ld", header = TRUE)
ld2 <- read.table("pointestimates/ld/cp2.ld.1-20000.hap.ld", header = TRUE)
ld3 <- read.table("pointestimates/ld/cp3.ld.1-20000.hap.ld", header = TRUE)
ld4 <- read.table("pointestimates/ld/cp4.ld.1-20000.hap.ld", header = TRUE)

# optional to convert NaN to 1
ld1$R.2[is.nan(ld1$R.2)] <- 1
ld2$R.2[is.nan(ld2$R.2)] <- 1
ld4$R.2[is.nan(ld4$R.2)] <- 1


bootstrap_names <- list.files("bootstrap/ld", pattern="*hap.ld", full.names=TRUE)
bootstrap_files <- lapply(bootstrap_names, read.table, header = TRUE)


####################################
############# PLOT IT ##############
####################################

## Setup plot coordinates
plot(ld2$POS2-ld2$POS1, ld2$R.2, 
     type = "n", xlim = c(0,200000), axes = FALSE, 
     xlab = "Coordinate Distance between SNPs", ylab = expression(r^2))
axis(1)
axis(2, las = 2)

## Plot bootstraps
plot.boot(bootstrap_files, 200, 1000, "lightgray") # plot shaded outline of max and min
#mapply(plot.bin, bootstrap_files, 100, 200, "gray") # plot individuals

## Plot pointestimates
plot.bin(ld1, 200, 1000, "red")
plot.bin(ld2, 200, 1000, "red")
#plot.bin(ld3, 200, 1000, "red")
plot.bin(ld4, 200, 1000, "red")



mapply(mean, bootstrap_files)

