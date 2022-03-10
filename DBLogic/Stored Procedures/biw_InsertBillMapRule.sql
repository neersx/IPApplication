-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertBillMapRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertBillMapRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertBillMapRule.'
	Drop procedure [dbo].[biw_InsertBillMapRule]
End
Print '**** Creating Stored Procedure dbo.biw_InsertBillMapRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_InsertBillMapRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnBillMapProfileKey	int,
	@pnFieldCode		int,
	@psMappedValue		nvarchar(254),
	@psWIPCode		nvarchar(10) = null,
	@psWIPTypeId		nvarchar(10) = null,
	@psWIPCategory		nvarchar(3) = null,
	@psNarrativeKey		nvarchar(10) = null,
	@pnStaffClass		int = null,
	@pnEntityNo		int = null,
	@pnOfficeId		int = null,
	@psCaseType		nvarchar(1) = null,
	@psCountryCode		nvarchar(3) = null,
	@psPropertyType 	nvarchar(1) = null,
	@psCaseCategory 	nvarchar(2) = null,
	@psSubType		nvarchar(2) = null,
	@psBasis		nvarchar(1) = null,
	@pnStatus		int = null
)
as
-- PROCEDURE:	biw_InsertBillMapRule
-- VERSION:	1
-- DESCRIPTION:	Insert a bill map rule.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Jul 2010	AT	RFC7271	1	Procedure created.
-- 15 Jul 2014	JD	RFC36538 2	Return identity key with SCOPE_IDENTITY instead of @@IDENTITY

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @nOutputMappingKey	int

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "INSERT INTO BILLMAPRULES(BILLMAPPROFILEID, FIELDCODE, MAPPEDVALUE, 
			WIPCODE, WIPTYPEID, WIPCATEGORY, NARRATIVECODE, STAFFCLASS, ENTITYNO, 
			OFFICEID, CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, BASIS, STATUS)
		VALUES (@pnBillMapProfileKey,
			@pnFieldCode,
			@psMappedValue,
			@psWIPCode,
			@psWIPTypeId,
			@psWIPCategory,
			@psNarrativeKey,
			@pnStaffClass,
			@pnEntityNo,
			@pnOfficeId,
			@psCaseType,
			@psCountryCode,
			@psPropertyType ,
			@psCaseCategory ,
			@psSubType,
			@psBasis,
			@pnStatus)
			SELECT @nOutputMappingKey = SCOPE_IDENTITY()"
		
		exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnBillMapProfileKey	int,
		  @pnFieldCode		int,
		  @psMappedValue	nvarchar(254),
		  @psWIPCode		nvarchar(10),
		  @psWIPTypeId		nvarchar(10),
		  @psWIPCategory	nvarchar(3),
		  @psNarrativeKey	nvarchar(10),
		  @pnStaffClass		int,
		  @pnEntityNo		int,
		  @pnOfficeId		int,
		  @psCaseType		nvarchar(1),
		  @psCountryCode	nvarchar(3),
		  @psPropertyType 	nvarchar(1),
		  @psCaseCategory 	nvarchar(2),
		  @psSubType		nvarchar(2),
		  @psBasis		nvarchar(1),
		  @pnStatus		int,
		  @nOutputMappingKey	int	OUTPUT',
		@pnBillMapProfileKey = @pnBillMapProfileKey,
		@pnFieldCode = @pnFieldCode,
		@psMappedValue = @psMappedValue,
		@psWIPCode = @psWIPCode,
		@psWIPTypeId = @psWIPTypeId,
		@psWIPCategory = @psWIPCategory,
		@psNarrativeKey = @psNarrativeKey,
		@pnStaffClass = @pnStaffClass,
		@pnEntityNo = @pnEntityNo,
		@pnOfficeId = @pnOfficeId,
		@psCaseType = @psCaseType,
		@psCountryCode = @psCountryCode,
		@psPropertyType = @psPropertyType ,
		@psCaseCategory = @psCaseCategory ,
		@psSubType = @psSubType,
		@psBasis = @psBasis,
		@pnStatus = @pnStatus,
		@nOutputMappingKey = @nOutputMappingKey OUTPUT
End

if (@nErrorCode = 0)
Begin
	Select @nOutputMappingKey as 'BillMapRuleKey',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from BILLMAPRULES
	WHERE MAPRULEID = @nOutputMappingKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertBillMapRule to public
GO