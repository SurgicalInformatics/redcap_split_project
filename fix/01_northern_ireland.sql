-- TODO fix redcap_record_list
-- current state:
-- select * from redcap_record_list where project_id = 54


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
          and target_dag.project_id = 54
          and source_record.dag_id in (1581,1612,2470)
;
