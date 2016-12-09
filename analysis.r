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

# -----------------------------------------------------------------------------------
# Question 2
# -----------------------------------------------------------------------------------


# -----------------------------------------------------------------------------------
# Cases 1,2 and 3
# -----------------------------------------------------------------------------------

final_intervals123 <- final_intervals %>% filter(case %in% c("100-50", "100-100", "100-30", "50-50", "80-20"))

limits <- aes(ymax = final_intervals123$upper_time, ymin = final_intervals123$lower_time)

ggplot(final_intervals123, aes(x=case, y=mean_time, color = instance)) + 
  geom_point() + 
  geom_errorbar(limits)

ggsave("results123.png")

# -----------------------------------------------------------------------------------
# Cases 4,5 and 6
# -----------------------------------------------------------------------------------

final_intervals456 <- final_intervals %>% filter(case %in% c("30-30", "50-30", "80-60"))

limits <- aes(ymax = final_intervals456$upper_time, ymin = final_intervals456$lower_time)

ggplot(final_intervals456, aes(x=case, y=mean_time, color = instance)) + 
  geom_point() + 
  geom_errorbar(limits)

ggsave("results456.png")

# -----------------------------------------------------------------------------------
# Different CAPs over 100%
# ----------------------------------------------------------------------------------

final_intervals_over100_1 <- final_intervals %>% filter(case %in% c("100-100", "100-50", "100-30"))

limits <- aes(ymax = final_intervals_over100_1$upper_time, ymin = final_intervals_over100_1$lower_time)

ggplot(final_intervals_over100_1, aes(x=case, y=mean_time, color = instance)) + 
  geom_point() + 
  geom_errorbar(limits)

ggsave("results_over100_1.png")

final_intervals_over100_2 <- final_intervals %>% filter(case %in% c("80-60", "80-20"))

limits <- aes(ymax = final_intervals_over100_2$upper_time, ymin = final_intervals_over100_2$lower_time)

ggplot(final_intervals_over100_2, aes(x=case, y=mean_time, color = instance)) + 
  geom_point() + 
  geom_errorbar(limits)

ggsave("results_over100_2.png")

final_intervals_over100_3 <- final_intervals %>% filter(case %in% c("100-100", "100-50", "50-50", "80-60"))

limits <- aes(ymax = final_intervals_over100_3$upper_time, ymin = final_intervals_over100_3$lower_time)

ggplot(final_intervals_over100_3, aes(x=case, y=mean_time, color = instance)) + 
  geom_point() + 
  scale_y_continuous(limits = c(26,31)) +
  geom_errorbar(limits)

ggsave("results_over100_3.png")

# -----------------------------------------------------------------------------------
# CAP effect comparison
# ----------------------------------------------------------------------------------

final_intervals_capcomparison <- final_intervals %>% filter(case %in% c("30-30", "50-30", "100-100", "100-50", "50-50", "80-60", "80-20"))

final_intervals_capcomparison$case2 <- factor(final_intervals_capcomparison$case, levels = c("30-30", "50-30", "50-50", "80-20", "80-60", "100-50", "100-100"))
limits <- aes(ymax = final_intervals_capcomparison$upper_time, ymin = final_intervals_capcomparison$lower_time)

ggplot(final_intervals_capcomparison, aes(x=case2, y=mean_time, color = instance)) + 
  geom_point() + 
  geom_errorbar(limits)

ggsave("results_capeffect_comparison.png")

ggsave("results.png")
