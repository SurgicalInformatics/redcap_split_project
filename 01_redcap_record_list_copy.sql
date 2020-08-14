-- this script copies specified records in redcap_record_list
-- from Source project to Target project
-- need to edit:
-- where source_arm.project_id = 64 -- Source project ID
--   and target_arm.project_id = 68 -- Target project ID
-- and value in (5319, 5457) -- DAG IDs to copy
-- DAG IDs as in the Source project.
-- After running this script, empty records (grey buttons)
-- should show up in the interface
-- Riinu Pius 14-Aug 2020
insert into redcap_record_list
select target_dag.project_id,
       source_record.arm,
       source_record.record,
       target_dag.group_id,
       source_record.sort
	from redcap_record_list source_record
    inner join redcap_data_access_groups source_dag on source_dag.group_id = source_record.dag_id
    inner join redcap_data_access_groups target_dag on target_dag.group_name = source_dag.group_name
        where source_dag.project_id = 64
          and target_dag.project_id = 68
          and source_record.dag_id in (5319, 5457)
