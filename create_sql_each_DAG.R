library(tidyverse)
library(glue)
library(snakecase)

# source project ID:
source_id = 16
# most target projects not created yet (except 37 North West and 39 West Midlands, testing only)

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
regions_lookup_orig = read_csv("dags_regions.csv")
dags_today = read_delim("check_dags_29-Sep.txt", delim = "\t")


regions_lookup = regions_lookup_orig %>% 
  filter(dag_label %in% dags_today$group_name)

regions_lookup %>% 
  distinct(nhs_region) %>% 
  pull(nhs_region)

# regional_projects = tibble(nhs_region = regions_lookup %>% 
#                              distinct(nhs_region) %>% 
#                              pull(nhs_region),
#                            target_id = 50:60)

regional_projects = tibble(nhs_region = "Northern Ireland",
                           target_id = 62)

id = 1
# regional_projects %>% 
#   rowid_to_column() %>% 
#   mutate(rowid = formatC(rowid, width = 2, flag = "0")) %>% 
#   mutate(name = paste("ccp", rowid, to_snake_case(nhs_region), sep = "_") %>% paste("=")) %>%
#   select(name)

for (myregion in regional_projects$nhs_region){
  fileid = formatC(id, width = 2, flag = "0")
  print(myregion)
  target_id = regional_projects %>% 
    filter(nhs_region == myregion) %>% 
    pull(target_id)
  
  do_region = regions_lookup %>% 
    filter(nhs_region == myregion) %>%
    arrange(group_id) %>% 
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
    write_file(paste0("fix/", fileid,"_",to_snake_case(myregion), ".sql"))
  id = id + 1
  
  
}


















