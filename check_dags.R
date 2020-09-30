library(tidyverse)

regions_lookup = read_csv("dags_regions.csv")

dags_today = read_delim("check_dags_29-Sep.txt", delim = "\t")

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


final_dags = regions_lookup %>% 
  filter(dag_label %in% dags_today$group_name |
           dag_label == "Queen Victoria Hospital")

final_dags %>% 
  count(nhs_region, name = "n_real_dags") %>% 
  mutate(total = sum(n_real_dags),
         to_be_removed = total-n_real_dags) %>% 
  drop_na() %>% 
  write_csv("dags_remove_count.csv")
