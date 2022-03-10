UPDATE CONFIGURATIONITEM
SET TITLE = 'Rules - Case Windows Screen Designer'
WHERE TITLE = 'Rules - Case Windows' and TASKID = 130

UPDATE CONFIGURATIONITEM
SET TITLE = 'Rules - Name Windows Screen Designer'
WHERE TITLE = 'Rules - Name Windows' and TASKID = 130

UPDATE CONFIGURATIONITEM
SET TITLE = 'Protected Rules - Case Windows Screen Designer'
WHERE TITLE = 'Protected Rules - Case Windows' and TASKID = 131

UPDATE CONFIGURATIONITEM
SET TITLE = 'Protected Rules - Name Windows Screen Designer'
WHERE TITLE = 'Protected Rules - Name Windows' and TASKID = 131

UPDATE CONFIGURATIONITEM
SET TITLE = 'Rules - Case Screen Designer (Apps)'
WHERE TITLE = 'Screen Designer - Cases' and TASKID in (130, 131)

UPDATE CONFIGURATIONITEMGROUP
SET TITLE = 'Rules - Case Screen Designer (Apps)'
WHERE TITLE = 'Screen Designer - Cases'

go