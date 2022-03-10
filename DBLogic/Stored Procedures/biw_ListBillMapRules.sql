-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillMapRules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillMapRules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillMapRules.'
	Drop procedure [dbo].[biw_ListBillMapRules]
End
Print '**** Creating Stored Procedure dbo.biw_ListBillMapRules...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillMapRules
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnBillMapProfileKey	int
)
as
-- PROCEDURE:	biw_ListBillMapRules
-- VERSION:	2
-- DESCRIPTION:	Return bill mapping rules for a specific profile.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Jul 2010	AT	RFC7271	1	Procedure created.
-- 28-Jul-2010	AT	RFC9556	2	Return WIP Description.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @sSQLString				nvarchar(4000)
Declare @sLookupCulture				nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "SELECT 
		BR.MAPRULEID		as 'MapRuleId',
		BR.BILLMAPPROFILEID	as 'BillMapProfileId',
		BR.FIELDCODE		as 'FieldCode',
		" + dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) + " as 'FieldDescription',
		BR.WIPCODE		as 'WIPCode',
		" + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura) + " as 'WIPDescription',
		BR.WIPTYPEID		as 'WIPTypeId',
		BR.WIPCATEGORY		as 'WIPCategory',
		BR.NARRATIVECODE	as 'NarrativeCode',
		BR.STAFFCLASS		as 'StaffClass',
		BR.ENTITYNO		as 'EntityNo',
		BR.OFFICEID		as 'OfficeId',
		BR.CASETYPE		as 'CaseType',
		BR.COUNTRYCODE		as 'CountryCode',
		" + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura) + " as 'CountryDescription',
		BR.PROPERTYTYPE		as 'PropertyType',
		BR.CASECATEGORY		as 'CaseCategory',
		BR.SUBTYPE		as 'SubType',
		BR.BASIS		as 'Basis',
		cast(BR.STATUS as int)	as 'Status',
		BR.MAPPEDVALUE		as 'MappedValue',
		BR.LOGDATETIMESTAMP	as 'LogDateTimeStamp'
		FROM BILLMAPRULES BR
		Left join WIPTEMPLATE WT on (WT.WIPCODE = BR.WIPCODE)
		Left join TABLECODES TC on (TC.TABLECODE = BR.FIELDCODE)
		Left join COUNTRY CT on (CT.COUNTRYCODE = BR.COUNTRYCODE)
		WHERE BILLMAPPROFILEID = @pnBillMapProfileKey
		ORDER BY TC.DESCRIPTION"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnBillMapProfileKey	int',
		@pnBillMapProfileKey=@pnBillMapProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillMapRules to public
GO
