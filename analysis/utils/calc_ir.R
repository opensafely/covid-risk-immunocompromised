## ###########################################################

##  This script:
## - Function to calculate incidence rate per 1000 person-years

## linda.nab@thedatalab.com - 20220615
## ###########################################################
library(dplyr)
library(tibble)
library(here)
source(here("analysis", "utils", "dsr.R"))

# Function 'calc_ir' calculation of incidence rate per 1000 py + 95% CIs
# Arguments:
# events: integer with number of events (e.g. number of deaths in wave)
# time: follow up in days
# Output:
# data.frame with columns rate, lower and upper 
calc_ir <- function(events, time, name = ""){
  rate <- events / time
  ir <- calc_dsr_i(365250, 1, rate, 1)
  var_ir <- calc_var_dsr_i(365250, 1, rate, 1, time)
  lower <- ir - qnorm(0.975) * sqrt(var_ir)
  upper <- ir + qnorm(0.975) * sqrt(var_ir)
  out <- data.frame(ir = round(ir,1), 
                    ir_lower_ci = round(lower,1), 
                    ir_upper_ci = round(upper,1))
  colnames(out) <- paste0(colnames(out), name)
  out
}
