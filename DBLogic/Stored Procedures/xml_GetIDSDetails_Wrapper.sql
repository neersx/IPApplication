-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_GetIDSDetails_Wrapper 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_GetIDSDetails_Wrapper]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_GetIDSDetails_Wrapper.'
	drop procedure dbo.xml_GetIDSDetails_Wrapper
end
print '**** Creating procedure dbo.xml_GetIDSDetails_Wrapper...'
print ''
go


set QUOTED_IDENTIFIER OFF
go
set ANSI_NULLS on
go

create procedure dbo.xml_GetIDSDetails_Wrapper	
		@ptXMLFilterCriteria		nvarchar(max)	-- The activityrequest row in xml flat structure.
as
---PROCEDURE :	xml_GetIDSDetails_Wrapper
-- VERSION :	1
-- DESCRIPTION:	A wrapper procedure of xml_GetIDSDetails  so that it can be 
--		called by DocGen.  
-- MODIFICATION
-- Date			Who	No		Version	Description
-- ==========	===	=== 	=======	=====================================================================
-- 08-11-2016	DL	11300	1		A wrapper procedure of xml_GetIDSDetails so that it can be called from DocGen
		
set nocount on
set concat_null_yields_null on


Declare	@hDocument 		int 				-- handle to the XML parameter which is the Activity Request row
Declare @nErrorCode		int
Declare @nUserIdentityId	int
Declare @nCaseId		int
Declare @sEntryPoint	nvarchar(30)		-- IRN
Declare @sSqlUser		nvarchar(40)
Declare	@sSQLString		nvarchar(max)




-----------------
-- Initialisation
-----------------
Set @nErrorCode		= 0

-------------------------------------------------
-- Check for a null value or emptiness of the 
-- @ptXMLFilterCriteria parameter and raise an
-- error before attempting to open the XML document.
-------------------------------------------------
If isnull(@ptXMLFilterCriteria,'') = ''
Begin	
	Raiserror('Activity request row XML parameter is empty.', 16, 1)
	Set 	@nErrorCode = @@Error
End

-------------------------------------------------
-- Collect the CASEID and User from the Activity Request row 
-- that has been passed as an XML parameter 
-- using OPENXML functionality.
-------------------------------------------------
If @nErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @ptXMLFilterCriteria
	Set 	@nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	Set @sSQLString="
	select 	
		@sSqlUser	= SQLUSER,
		@nCaseId	= CASEID
		from openxml(@hDocument,'ACTIVITYREQUEST',2)
		with (	SQLUSER		nvarchar(40),
				CASEID		int) "
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'	@sSqlUser		nvarchar(40)		OUTPUT,
			@nCaseId		int					OUTPUT,
		  	@hDocument		int',
			@sSqlUser		= @sSqlUser			OUTPUT,
			@nCaseId		= @nCaseId			OUTPUT,
			@hDocument 		= @hDocument
End


-- remove the document.
Exec sp_xml_removedocument @hDocument 

If isnull(@nCaseId, 0) = 0
Begin	
	Raiserror('Activity request row does not contain a Case IRN for use as entry point.', 16, 1)
	Set 	@nErrorCode = @@Error
End

-- Get the IRN to use as entry point
If @nErrorCode = 0
Begin
	Set @sSQLString="
	select 	
		@sEntryPoint	= IRN
		from CASES 
		where CASEID = @nCaseId"
	Exec @nErrorCode=sp_executesql @sSQLString,
		N'	@sEntryPoint	nvarchar(30)		OUTPUT,
			@nCaseId		int     ',
			@sEntryPoint	= @sEntryPoint	OUTPUT,
			@nCaseId		= @nCaseId	
End

-- Get the IDENTITYID of the user that raised the ACTIVITYREQUEST request.  
-- The ACTIVITYREQUEST.IDENTITYID could be a user that started the Policing background which process the policing row and then raise the ACTIVITYREQUEST.
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @nUserIdentityId = isnull(IDENTITYID, 0)
	from USERS
	where USERID=@sSqlUser"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nUserIdentityId		int	OUTPUT,
			  @sSqlUser				nvarchar(40)',
			  @nUserIdentityId=@nUserIdentityId	OUTPUT,
			  @sSqlUser		= @sSqlUser
End


If @nErrorCode = 0
Begin
	EXEC	@nErrorCode = [dbo].[xml_GetIDSDetails]
			@pnUserIdentityId = @nUserIdentityId,
			@psEntryPoint = @sEntryPoint
End


return @nErrorCode
go

grant execute on dbo.xml_GetIDSDetails_Wrapper  to public
go

