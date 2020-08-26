-- The project_id and DAG ID numbers within this script have been inserted using
-- a script, not by hand.
-- This script copies
-- Countess Of Chester Hospital
-- data from the original (full) project to:
-- 'CCP UK SARI - North West'


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
        where source_dag.project_id = 16
          and target_dag.project_id = 37
          and source_record.dag_id = 236


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
where source_arm.project_id = 16
  and target_arm.project_id = 37
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value = 236 -- DAG IDs to copy
  ) and field_name != '__GROUPID__'


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
where source_arm.project_id = 16
  and target_arm.project_id = 37
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value = 236-- DAG IDs to copy
  ) and field_name = '__GROUPID__'


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
      and source_dag.project_id = 16
      and target_dag.project_id = 37
      and source_rights.group_id = 236
;