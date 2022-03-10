if exists (select * from sysobjects where type='TR' and name = 'tU_ValidForWorkBench')
begin
	PRINT 'Refreshing trigger tU_ValidForWorkBench...'
	DROP TRIGGER tU_ValidForWorkBench
end
go

CREATE TRIGGER tU_ValidForWorkBench ON USERIDENTITY FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tU_ValidForWorkBench  
-- VERSION:	2
-- DESCRIPTION:	Update of USERIDENTITY

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	if exists (select * from inserted where ISVALIDWORKBENCH = 1)
    	begin
      		UPDATE 	USERIDENTITY 
		SET 	ISVALIDWORKBENCH = 0
		FROM	inserted i
		JOIN	NAME N on (N.NAMENO = i.NAMENO)
		WHERE	i.ISVALIDWORKBENCH = 1
		and	i.IDENTITYID = USERIDENTITY.IDENTITYID
		AND	i.ISADMINISTRATOR = 0
		and	(i.ACCOUNTID IS NULL
		OR 	N.MAINEMAIL IS NULL)
	end
end
GO
