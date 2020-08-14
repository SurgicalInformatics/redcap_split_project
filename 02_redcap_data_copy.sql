-- this script copies specified records in redcap_data
-- from Source project to Target project
-- need to edit:
-- where source_arm.project_id = 64 -- Source project ID
--   and target_arm.project_id = 68 -- Target project ID
-- and value in (5319, 5457) -- DAG IDs to copy
-- DAG IDs as in the Source project.
-- The script will copy all records into the Target project
-- the scripts will be in appropriate DAGs, as that was already determined in redcap_record_list
-- but the interface will not present the DAG info, as that needs to be duplicately stored in redcap_data
-- as well, as is done in the next script.
-- The next script will move them into DAGs
-- Riinu Pius 14-Aug 2020
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
where source_arm.project_id = 64 -- Source project
  and target_arm.project_id = 68 -- Target project
  and record.record in (
    select record from redcap_data
     where field_name = '__GROUPID__'
       and project_id = source_arm.project_id
       and value in (5319, 5457) -- DAG IDs to copy
  ) and field_name != '__GROUPID__'
