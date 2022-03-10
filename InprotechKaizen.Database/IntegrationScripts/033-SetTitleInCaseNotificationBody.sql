update	CaseNotifications
set		Body = CASE 
				WHEN Body like '%:null%' THEN null ELSE
					SUBSTRING(Body, 11, len(Body)-12) 
				END
where	Type = 0 
and		Body is not null
go