library(tidyverse)
library(glue)
library(snakecase)

# source project ID:
source_id = 16
# most target projects not created yet (except 37 North West and 39 West Midlands, testing only)
regional_projects = tribble(~nhs_region, ~target_id,
                            "North West", 37,
                            "West Midlands", 39)


# read in SQL templates include R-glue placeholders: {} ----
sql_01 = read_file("01_redcap_record_list_copy.sql")
sql_02 = read_file("02_redcap_data_copy.sql")
sql_03 = read_file("03_redcap_data_add_GROUPID.sql")
sql_04 = read_file("04_redcap_user_rights.sql")

# modify a bit to make work together all in one:
# some comments still conflicting/meant for running as separate scripts so watch out
preamble = "
-- The project_id and DAG ID numbers within this script have been inserted using
-- a script, not by hand.
-- This script copies
-- {DAG_name}
-- data from the original (full) project to:
-- 'CCP UK SARI - {nhs_region}'
"
sql = paste(preamble, sql_01, sql_02, sql_03, sql_04, sep = "\n") %>% 
  # commenting out SET lines and replacing with R glue
  str_replace_all("SET", "-- SET") %>% 
  str_replace_all("= @DAG_id", "in ({DAG_id})") %>% 
  str_replace_all("= @source_project", "= {source_id}") %>% 
  str_replace_all("= @target_project", "= {target_id}") %>% 
  str_replace_all("= @role_name", "= 'Data Entry'")



# create an SQL file for each region:
system("mkdir regional_files")
regions_lookup = read_csv("dags_regions.csv")

for (myregion in regional_projects$nhs_region){
  print(myregion)
  target_id = regional_projects %>% 
    filter(nhs_region == myregion) %>% 
    pull(target_id)
  
  do_region = regions_lookup %>% 
    filter(nhs_region == myregion) %>%
    select(nhs_region, DAG_name = dag_label, DAG_id = group_id)
  
  all_dags_within_region = do_region %>% 
    pull(DAG_id) %>% 
    paste(collapse = ",")
  
  all_in_one = tibble(source_project = source_id,
                      target_project = target_id,
                      nhs_region = myregion, 
                      DAG_id = all_dags_within_region,
                      DAG_name = "All DAGs within this region",
                      sql = sql) %>% 
    mutate(sql_alldags = glue(sql))
  
  
  all_in_one %>% 
    pull(sql_alldags) %>% 
    write_file(paste0("regional_files/", to_snake_case(myregion), ".sql"))
  
  
}


















