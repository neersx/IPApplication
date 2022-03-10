if exists (select * from sysobjects where type='TR' and name = 'tu_SiteControlContact')
begin
	PRINT 'Refreshing trigger tu_SiteControlContact...'
	DROP TRIGGER tu_SiteControlContact
end
go

CREATE TRIGGER tu_SiteControlContact ON SITECONTROL
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tu_SiteControlContact  
-- VERSION:	4
-- DESCRIPTION:	This trigger recalculates the AccountCaseContact entries for the whole table whenever 
--		the SiteControl is updated for the Client Case Types or/and Client Name Types, 
--		and the ColCharacter has been modified.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Apr-2004	JEK	1033	 1	Procedure created
-- 17-Nov-2008	MF	SQA17123 2	Performance problem. Use of UPPER in join on SITECONTROL table is causing
--					an index scan. By removing the UPPER, the faster index seek is used by SQLServer.
-- 15 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 Mar 2009	MF	17490	4	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	Declare @nCaseKey 	int
	Declare @nErrorCode 	int			

	Set @nErrorCode = 0

	If exists (Select 1
		   -- Check if the SiteControl for Client Case Types and/or Client Name Types
		   -- has been updated and the ColCharacter has been modified:
		   from inserted i
		   join deleted d on (i.CONTROLID = d.CONTROLID)
		   where (i.CONTROLID='Client Case Types' 				 
		      or  i.CONTROLID='Client Name Types')	   			
		    and   i.COLCHARACTER <> d.COLCHARACTER)
	Begin
		exec @nErrorCode = ua_MaintainAccountCaseContact									
	End			

	if @nErrorCode <> 0
	Begin
		Raiserror  ( 'Error %d extracting AccountCaseContact information', 16,1, @nErrorCode)
		Rollback
	End
End	
go


