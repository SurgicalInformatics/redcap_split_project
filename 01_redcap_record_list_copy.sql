-- this script copies specified records in redcap_record_list
-- from Source project to Target project
-- need to edit variables:
-- source_project = xx
-- target_project = yy
-- source DAG_ids = '1,2,3...'
-- (if using SET can only do one at a time)
-- After running this script, empty records (grey buttons)
-- should show up in the interface

SET @source_project = 16;
SET @target_project = 39;
-- just Birmingham:
SET @DAG_id = 404;


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
          and source_record.dag_id = @DAG_id
;
