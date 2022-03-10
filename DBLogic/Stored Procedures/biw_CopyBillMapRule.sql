-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_CopyBillMapRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_CopyBillMapRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_CopyBillMapRule.'
	Drop procedure [dbo].[biw_CopyBillMapRule]
End
Print '**** Creating Stored Procedure dbo.biw_CopyBillMapRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_CopyBillMapRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCopyFromBillMapProfileKey	int,
	@pnCopyToBillMapProfileKey	int
)
as
-- PROCEDURE:	biw_CopyBillMapRule
-- VERSION:	1
-- DESCRIPTION:	Copy a set of bill map rules from one profile to another.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Aug 2010	AT	RFC9556	1	Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

create table #OUTPUTTABLE(
	[MAPRULEID] [int] NOT NULL,
	[BILLMAPPROFILEID] [int] NOT NULL,
	[FIELDCODE] [int] NOT NULL,
	[MAPPEDVALUE] [nvarchar](254) COLLATE database_default NULL,
	[WIPCODE] [nvarchar](10) COLLATE database_default NULL,
	[WIPTYPEID] [nvarchar](10) COLLATE database_default NULL,
	[WIPCATEGORY] [nvarchar](3) COLLATE database_default NULL,
	[NARRATIVECODE] [nvarchar](10) COLLATE database_default NULL,
	[STAFFCLASS] [int] NULL,
	[ENTITYNO] [int] NULL,
	[OFFICEID] [int] NULL,
	[CASETYPE] [NVARCHAR](1) COLLATE database_default NULL,
	[COUNTRYCODE] [nvarchar](3) COLLATE database_default NULL,
	[PROPERTYTYPE] [nvarchar](1) COLLATE database_default NULL,
	[CASECATEGORY] [nvarchar](2) COLLATE database_default NULL,
	[SUBTYPE] [nvarchar](2) COLLATE database_default NULL,
	[BASIS] [nvarchar](2) COLLATE database_default NULL,
	[STATUS] [smallint] NULL,
	[LOGDATETIMESTAMP] [datetime] NULL)

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "INSERT INTO BILLMAPRULES(BILLMAPPROFILEID, FIELDCODE, MAPPEDVALUE, 
			WIPCODE, WIPTYPEID, WIPCATEGORY, NARRATIVECODE, STAFFCLASS, ENTITYNO, 
			OFFICEID, CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, BASIS, STATUS)
			
			OUTPUT INSERTED.MAPRULEID, INSERTED.BILLMAPPROFILEID, INSERTED.FIELDCODE, INSERTED.MAPPEDVALUE,
			INSERTED.WIPCODE, INSERTED.WIPTYPEID, INSERTED.WIPCATEGORY, INSERTED.NARRATIVECODE, INSERTED.STAFFCLASS, INSERTED.ENTITYNO, 
			INSERTED.OFFICEID, INSERTED.CASETYPE, INSERTED.COUNTRYCODE, INSERTED.PROPERTYTYPE, INSERTED.CASECATEGORY, INSERTED.SUBTYPE, INSERTED.BASIS, INSERTED.STATUS,
			INSERTED.LOGDATETIMESTAMP 
			-- need an INTO clause because there are triggers on this table.
			INTO #OUTPUTTABLE

			select @pnCopyToBillMapProfileKey, FIELDCODE, MAPPEDVALUE, 
			WIPCODE, WIPTYPEID, WIPCATEGORY, NARRATIVECODE, STAFFCLASS, ENTITYNO, 
			OFFICEID, CASETYPE, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, BASIS, STATUS
			from BILLMAPRULES
			WHERE BILLMAPPROFILEID = @pnCopyFromBillMapProfileKey"
		
		exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnCopyFromBillMapProfileKey	int,
		  @pnCopyToBillMapProfileKey	int',
		@pnCopyFromBillMapProfileKey = @pnCopyFromBillMapProfileKey,
		@pnCopyToBillMapProfileKey = @pnCopyToBillMapProfileKey
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "Update #OUTPUTTABLE set LOGDATETIMESTAMP = BMR.LOGDATETIMESTAMP 
	FROM BILLMAPRULES BMR
	WHERE BMR.MAPRULEID = #OUTPUTTABLE.MAPRULEID
	AND BMR.BILLMAPPROFILEID = #OUTPUTTABLE.BILLMAPPROFILEID"
	
	exec @nErrorCode = sp_executesql @sSQLString
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "Select 		
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
	from #OUTPUTTABLE BR
	Left join WIPTEMPLATE WT on (WT.WIPCODE = BR.WIPCODE)
	Left join TABLECODES TC on (TC.TABLECODE = BR.FIELDCODE)
	Left join COUNTRY CT on (CT.COUNTRYCODE = BR.COUNTRYCODE)
	ORDER BY TC.DESCRIPTION"
	
	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.biw_CopyBillMapRule to public
GO