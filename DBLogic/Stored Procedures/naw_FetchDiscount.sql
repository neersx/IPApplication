-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchDiscount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchDiscount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchDiscount.'
	Drop procedure [dbo].[naw_FetchDiscount]
End
Print '**** Creating Stored Procedure dbo.naw_FetchDiscount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_FetchDiscount
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@pbNewRow		bit		= 0
)
as
-- PROCEDURE:	naw_FetchDiscount
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Disocunt business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Feb 2010	MS	RFC8607	1	Procedure created
-- 15 Jun 2012	KR	R12005	2	added CASETYPE and WIPCODE to DISCOUNT table.
-- 11 Apr 2013	DV	R13270	3       Increase the length of nvarchar to 11 when casting or declaring integer
-- 01 Jun 2015  MS      R35907  4       Added Country to Discount table
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @dDiscountRate	decimal(6,3)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin	
	If @pbNewRow = 1
	Begin
		If @nErrorCode = 0
		Begin
			Select 	null		as RowKey,
				@pnNameKey	as NameKey,
				null		as DiscountId,
				null		as DiscountRate,
				0		as IsSurcharge				
		End

	End
	Else
	Begin
		Set @sSQLString = "Select	
		Cast(D.DISCOUNTID as nvarchar(11)) as 'RowKey',
		D.DISCOUNTID as 'DiscountId',
		D.NAMENO as 'NameKey',
		D.PROPERTYTYPE as 'PropertyType',
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyName',
		A.ACTION as 'ActionType',
		"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ActionName',
		D.DISCOUNTRATE  as 'DiscountRate',
		Case when D.DISCOUNTRATE < 0 Then 1 else 0 end as 'IsSurcharge',
		D.WIPCATEGORY   as 'WIPCategoryCode',
		"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'WIPCategory',
		D.WIPTYPEID   as 'WIPTypeCode',
		"+dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'WIPType',
		D.BASEDONAMOUNT	as 'IsPreMargin',
		TC.TABLECODE	as 'ProductKey',
		TC.USERCODE	as 'ProductCode',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ProductName',		
		D.EMPLOYEENO	as 'StaffKey',
		N.NAMECODE	as 'StaffCode',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'StaffName',
		D.CASEOWNER	as 'CaseOwnerKey',
		N1.NAMECODE	as 'CaseOwnerCode',
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null) as 'CaseOwner',
		CT.CASETYPE as CaseTypeCode,
		" + dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura) + " as 'CaseTypeDescription',
		WIPT.WIPCODE as ActivityKey,
		" + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WIPT',@sLookupCulture,@pbCalledFromCentura) + " as 'Activity',
                D.COUNTRYCODE   as 'CountryCode',
                " + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNT',@sLookupCulture,@pbCalledFromCentura)
				    + " as Country,
                D.LOGDATETIMESTAMP      as LastModifiedDate
		from DISCOUNT D
		LEFT OUTER JOIN PROPERTYTYPE P ON (D.PROPERTYTYPE = P.PROPERTYTYPE)  	
		LEFT OUTER JOIN ACTIONS A ON (D.ACTION = A.ACTION)  	
		LEFT OUTER JOIN WIPCATEGORY WC ON (D.WIPCATEGORY = WC.CATEGORYCODE)  	
		LEFT OUTER JOIN WIPTYPE WT ON (D.WIPTYPEID = WT.WIPTYPEID)  	
		LEFT OUTER JOIN NAME N1 ON (D.CASEOWNER = N1.NAMENO)  	
		LEFT OUTER JOIN NAME N ON (D.EMPLOYEENO = N.NAMENO)  
		LEFT OUTER JOIN TABLECODES TC on (D.PRODUCTCODE = TC.TABLECODE and TC.TABLETYPE = 106)
		Left Outer Join CASETYPE CT on (D.CASETYPE = CT.CASETYPE)
		Left Outer Join WIPTEMPLATE WIPT on (D.WIPCODE = WIPT.WIPCODE)
                Left Outer Join COUNTRY CNT on (D.COUNTRYCODE = CNT.COUNTRYCODE)
		where D.NAMENO = @pnNameKey order by D.SEQUENCE"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int,
				@pnUserIdentityId	int,
				@sLookupCulture		nvarchar(10),
				@pbCalledFromCentura	bit',
				@pnNameKey		= @pnNameKey,
				@pnUserIdentityId 	= @pnUserIdentityId,
				@sLookupCulture		= @sLookupCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura
	End
	

End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchDiscount to public
GO
