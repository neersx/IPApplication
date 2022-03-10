	/******************************************************************************************************************/
	/*** Insert the appropriate IdentityRoles rows for user (-20), internal (-21)					***/
	/*** or external (-22) based on the IsExternal field.								***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'ti_UserIdentityRole')
	   begin
	    PRINT 'Refreshing trigger ti_UserIdentityRole...'
	    DROP TRIGGER ti_UserIdentityRole
	   end
	  go

	-- This trigger inserts the appropriate IdentityRoles rows for user (-20), 
	-- internal (-21) or external (-22) based on the IsExternal field.

	CREATE TRIGGER ti_UserIdentityRole
		ON USERIDENTITY
		FOR INSERT NOT FOR REPLICATION AS

		Declare @nErrorCode 	int	
		
		Set @nErrorCode = 0	

		If @nErrorCode = 0
		Begin
			-- Attach internal users to user and internal roles
			Insert into IDENTITYROLES (IDENTITYID, ROLEID)
			select U.IDENTITYID, R.ROLEID
			from inserted U
			join ROLE R on (ROLEID IN (-20,-21))
			where U.ISEXTERNALUSER=0
		End

		If @nErrorCode = 0
		Begin
			-- Attach external users to user and external roles
			Insert into IDENTITYROLES (IDENTITYID, ROLEID)
			select U.IDENTITYID, R.ROLEID
			from inserted U
			join ROLE R on (ROLEID IN (-20,-22))
			where U.ISEXTERNALUSER=1
		End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

