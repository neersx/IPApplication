-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetFunctionSecurityRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetFunctionSecurityRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetFunctionSecurityRule.'
	Drop procedure [dbo].[ipw_GetFunctionSecurityRule]
End
Print '**** Creating Stored Procedure dbo.ipw_GetFunctionSecurityRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetFunctionSecurityRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, -- Language in which output is to be expressed
	@pnFunctionType int, -- The function type
	@pnOwnerNameNo	int	= null,	-- The NAMENO of the owner
	@pbCalledFromCentura	bit	= 0
)
as
-- PROCEDURE:	ipw_GetFunctionSecurityRule
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the function security rule that best fits based on the details provided

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Nov 2009	KR		RFC8169 1		Procedure created
-- 30 Jun 2010	SF		RFC5040 2		Fix Typo
-- 07 Sep 2018	AV	74738	3	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @nAccessStaff int
Declare @nAccessGroup int

-- Initialise variables
Set @nErrorCode	= 0
Set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	SELECT @nAccessStaff  = NAMENO FROM USERIDENTITY WHERE IDENTITYID = @pnUserIdentityId

	SELECT @nAccessGroup = FAMILYNO FROM NAME N
						JOIN USERIDENTITY UI on (UI.NAMENO = N.NAMENO)
						WHERE UI.IDENTITYID = @pnUserIdentityId
End


If @nErrorCode = 0
Begin
		Set @sSQLString = "SELECT" +char(10)+
		"CAST(SEQUENCENO as nvarchar(10))+'^'+ CAST(FUNCTIONTYPE as varchar(10)) as 'RowKey'," +char(10)+
		"SEQUENCENO as 'SeqNo'," +char(10)+
		"FUNCTIONTYPE as 'FunctionType'," +char(10)+
		"ACCESSGROUP as 'AccessGroup'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 1) as bit) as 'CanRead'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 2) as bit) as 'CanInsert'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 4) as bit) as 'CanUpdate'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 8) as bit) as 'CanDelete'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 16) as bit) as 'CanPost'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 32) as bit) as 'CanFinalise'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 64) as bit) as 'CanReverse'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 128) as bit) as 'CanCredit'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 256) as bit) as 'CanAdjustValue'," +char(10)+
		"cast((isnull(ACCESSPRIVILEGES, 0) & 512) as bit) as 'CanConvert'," +char(10)+
		"ACCESSSTAFFNO as 'AccessStaff'," +char(10)+
		"OWNERNO as 'OwnerNo'," +char(10)+
		"CASE WHEN (OWNERNO IS NULL)	THEN '0' ELSE '1' END +    			
		CASE WHEN (ACCESSSTAFFNO IS NULL)	THEN '0' ELSE '1' END +	
		CASE WHEN (ACCESSGROUP IS NULL)	THEN '0' ELSE '1' END as 'BestFit'" +char(10)+
		"FROM FUNCTIONSECURITY 
		WHERE FUNCTIONTYPE = @pnFunctionType 
		AND (OWNERNO = @pnOwnerNameNo OR OWNERNO IS NULL) 
		AND (ACCESSSTAFFNO = @nAccessStaff OR ACCESSSTAFFNO IS NULL) 
		AND (ACCESSGROUP = @nAccessGroup OR ACCESSGROUP IS NULL) " +char(10)+
		"ORDER BY BestFit desc"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnFunctionType int,
			  @pnOwnerNameNo int,
			  @nAccessStaff int,
			  @nAccessGroup int',	
			@pnFunctionType = @pnFunctionType,
			@pnOwnerNameNo = @pnOwnerNameNo,
			@nAccessStaff = @nAccessStaff,
			@nAccessGroup = @nAccessGroup
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_GetFunctionSecurityRule to public
GO
