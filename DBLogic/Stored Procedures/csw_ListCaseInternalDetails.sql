-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.csw_ListCaseInternalDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseInternalDetails ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseInternalDetails .'
	Drop procedure [dbo].[csw_ListCaseInternalDetails]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseInternalDetails ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_ListCaseInternalDetails 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
AS
-- PROCEDURE:	csw_ListCaseInternalDetails
-- VERSION:	2
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Lists the internal details of the Case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17-Mar-2010 ASH RFC5632 1   New Procedure	
-- 25-May-2016 MS  R54074  2   Added Case Row Access security check and restrict access for external user


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString			nvarchar(4000)
Declare @sDateCreated datetime
Declare @sDateChanged datetime
declare @bHasAccessSecurity bit
declare @sAlertXML nvarchar(max)
declare @bIsExternalUser bit

Set @nErrorCode = 0
Set @bHasAccessSecurity = 0

If @nErrorCode = 0
Begin
        Set @sSQLString = "Select @bIsExternalUser = ISEXTERNALUSER FROM USERIDENTITY where IDENTITYID = @pnUserIdentityId"
        exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit     output,
				  @pnUserIdentityId	        int',
				  @bIsExternalUser		= @bIsExternalUser      output,
				  @pnUserIdentityId             = @pnUserIdentityId
End

if @nErrorCode = 0 and @bIsExternalUser = 0
Begin
        Select @bHasAccessSecurity = SECURITYFLAG & 1
        from dbo.fn_FilterRowAccessCases(@pnUserIdentityId) 
        where CASEID = @pnCaseKey
End

If @nErrorCode = 0
Begin
        If @bIsExternalUser = 1 or ISNULL(@bHasAccessSecurity,0) = 0 
        Begin
                Set @sAlertXML = dbo.fn_GetAlertXML('SF59', 'You do not have the necessary permissions to access this information.  Please contact your system administrator.', null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
        End
End

if @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sDateCreated = EVENTDATE From CASEEVENT where CASEID=@pnCaseKey and EVENTNO=-13"
        	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @sDateCreated	datetime OUTPUT',
					  @pnCaseKey			= @pnCaseKey,
					  @sDateCreated = @sDateCreated OUTPUT
End

if @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sDateChanged = EVENTDATE From CASEEVENT where CASEID=@pnCaseKey and EVENTNO=-14"
        	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
						 @sDateChanged	datetime OUTPUT',
					  @pnCaseKey			= @pnCaseKey,
						@sDateChanged = @sDateChanged OUTPUT
End

If @nErrorCode = 0
Begin

	Set @sSQLString = " Select distinct	CASEID		as 'CaseKey',
		@sDateCreated	as 'DateCreated',
		@sDateChanged 		as 'DateChanged'
	FROM CASEEVENT 
    WHERE CASEID=@pnCaseKey"

  exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					 @sDateCreated	datetime,
					 @sDateChanged	datetime',
					 @pnCaseKey			= @pnCaseKey,
					@sDateCreated = @sDateCreated,
					@sDateChanged = @sDateChanged
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseInternalDetails  to public
GO
