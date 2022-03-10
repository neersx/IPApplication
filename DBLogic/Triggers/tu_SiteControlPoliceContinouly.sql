if exists (select * from sysobjects where type='TR' and name = 'tu_SiteControlPoliceContinouly')
begin
	PRINT 'Refreshing trigger tu_SiteControlPoliceContinouly...'
	DROP TRIGGER tu_SiteControlPoliceContinouly
end
go

CREATE TRIGGER tu_SiteControlPoliceContinouly ON SITECONTROL
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tu_SiteControlPoliceContinouly  
-- VERSION:	1
-- DESCRIPTION:	Whtn SiteControl 'Police Continuously' is turned off this trigger removes rows in 
-- PROCESSREQUEST that indicating policing continouly was running.  
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06-May-2009	DL	17622	 1	Trigger created

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	Declare @nErrorCode 	int			

	Set @nErrorCode = 0

	If exists (Select 1
		   -- Check if the SiteControl for 'Police Continuously'
		   -- has been updated and the COLBOOLEAN has been modified to 0
		   from inserted i
		   where  i.CONTROLID='Police Continuously' 				 
		    and   i.COLBOOLEAN <> 1)
	Begin
		-- delete tracking rows that indicating policing continous is running
		Delete PROCESSREQUEST 
		where REQUESTTYPE = N'POLICING BACKGROUND'
		set @nErrorCode = @@ERROR
	End			

	if @nErrorCode <> 0
	Begin
		Raiserror  ( 'Cannot delete PROCESSREQUEST with REQUESTTYPE [POLICING BACKGROUND]', 16,1, @nErrorCode)
		Rollback
	End
End	
go
