library(tidyverse)
library(rvest)
library(readr)
library(dplyr)
library(ggplot2)


# reading csv file containing dataset of all ranked nations in FIFA ranking between 1992 - 2022 (last_updated 20221222)
# source: https://www.kaggle.com/datasets/cashncarry/fifaworldranking?resource=download
fifa <- read_csv("Documents/Rstudio/fifa_ranking-2022-12-22.csv")

# only selecting nation names and its FIFA confederation for later use
fifa_2022<-fifa[fifa$rank_date == "2022-12-22",] %>%
           rename(Opponent = country_full, Confederation = confederation) %>%
              select(2,7)

# webscraping messi's goal data from wikipedia
url = "https://en.wikipedia.org/wiki/List_of_international_goals_scored_by_Lionel_Messi"

scrape_data <- url %>% 
                read_html() %>%
                  html_node(xpath = '//*[@id="mw-content-text"]/div[1]/table[2]') %>%
                    html_table(fill = TRUE) %>%
                      data.frame()

new_scrape_data <- scrape_data[1:8] # removing last column which is just a reference link to the match



# creating a table of opponents Messi has scored against, and how many times he was scored, while playing with Argentina NT
goals <- new_scrape_data %>%
            group_by(Opponent) %>%
              summarize(goals_against = n()) %>%
                arrange(desc(goals_against)) %>%
                  left_join(fifa_2022, by = "Opponent")


# clean the dataset for any mistakes of missing values
goals %>%
  filter(is.na(Confederation))  #shows 3 nation have "NA" as confederation after joining fifa_2022 dataset
  
# adding confederations to nations with NA
goals[36,3] = "CONCACAF"
goals[28,3] = "AFC"
goals[33,3] = "UEFA"

# grouping by goals scored against each confederation
goals_against_conf <- goals %>%
  group_by(Confederation) %>%
    summarize(nations = n())


goals_against_nation <- goals %>%
  group_by(Confederation) %>%
    summarize(nation = Opponent)


# grouping by goals scored in each competition

goal_comp <- new_scrape_data %>%
              group_by(Competition) %>%
                summarize(goals_in_comp = n()) %>%
                  arrange(desc(goals_in_comp))


# visualizing the data  

# linechart
ggplot(new_scrape_data, aes(x = Cap, y = No.)) +
  geom_line() + 
  xlab("No. of cap") + 
  ylab("No. of goal(s)") + 
  annotate("text", x = 120, y = 20, label = "Goal ratio = 0.57") + 
  geom_vline(aes(xintercept = new_scrape_data[97,2]), linetype = "dashed") +
  geom_vline(aes(xintercept = new_scrape_data[2,2]), linetype = "dashed") +
  geom_vline(aes(xintercept = new_scrape_data[5,2]), linetype = "dashed") +
  geom_vline(aes(xintercept = new_scrape_data[20,2]), linetype = "dashed") +
  geom_vline(aes(xintercept = new_scrape_data[82,2]), linetype = "dashed") +
  geom_text(aes(new_scrape_data[2,2]), label = "First WC goal", y = 30) +
  geom_text(aes(new_scrape_data[97,2], label = "2022 WC Final", y = 100)) + 
  geom_text(aes(new_scrape_data[5,2], label = "First CA goal", y = 50)) +
  geom_text(aes(new_scrape_data[20,2], label = "First INT hattrick", y = 60)) + 
  geom_text(aes(new_scrape_data[82,2], label = "5 Goals in 1 game", y = 70))

# barchart of goals scored against
ggplot(goals, aes(x = Opponent, y = goals_against)) + 
  geom_col() + 
  labs(x = NULL, y = "Goals against opponent") +
  theme(axis.text.x = element_text(angle = 90, hjust = 0.5, vjust = 0.5)) 
  
  
# piechart(# of nations he has scored against from each confederation)
ggplot(goals_against_conf, aes(x="", y=nations, fill=Confederation)) +
  geom_bar(stat="identity", width=1) +
  geom_text(aes(label = nations), 
                position = position_stack(vjust = 0.5)) +
  coord_polar("y", start=0) + 
  theme_void() + 
  scale_fill_brewer()


