-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_GetExchangeRateVariation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_GetExchangeRateVariation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_GetExchangeRateVariation.'
	Drop procedure [dbo].[acw_GetExchangeRateVariation]
End
Print '**** Creating Stored Procedure dbo.acw_GetExchangeRateVariation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_GetExchangeRateVariation
(
	@pnRowCount				int		= null output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnExchVariationID		int -- Mandatory
)
as
-- PROCEDURE:	acw_GetExchangeRateVariation
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns Exchange Rate Variation Data
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2010  DV		RFC7350		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  E.EXCHVARIATIONID as ExchVariationID,
			E.CURRENCYCODE as CurrencyCode,
			"+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CU',@sLookupCulture,@pbCalledFromCentura) 
				+ " as CurrencyDescription,
			E.EXCHSCHEDULEID as ExchScheduleID,
			"+dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'ES',@sLookupCulture,@pbCalledFromCentura) 
				+ " as ExchScheduleDescription,
			E.CASETYPE as CaseType,
			"+dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0)
				+ " as CaseTypeDescription,
			E.CASECATEGORY as CaseCategory,
			isnull("+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) +","
				    +dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0)
				+ ") as CaseCategoryDescription,
			E.PROPERTYTYPE as PropertyType,
			isnull("+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) +","
				+ dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0)
				+ ") as PropertyTypeDescription,
			E.COUNTRYCODE as CountryCode,
			C.COUNTRY as CountryDescription,
			E.CASESUBTYPE as SubType,
			isnull("+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0) +","
				+ dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0)
				+ ")  as SubTypeDescription,
			E.BUYFACTOR as BuyFactor,
			E.SELLFACTOR as SellFactor,
			E.BUYRATE as BuyRate,
			E.SELLRATE as SellRate,
			E.EFFECTIVEDATE as DateChanged,
			E.NOTES as Notes,
			E.LOGDATETIMESTAMP as LastUpdatedDate
	from 	EXCHRATEVARIATION E left join CURRENCY CU on (CU.CURRENCY=E.CURRENCYCODE)
			left join EXCHRATESCHEDULE ES on (ES.EXCHSCHEDULEID=E.EXCHSCHEDULEID)
			left join COUNTRY C on (C.COUNTRYCODE=E.COUNTRYCODE)
			left join CASETYPE CT on (CT.CASETYPE=E.CASETYPE)
			left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=E.PROPERTYTYPE
				and VC.CASETYPE = E.CASETYPE
				and VC.CASECATEGORY = E.CASECATEGORY
				and VC.COUNTRYCODE =( select min(VC1.COUNTRYCODE)
				from VALIDCATEGORY VC1
				where VC1.CASETYPE = E.CASETYPE
				and VC1.PROPERTYTYPE = E.PROPERTYTYPE
				and VC1.COUNTRYCODE in ('ZZZ',E.COUNTRYCODE)))
			left join CASECATEGORY CC on (CC.CASETYPE=E.CASETYPE
				and CC.CASECATEGORY = E.CASECATEGORY)
				left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=E.PROPERTYTYPE
				and VP.COUNTRYCODE =(select min(VP1.COUNTRYCODE)
				from VALIDPROPERTY VP1
				where VP1.COUNTRYCODE in ('ZZZ',E.COUNTRYCODE)))  
			left join PROPERTYTYPE P	on (P.PROPERTYTYPE=E.PROPERTYTYPE)
			left join VALIDSUBTYPE VS on (VS.PROPERTYTYPE=E.PROPERTYTYPE
				and VS.CASETYPE = E.CASETYPE
				and VS.CASECATEGORY = E.CASECATEGORY
				and VS.SUBTYPE = E.CASESUBTYPE
				and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)
				from VALIDSUBTYPE VS1
				where VS1.CASETYPE = E.CASETYPE
				and VS1.PROPERTYTYPE = E.PROPERTYTYPE
				and VS1.CASECATEGORY = E.CASECATEGORY
				and VS1.COUNTRYCODE in ('ZZZ',E.COUNTRYCODE)))
				left join SUBTYPE S on (S.SUBTYPE=E.CASESUBTYPE)
			where E.EXCHVARIATIONID = @pnExchVariationID"	
End

print @sSQLString
exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnExchVariationID int',
			@pnExchVariationID	= @pnExchVariationID

Set @pnRowCount = @@Rowcount

Return @nErrorCode
go

Grant exec on dbo.acw_GetExchangeRateVariation to Public
go