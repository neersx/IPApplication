if exists (select * from sysobjects where type='TR' and name = 'tdi_SiteControlContact')
begin
	PRINT 'Refreshing trigger tdi_SiteControlContact...'
	DROP TRIGGER tdi_SiteControlContact
end
go

CREATE TRIGGER tdi_SiteControlContact
ON SITECONTROL
FOR INSERT, DELETE NOT FOR REPLICATION AS
-- TRIGGER:	tdi_SiteControlContact  
-- VERSION:	2
-- DESCRIPTION:	This trigger recalculates the AccountCaseContact entries for the whole table whenever 
--		the SiteControl is inserted or deleted for the Client Case Types or/and Client Name Types, 
--		and the ColCharacter is not null.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Apr-2004	JEK	1033	 1	Procedure created
-- 17-Nov-2008	MF	SQA17123 2	Performance problem. Use of UPPER in join on SITECONTROL table is causing
--					an index scan. By removing the UPPER, the faster index seek is used by SQLServer.

Declare @nCaseKey 	int
Declare @nErrorCode 	int			

Set @nErrorCode = 0

If exists (Select 1
	   -- Check if the SiteControl for Client Case Types and/or Client Name Types
	   -- has been inserted and the ColCharacter is not null:
	   from inserted 
	   where (inserted.CONTROLID='Client Case Types' and 
		  inserted.COLCHARACTER is not null)						 
	      or (inserted.CONTROLID='Client Name Types' and 
		  inserted.COLCHARACTER is not null))			   
or exists (Select 1
	   -- Check if the SiteControl for Client Case Types and/or Client Name Types
	   -- has been deleted and the ColCharacter is not null:
	   from deleted 
	   where (deleted.CONTROLID='Client Case Types' and 
		  deleted.COLCHARACTER is not null)						 
	      or (deleted.CONTROLID='Client Name Types' and 
		  deleted.COLCHARACTER is not null))
Begin
	exec @nErrorCode = ua_MaintainAccountCaseContact									
End			

if @nErrorCode <> 0
Begin
	Raiserror  ( 'Error %d extracting AccountCaseContact information', 16,1, @nErrorCode)
	Rollback
End
go


