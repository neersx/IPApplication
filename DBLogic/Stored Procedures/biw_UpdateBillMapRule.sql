-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_UpdateBillMapRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_UpdateBillMapRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_UpdateBillMapRule.'
	Drop procedure [dbo].[biw_UpdateBillMapRule]
End
Print '**** Creating Stored Procedure dbo.biw_UpdateBillMapRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_UpdateBillMapRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnMapRuleKey		int,
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
	@pnStatus		int = null,
	@pdtLogDateTimeStamp	datetime
)
as
-- PROCEDURE:	biw_UpdateBillMapRule
-- VERSION:	1
-- DESCRIPTION:	Update a bill map rule.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Jul 2010	AT	RFC7271	1	Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sAlertXML	nvarchar(1000)
Declare @nOutputMappingKey	int

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "UPDATE BILLMAPRULES
	Set FIELDCODE = @pnFieldCode,
	MAPPEDVALUE = @psMappedValue,
	WIPCODE = @psWIPCode,
	WIPTYPEID = @psWIPTypeId,
	WIPCATEGORY = @psWIPCategory,
	NARRATIVECODE = @psNarrativeKey,
	STAFFCLASS = @pnStaffClass,
	ENTITYNO = @pnEntityNo,
	OFFICEID = @pnOfficeId,
	CASETYPE = @psCaseType,
	COUNTRYCODE = @psCountryCode,
	PROPERTYTYPE = @psPropertyType,
	CASECATEGORY = @psCaseCategory,
	SUBTYPE = @psSubType,
	BASIS = @psBasis,
	STATUS = @pnStatus
	Where LOGDATETIMESTAMP = @pdtLogDateTimeStamp
	AND MAPRULEID = @pnMapRuleKey"
		
		exec @nErrorCode = sp_executesql @sSQLString,
		N' @pnFieldCode		int,
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
		  @pdtLogDateTimeStamp	datetime,
		  @pnMapRuleKey		int',
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
		@pdtLogDateTimeStamp = @pdtLogDateTimeStamp,
		@pnMapRuleKey = @pnMapRuleKey
		
	if (@@ROWCOUNT = 0)
	Begin
		-- BillMapRule not found
		Set @sAlertXML = dbo.fn_GetAlertXML('BI3', 'Concurrency error. Bill Map Rule has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

if (@nErrorCode = 0)
Begin
	Select @pnMapRuleKey as 'BillMapRuleKey',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from BILLMAPRULES
	WHERE MAPRULEID = @pnMapRuleKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_UpdateBillMapRule to public
GO