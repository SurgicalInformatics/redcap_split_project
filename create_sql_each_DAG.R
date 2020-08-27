library(tidyverse)
library(glue)
library(snakecase)

# read in SQL templates include R-glue placeholders: {} ----
sql_01 = "
----------
-- 01_redcap_record_list_copy.sql
----------
insert into redcap_record_list
select target_dag.project_id,
       source_record.arm,
       source_record.record,
       target_dag.group_id,
       source_record.sort
  from redcap_record_list source_record
    inner join redcap_data_access_groups source_dag on source_dag.group_id = source_record.dag_id
    inner join redcap_data_access_groups target_dag on target_dag.group_name = source_dag.group_name
        where source_dag.project_id = {source_project}
          and target_dag.project_id = {target_project}
          and source_record.dag_id = {DAG_id}
;
"

sql_02 = "
----------
-- 02_redcap_data_copy.sql
----------
insert into redcap_data
select target_arm.project_id,
       target_event.event_id,
       record.record,
       record.field_name,
       record.value,
       record.instance

-- Source record data
from redcap_data record

-- Get the source project's arms
inner join redcap_events_arms source_arm
        on source_arm.project_id = record.project_id

-- Match the target project's arms to source
inner join redcap_events_arms target_arm
        on target_arm.arm_num = source_arm.arm_num

-- Get the source project's events
inner join redcap_events_metadata source_event
        on source_event.arm_id = source_arm.arm_id
       and source_event.event_id = record.event_id

-- Match the target project's events to source
inner join redcap_events_metadata target_event
        on target_event.descrip = source_event.descrip
       and target_event.arm_id = target_arm.arm_id

-- Input parameters
where source_arm.project_id = {source_project}
  and target_arm.project_id = {target_project}
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value = {DAG_id} -- DAG IDs to copy
  ) and field_name != '__GROUPID__'
;
"

sql_03 = "
----------
-- 03_redcap_data_add_GROUPID.sql
----------
insert into redcap_data
select target_arm.project_id,
       target_event.event_id,
       record.record,
       record.field_name,
       target_list.dag_id,
       record.instance

-- Source record data
from redcap_data record

-- Get the source project's arms
inner join redcap_events_arms source_arm
        on source_arm.project_id = record.project_id

-- Match the target project's arms to source
inner join redcap_events_arms target_arm
        on target_arm.arm_num = source_arm.arm_num

-- Get the source project's events
inner join redcap_events_metadata source_event
        on source_event.arm_id = source_arm.arm_id
       and source_event.event_id = record.event_id

-- Match the target project's events to source
inner join redcap_events_metadata target_event
        on target_event.descrip = source_event.descrip
       and target_event.arm_id = target_arm.arm_id

-- Match the target projec's record list to find the new dag
inner join redcap_record_list target_list
        on target_list.arm = target_arm.arm_num
       and target_list.project_id = target_arm.project_id
       and target_list.record = record.record

-- Input parameters
where source_arm.project_id = {source_project}
  and target_arm.project_id = {target_project}
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value = {DAG_id}-- DAG IDs to copy
  ) and field_name = '__GROUPID__'
;
"

sql_04 = "
----------
-- 04_redcap_user_rights.sql
----------
SET @role_name = 'Data Entry';
insert into redcap_user_rights
(
    project_id,
    username,
    role_id,
    group_id
)
select  target_dag.project_id,
        source_rights.username,
        target_role.role_id,
        target_dag.group_id
from redcap_user_rights source_rights
-- Filter based on roles
inner join redcap_user_roles source_role
        on source_role.role_id = source_rights.role_id
-- Filter based on group
inner join redcap_data_access_groups source_dag
        on source_dag.group_id = source_rights.group_id
-- Find target group and project
inner join redcap_data_access_groups target_dag
        on target_dag.group_name = source_dag.group_name
-- Find target role
inner join redcap_user_roles target_role
        on target_role.role_name = source_role.role_name
       and target_role.project_id = target_dag.project_id
-- Parameters
where source_role.role_name = @role_name
      and source_dag.project_id = {source_project}
      and target_dag.project_id = {target_project}
      and source_rights.group_id = {DAG_id}
;
"

# glue together with the DAG IDs (and project IDs)
preamble = "
-- The project_id and DAG ID numbers within this script have been inserted using
-- a script, not by hand.
-- This script copies
-- {DAG_name}
-- data from the original (full) project to:
-- 'CCP UK SARI - {nhs_region}'
"
sql = paste(preamble, sql_01, sql_02, sql_03, sql_04, sep = "\n")


myregion = "North West"
mysource = 16
mytarget = 37


#regions_lookup = read_csv("dags_regions.csv")
regions_lookup = read_csv("https://raw.githubusercontent.com/SurgicalInformatics/redcap_split_project/153fdbcaa874759ac084e437a6ac59fd313698bb/dags_regions.csv")

do_region = regions_lookup %>% 
  filter(nhs_region == myregion) %>% 
  select(nhs_region, DAG_name = redcap_data_access_group_label, DAG_id = data_access_group_id) %>% 
  mutate(source_project = mysource, target_project = mytarget,
         sql_onedag = glue(sql),
         filename = paste0(to_snake_case(DAG_name), ".sql"))

system(paste("mkdir", to_snake_case(myregion)))
for (myfilename in do_region$filename){
  print(myfilename)
  do_region %>%
    filter(filename == myfilename) %>%
    pull(sql_onedag) %>%
    write_file(paste(to_snake_case(myregion), myfilename, sep = "/"))
}




















