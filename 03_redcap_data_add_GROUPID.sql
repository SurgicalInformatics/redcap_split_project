-- this script inserts the DAG info for each DAG into redcap_data
-- redcap_record_list already knows this info, but it must be duplicated for
-- the interface to work properly.
-- need to edit:
-- where source_arm.project_id = 64 -- Source project ID
--   and target_arm.project_id = 68 -- Target project ID
-- and value in (5319, 5457) -- DAG IDs to copy
-- DAG IDs as in the Source project.
-- Riinu Pius 14-Aug 2020

-- mofified to use variables
-- Tim Shaw 18-Aug-2020 

SET @source_project = 64;
SET @target_project = 68;
SET @DAG_ids = '5319, 5457';

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
where source_arm.project_id = @source_project
  and target_arm.project_id = @target_project
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value in (@DAG_ids) -- DAG IDs to copy
  ) and field_name = '__GROUPID__'
