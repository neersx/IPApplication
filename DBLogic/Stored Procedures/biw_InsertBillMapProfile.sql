-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertBillMapProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertBillMapProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertBillMapProfile.'
	Drop procedure [dbo].[biw_InsertBillMapProfile]
End
Print '**** Creating Stored Procedure dbo.biw_InsertBillMapProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_InsertBillMapProfile
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psBillMapDesc nvarchar(200),
	@psSchemaName		nvarchar(200)	= null
)
as
-- PROCEDURE:	biw_InsertBillMapProfile
-- VERSION:	1
-- DESCRIPTION:	Insert a bill map profile.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Jul 2010	AT	RFC7271	1	Procedure created.
-- 17 Jul 2014	JD	RFC36538 2	Return identity key with SCOPE_IDENTITY instead of @@IDENTITY

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @nOutputProfileId	int

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "INSERT INTO BILLMAPPROFILE(BILLMAPDESC, SCHEMANAME)
			VALUES (@psBillMapDesc, @psSchemaName)
			SELECT @nOutputProfileId = SCOPE_IDENTITY()"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@psBillMapDesc nvarchar(200),
			@psSchemaName		nvarchar(200),
			@nOutputProfileId	int	OUTPUT',
			@psBillMapDesc=@psBillMapDesc,
			@psSchemaName=@psSchemaName,
			@nOutputProfileId = @nOutputProfileId OUTPUT
End

if (@nErrorCode = 0)
Begin
	Select @nOutputProfileId as 'BillMapProfileKey',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from BILLMAPPROFILE 
	WHERE BILLMAPPROFILEID = @nOutputProfileId
End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertBillMapProfile to public
GO