library(tidyverse)

regions_lookup_orig = read_csv("dags_regions.csv")

dags_today = read_delim("check_dags_29-Sep.txt", delim = "\t")

add_missing = tibble(dag_label = "Northamptonshire Healthcare Foundation Trust",
                     nhs_region = "East Midlands",
                     group_id = 2475)

regions_lookup = bind_rows(regions_lookup_orig, add_missing)

not_in_lookup = dags_today %>% 
  filter(! group_name %in% regions_lookup$dag_label)

not_in_project = regions_lookup %>% 
  filter(! dag_label %in% dags_today$group_name)


dags_to_be_moved = regions_lookup %>% 
  filter(dag_label %in% dags_today$group_name)

# check that GROUP IDs have not changed
dags_today %>% 
  left_join(regions_lookup, by = c("group_name" = "dag_label")) %>% 
  filter(group_id.x != group_id.y)

