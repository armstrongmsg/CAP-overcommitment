library(dplyr)
library(ggplot2)
library(reshape2)

data <- read.csv("results.csv")

data$cap_a <- as.factor(data$cap_a)
data$cap_b <- as.factor(data$cap_b)

conf.intervals <- data %>% group_by(cap_a, cap_b) %>% summarise(mean_time_a = mean(total_time_a),
                                              mean_time_b = mean(total_time_b),
                                              lower_time_a = wilcox.test(total_time_a, conf.int = TRUE)$conf.int[1],
                                              upper_time_a = wilcox.test(total_time_a, conf.int = TRUE)$conf.int[2],
                                              lower_time_b = wilcox.test(total_time_b, conf.int = TRUE)$conf.int[1],
                                             upper_time_b = wilcox.test(total_time_b, conf.int = TRUE)$conf.int[2]) 

set1 <- subset(conf.intervals, select = c(cap_a, cap_b, mean_time_b, lower_time_b, upper_time_b))
set1$instance = rep("B", 9)
colnames(set1) <- c("cap_a", "cap_b", "mean_time", "lower_time", "upper_time", "instance")

set2 <- subset(conf.intervals, select = c(cap_a, cap_b, mean_time_a, lower_time_a, upper_time_a))
set2$instance = rep("A", 9)
colnames(set2) <- c("cap_a", "cap_b", "mean_time", "lower_time", "upper_time", "instance")

final_intervals <- rbind(set1, set2)
final_intervals$case <- c(paste(as.character(final_intervals$cap_a),as.character(final_intervals$cap_b), sep = "-"))

limits <- aes(ymax = final_intervals$upper_time, ymin = final_intervals$lower_time)

ggplot(final_intervals, aes(x=case, y=mean_time, color = instance)) + 
  geom_point() + 
  geom_errorbar(limits)
