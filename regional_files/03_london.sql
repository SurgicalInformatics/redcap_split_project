-- The project_id and DAG ID numbers within this script have been inserted using
-- a script, not by hand.
-- This script copies
-- All DAGs within this region
-- data from the original (full) project to:
-- 'CCP UK SARI - London'

-- this script copies specified records in redcap_record_list
-- from Source project to Target project
-- need to edit variables:
-- source_project = xx
-- target_project = yy
-- source DAG_ids = '1,2,3...'
-- (if using -- SET can only do one at a time)
-- After running this script, empty records (grey buttons)
-- should show up in the interface

-- -- SETs for TESTING only:
-- SET @source_project = 16;
-- SET @target_project = 39;
-- just Birmingham:
-- SET @DAG_id = 404;


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
          and target_dag.project_id = 52
          and source_record.dag_id in (45,74,75,98,114,132,140,145,153,168,192,224,271,278,287,300,312,338,368,551,712,748,760,804,937)
;

-- this script copies specified records in redcap_data
-- from Source project to Target project
-- need to edit:
-- @source_project = 64 -- Source project ID
-- @target_project = 68 -- Target project ID
-- @DAG_ids = (5319, 5457) -- DAG IDs in the source project owning records to be copied
-- The script will copy all records into the Target project
-- the scripts will be in appropriate DAGs, as that was already determined in redcap_record_list
-- but the interface will not present the DAG info, as that needs to be duplicately stored in redcap_data
-- as well, as is done in the next script.
-- The next script will move them into DAGs

-- -- SETs for TESTING only:
-- SET @source_project = 16;
-- SET @target_project = 39;
-- just Birmingham:
-- SET @DAG_id = 404;

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
  and target_arm.project_id = 52
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value in (45,74,75,98,114,132,140,145,153,168,192,224,271,278,287,300,312,338,368,551,712,748,760,804,937) -- DAG ID to copy
  ) and field_name != '__GROUPID__'
;
-- this script inserts the DAG info for each DAG into redcap_data
-- redcap_record_list already knows this info, but it must be duplicated for
-- the interface to work properly.
-- need to edit:
-- @source_project = 64 -- Source project ID
-- @target_project = 68 -- Target project ID
-- @DAG_ids = (5319, 5457) -- DAG IDs in the source project owning records to be copied

-- -- SETs for TESTING only:
-- SET @source_project = 16;
-- SET @target_project = 39;
-- just Birmingham:
-- SET @DAG_id = 404;

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
  and target_arm.project_id = 52
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value in (45,74,75,98,114,132,140,145,153,168,192,224,271,278,287,300,312,338,368,551,712,748,760,804,937) -- DAG IDs to copy
  ) and field_name = '__GROUPID__'
;
-- this script copies the users over to the new project
-- it updates the role_id as well as the group_id
-- this is the final script and project should be ready to go after this

-- -- SETs for TESTING only:
-- SET @source_project = 16;
-- SET @target_project = 39;
-- just Birmingham:
-- SET @DAG_id = 404;

-- SET @role_name = 'Data Entry';

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
where source_role.role_name = 'Data Entry'
      and source_dag.project_id = 16
      and target_dag.project_id = 52
      and source_rights.group_id in (45,74,75,98,114,132,140,145,153,168,192,224,271,278,287,300,312,338,368,551,712,748,760,804,937)
;