-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateFunctionSecurityRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateFunctionSecurityRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateFunctionSecurityRule.'
	Drop procedure [dbo].[ipw_UpdateFunctionSecurityRule]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateFunctionSecurityRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateFunctionSecurityRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnFunctionType		int,	
	@pnOwnerNo		int,
	@pnAccessStaffKey	int,
	@pnAccessGroupKey	int,	
	@pbCanRead		bit,
	@pbCanInsert		bit,
	@pbCanUpdate		bit,
	@pbCanDelete		bit,
	@pbCanPost		bit, 
	@pbCanFinalise		bit,
	@pbCanReverse		bit, 
	@pbCanCredit		bit,
	@pbCanAdjustValue	bit,
	@pbCanConvert		bit,
	@pnOldFunctionType	int,
	@pnOldSequenceNo	int,
	@pnOldAccessStaffKey	int,
	@pnOldAccessGroupKey	int,
	@pnOldOwnerNo		int
)
as
-- PROCEDURE:	ipw_UpdateFunctionSecurityRule
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates the Function Security Rule

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Dec 2009	NG	RFC8631	1	Procedure created
-- 11 Jan 2009	MS	RFC8631	2	Added OwnerNo in "Function Security Rule exists" check

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sAlertXML		nvarchar(400)
declare @nAccessPrivileges	int
declare @sSQLString		nvarchar(max)
Declare @nSequenceNo		int

-- Initialise variables
Set @nErrorCode = 0

-- Check for Function Security Rule existence
If @nErrorCode = 0
and (@pnAccessStaffKey <> @pnOldAccessStaffKey  or  @pnAccessGroupKey <> @pnOldAccessGroupKey or @pnOwnerNo <> @pnOldOwnerNo)
Begin	
	if ((@pnAccessStaffKey is not null and
		exists(select 1 from FUNCTIONSECURITY where FUNCTIONTYPE = @pnFunctionType and ACCESSSTAFFNO = @pnAccessStaffKey and ACCESSGROUP is null and OWNERNO = @pnOwnerNo))
	or (@pnAccessGroupKey is not null and
		exists(select 1 from FUNCTIONSECURITY where FUNCTIONTYPE = @pnFunctionType and ACCESSGROUP = @pnAccessGroupKey and ACCESSSTAFFNO is null and OWNERNO = @pnOwnerNo))
	or (@pnAccessStaffKey is null and @pnAccessGroupKey is null and
		exists(select 1 from FUNCTIONSECURITY where FUNCTIONTYPE = @pnFunctionType and ACCESSGROUP is null and ACCESSSTAFFNO is null and OWNERNO = @pnOwnerNo)))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP104', 'Function Security Rule already exists.', null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Set @nAccessPrivileges = 
			CASE WHEN @pbCanRead = 1 THEN 1 ELSE 0 END +
			CASE WHEN @pbCanInsert = 1 THEN 2 ELSE 0 END +
			CASE WHEN @pbCanUpdate = 1 THEN 4 ELSE 0 END +
			CASE WHEN @pbCanDelete = 1 THEN 8 ELSE 0 END +
			CASE WHEN @pbCanPost = 1 THEN 16 ELSE 0 END +
			CASE WHEN @pbCanFinalise = 1 THEN 32 ELSE 0 END +
			CASE WHEN @pbCanReverse = 1 THEN 64 ELSE 0 END +
			CASE WHEN @pbCanCredit = 1 THEN 128 ELSE 0 END+
			CASE WHEN @pbCanAdjustValue = 1 THEN 256 ELSE 0 END+
			CASE WHEN @pbCanConvert = 1 THEN 512 ELSE 0 END
End

If @nErrorCode = 0
Begin
	If @pnFunctionType <> @pnOldFunctionType
	Begin
		if exists (select 1 from FUNCTIONSECURITY where FUNCTIONTYPE = @pnFunctionType)
			Select @nSequenceNo = max(SEQUENCENO)+1 from FUNCTIONSECURITY where FUNCTIONTYPE = @pnFunctionType
		else
			Set @nSequenceNo = 0
	End
	Else
	Begin
		Set @nSequenceNo = @pnOldSequenceNo
	End


	Set @sSQLString = "UPDATE FUNCTIONSECURITY
			  Set	FUNCTIONTYPE	= @pnFunctionType,
				SEQUENCENO	= @nSequenceNo,
				OWNERNO		= @pnOwnerNo,
				ACCESSSTAFFNO	= @pnAccessStaffKey,
				ACCESSGROUP	= @pnAccessGroupKey,
				ACCESSPRIVILEGES = @nAccessPrivileges
			  where FUNCTIONTYPE = @pnOldFunctionType
			  and	SEQUENCENO = @pnOldSequenceNo
			  and	(ACCESSSTAFFNO is null or ACCESSSTAFFNO = @pnOldAccessStaffKey)
			  and	(ACCESSGROUP is null or ACCESSGROUP = @pnOldAccessGroupKey)
			  and   (OWNERNO is null or OWNERNO = @pnOldOwnerNo)"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnFunctionType		int,
				  @nSequenceNo			int,
				  @pnOwnerNo			int,
				  @pnAccessStaffKey		int,
				  @pnAccessGroupKey		int,
				  @nAccessPrivileges		int,
				  @pnOldFunctionType		int,
				  @pnOldSequenceNo		int,
				  @pnOldAccessStaffKey		int,
				  @pnOldAccessGroupKey		int,
				  @pnOldOwnerNo			int',
				  @pnFunctionType		= @pnFunctionType,
				  @nSequenceNo			= @nSequenceNo,
				  @pnOwnerNo			= @pnOwnerNo,
				  @pnAccessStaffKey		= @pnAccessStaffKey,
				  @pnAccessGroupKey		= @pnAccessGroupKey,
				  @nAccessPrivileges		= @nAccessPrivileges,
				  @pnOldFunctionType		= @pnOldFunctionType,
				  @pnOldSequenceNo		= @pnOldSequenceNo,
				  @pnOldAccessStaffKey		= @pnOldAccessStaffKey,
				  @pnOldAccessGroupKey		= @pnOldAccessGroupKey,
				  @pnOldOwnerNo			= @pnOldOwnerNo
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateFunctionSecurityRule to public
GO
