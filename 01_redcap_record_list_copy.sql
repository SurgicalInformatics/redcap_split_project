-- this script copies specified records in redcap_record_list
-- from Source project to Target project
-- need to edit variables:
-- source_project = xx
-- target_project = yy
-- source DAG_ids = '1,2,3...'
-- After running this script, empty records (grey buttons)
-- should show up in the interface
-- Riinu Pius 14-Aug 2020

-- mofified to use variables
-- Tim Shaw 18-Aug-2020 

SET @source_project = 64;
SET @target_project = 68;
SET @DAG_ids = '5319, 5457';

insert into redcap_record_list
select target_dag.project_id,
       source_record.arm,
       source_record.record,
       target_dag.group_id,
       source_record.sort
	from redcap_record_list source_record
    inner join redcap_data_access_groups source_dag on source_dag.group_id = source_record.dag_id
    inner join redcap_data_access_groups target_dag on target_dag.group_name = source_dag.group_name
        where source_dag.project_id = @source_project
          and target_dag.project_id = @target_project
          and source_record.dag_id in (@DAG_ids)
