-----------------------------------------------------------------------------------------------------------------------------
-- Add redirections for Configuration Items for Portal
-----------------------------------------------------------------------------------------------------------------------------

--Schedule Data Download
update CONFIGURATIONITEM set URL='/apps/#/integration/ptoaccess/uspto-private-pair-certificates' where URL='/i/integration/ptoaccess/#/uspto-private-pair-certificates'
update CONFIGURATIONITEM set URL='/apps/#/integration/ptoaccess/schedules' where URL='/i/integration/ptoaccess/#/schedules'

update CONFIGURATIONITEMGROUP set URL='/apps/#/integration/ptoaccess/schedules' where URL='/i/integration/ptoaccess/#/schedules'
GO
