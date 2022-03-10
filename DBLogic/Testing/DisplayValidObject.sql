select 	OBJECTID,
	CASE	TYPE
		WHEN 10 THEN 'M'
		WHEN 20 THEN 'T'
		WHEN 30 THEN 'D'
		WHEN 35 THEN 'R'
		WHEN 40 THEN 'L'
	END AS Type,
	CASE WHEN substring(dbo.fn_Clarify(OBJECTDATA),1,3)='999' THEN 'Any' 
	     WHEN substring(dbo.fn_Clarify(OBJECTDATA),1,3)='517' THEN 'Client WorkBench Administration' 
	     ELSE L.MODULENAME END as Module,
	coalesce(M.TITLE,T.TASKNAME,D.TOPICNAME,DP.TOPICNAME) as Description, 
	dbo.fn_Clarify(OBJECTDATA) AS ObjectData
from VALIDOBJECT
left join LICENSEMODULE L ON (L.MODULEID=cast(substring(dbo.fn_Clarify(OBJECTDATA),1,3)as int))
left join MODULE M ON (M.MODULEID=cast(substring(dbo.fn_Clarify(OBJECTDATA),4,10)as int)
			AND TYPE=10)
left join TASK T ON (T.TASKID=cast(substring(dbo.fn_Clarify(OBJECTDATA),4,10)as int)
			AND TYPE=20)
left join DATATOPIC D ON (D.TOPICID=cast(substring(dbo.fn_Clarify(OBJECTDATA),4,10)as int)
			AND TYPE=30)
left join DATATOPIC DP ON (DP.TOPICID=cast(substring(dbo.fn_Clarify(OBJECTDATA),4,10)as int)
			AND TYPE=35)
ORDER BY L.MODULEID, TYPE, Description

