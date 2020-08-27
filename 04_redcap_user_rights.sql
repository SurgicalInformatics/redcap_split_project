-- this script copies the users over to the new project
-- it updates the role_id as well as the group_id
-- this is the final script and project should be ready to go after this
-- Riinu Pius 26-Aug 2020

SET @source_project = 16;
SET @target_project = 37;
-- just Birmingham:
SET @DAG_ids = 404;


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
      and source_dag.project_id = @source_project
      and target_dag.project_id = @target_project
      and source_rights.group_id = @DAG_ids
;
