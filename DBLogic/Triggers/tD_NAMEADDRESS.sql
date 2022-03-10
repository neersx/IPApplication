/******************************************************************************************************************/
/*** Create trigger tD_NAMEADDRESS to add row in the INTEGRATIONQUEUE table if required	 	***/
/******************************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tD_NAMEADDRESS')
begin
	PRINT 'Refreshing trigger tD_NAMEADDRESS...'
	DROP TRIGGER tD_NAMEADDRESS
end
go

CREATE TRIGGER tD_NAMEADDRESS ON NAMEADDRESS FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER :	tD_NAMEADDRESS
-- VERSION :	1
-- DESCRIPTION:	This trigger applies a referential integrity check for Addresses referenced in the CASENAME table.
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 	
-- 06 Dec 2015	MF	42808	1	Moved this RI check into own trigger from tD_NAMEADDRESS_Integration
	
Declare @nErrorCode		int
Set @nErrorCode = 0

-- Block the deletion of a NAMEADDRESS if that NameNo and AddressCode
-- combination is still being referenced by a CASENAME row.
If exists (	Select 1
		from deleted d
		join CASENAME CN on (CN.NAMENO = d.NAMENO
				 and CN.ADDRESSCODE=d.ADDRESSCODE))
Begin						
	Raiserror ('The Address being deleted from this Name may not be removed as it is still being referenced against a Case for this Name.',16,1)
	Set @nErrorCode = @@Error	
End	
	

go
