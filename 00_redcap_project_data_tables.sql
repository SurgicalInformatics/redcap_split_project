/* all redcap_data of a single record */
select * from redcap_data where project_id = 64 and record = 'RTH08-0001'

/* group_id must be made to match these values from the destination project: */
select * from redcap_data_access_groups where project_id = 64

/* arm_id must be made to match these:
old arm_id = 69, 70, 71
new arm_id = 73, 74, 75
*/
select * from redcap_events_arms where project_id = 64 or project_id = 68


/* event_id from redcap_events_metadata must be made to match the arm_ids */
select * from redcap_events_metadata where arm_id between 69 and 71 or arm_id between 79 and 81

/* data looks ok in the table, but doesn't show up in the interface */
select * from redcap_data where record = 'RTH08-0003'

/* update record list: */
select * from redcap_record_list where project_id  = 64 or project_id = 68
