-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetCaseDataValidation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetCaseDataValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetCaseDataValidation.'
	Drop procedure [dbo].[ipw_GetCaseDataValidation]
End
Print '**** Creating Stored Procedure dbo.ipw_GetCaseDataValidation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_GetCaseDataValidation
(
	@pnRowCount				int		= null output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDataValidationID		int -- Mandatory
)
as
-- PROCEDURE:	ipw_GetCaseDataValidation
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns Data Validation Row on the basis of @pnDataValidationID
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	-------	-------	--------------------------------------- 
-- 29 Sep 2010  DV	RFC9387	1	Procedure created
-- 17 May 2011  DV	R10157	2       Get the value of NOT columns in the select caluse
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	        nvarchar(max)
Declare @sSQLStringSelect	nvarchar(max)
Declare @sSQLStringFrom 	nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Set @sSQLStringSelect = "
	Select D.VALIDATIONID as ValidationID,			
			D.CASETYPE as CaseType,
			"+dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0)
				+ " as CaseTypeDescription,
			D.COUNTRYCODE as CountryCode,
			C.COUNTRY as CountryDescription,
			D.PROPERTYTYPE as PropertyType,
			isnull("+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) +","
				+ dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0)
				+ ") as PropertyTypeDescription,
			D.SUBTYPE as SubType,
			isnull("+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0) +","
				+ dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0)
				+ ") as SubTypeDescription,
			D.CASECATEGORY as CaseCategory,
			isnull("+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) +","
				    +dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0)
				+ ") as CaseCategoryDescription,
			D.BASIS as Basis,
			isnull("+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','BASISDESCRIPTION',null,'VB',@sLookupCulture,0) +","
				+ dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,0)
				+ ") as BasisDescription,
			D.OFFICEID as OfficeID,
			"+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OC',@sLookupCulture,0)
				+ " as OfficeDescription,
			D.COLUMNNAME as TableColumn,
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,0)
				+ " as TableColumnDescription,
			D.STATUSFLAG as StatusFlag,
			D.LOCALCLIENTFLAG as LocalClientFlag,
			D.EVENTNO as EventCode,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,0)
				+ " as EventDescription,
			D.EVENTDATEFLAG as EventDateFlag,
			D.INUSEFLAG as InUseFlag,
			D.DEFERREDFLAG as DeferredFlag,
			D.FAMILYNO as NameGroupKey,
			"+dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'NF',@sLookupCulture,0)
				+ " as NameGroupDescription,
			D.NAMENO as NameKey,
			N.NAMECODE as NameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) as Name,
			D.NAMETYPE as NameTypeKey,
			NT.DESCRIPTION as NameTypeDescription,
			D.INSTRUCTIONTYPE as InstructionTypeKey,
			"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'IT',@sLookupCulture,0)
				+ " as InstructionTypeDescription,
			D.FLAGNUMBER as InstructionKey,
			"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONLABEL','FLAGLITERAL',null,'IL',@sLookupCulture,0)
				+ " as InstructionDescription,
			"+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','DISPLAYMESSAGE',null,'D',@sLookupCulture,0)
				+ " as DisplayMessage,
			D.RULEDESCRIPTION as RuleDescription,
			D.WARNINGFLAG as WarningFlag,
			D.ROLEID as RoleID,
			R.ROLENAME as RoleName,
			D.ITEM_ID as ValidationItemID,
			I.ITEM_NAME as ValidationItemName,
			"+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','RULEDESCRIPTION',null,'D',@sLookupCulture,0)
				+ " as RuleDescription,
			"+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','NOTES',null,'D',@sLookupCulture,0)
				+ " as Notes,	
		        D.NOTCASETYPE as NotCaseType,	
		        D.NOTPROPERTYTYPE as NotPropertyType,
		        D.NOTCASECATEGORY as NotCaseCategory,
		        D.NOTSUBTYPE as NotSubType,
		        D.NOTCOUNTRYCODE as NotCountryCode,
		        D.NOTBASIS as NotBasis,	
			D.LOGDATETIMESTAMP as LastUpdatedDate "
        Set @sSQLStringFrom = "
	from DATAVALIDATION D left join COUNTRY C on (C.COUNTRYCODE=D.COUNTRYCODE)
			left join CASETYPE CT on (CT.CASETYPE=D.CASETYPE)
			left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=D.PROPERTYTYPE
				and VC.CASETYPE = D.CASETYPE
				and VC.CASECATEGORY = D.CASECATEGORY
				and VC.COUNTRYCODE =( select min(VC1.COUNTRYCODE)
				from VALIDCATEGORY VC1
				where VC1.CASETYPE = D.CASETYPE
				and VC1.PROPERTYTYPE = D.PROPERTYTYPE
				and VC1.COUNTRYCODE in ('ZZZ',D.COUNTRYCODE)))
			left join CASECATEGORY CC on (CC.CASETYPE=D.CASETYPE
				and CC.CASECATEGORY = D.CASECATEGORY)
				left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=D.PROPERTYTYPE
				and VP.COUNTRYCODE =(select min(VP1.COUNTRYCODE)
				from VALIDPROPERTY VP1
				where VP1.COUNTRYCODE in ('ZZZ',D.COUNTRYCODE))) 
			left join PROPERTYTYPE P on (P.PROPERTYTYPE=D.PROPERTYTYPE)
			left join VALIDSUBTYPE VS on (VS.PROPERTYTYPE=D.PROPERTYTYPE
				and VS.CASETYPE = D.CASETYPE
				and VS.CASECATEGORY = D.CASECATEGORY
				and VS.SUBTYPE = D.SUBTYPE
				and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)
				from VALIDSUBTYPE VS1
				where VS1.CASETYPE = D.CASETYPE
				and VS1.PROPERTYTYPE = D.PROPERTYTYPE
				and VS1.CASECATEGORY = D.CASECATEGORY
				and VS1.COUNTRYCODE in ('ZZZ',D.COUNTRYCODE)))
				left join SUBTYPE S on (S.SUBTYPE=D.SUBTYPE)
			left join VALIDBASIS VB	on (VB.PROPERTYTYPE=D.PROPERTYTYPE
				and VB.BASIS=D.BASIS
				and VB.COUNTRYCODE =(select min(VB1.COUNTRYCODE)
				from VALIDBASIS VB1
				where VB1.PROPERTYTYPE=D.PROPERTYTYPE
				and VB1.COUNTRYCODE in (D.COUNTRYCODE,'ZZZ')))
				left join APPLICATIONBASIS B on (B.BASIS=D.BASIS)
		   left join OFFICE OC on (OC.OFFICEID=D.OFFICEID)
			left join TABLECODES TC on (TC.TABLECODE=D.COLUMNNAME)
			left join NAMEFAMILY NF on (NF.FAMILYNO=D.FAMILYNO)
			left join EVENTS EV on (EV.EVENTNO=D.EVENTNO)
			left join NAME N on (N.NAMENO=D.NAMENO)
			left join NAMETYPE NT on (NT.NAMETYPE=D.NAMETYPE)
			left join INSTRUCTIONTYPE IT on (IT.INSTRUCTIONTYPE=D.INSTRUCTIONTYPE)
			left join INSTRUCTIONLABEL IL on (IL.FLAGNUMBER=D.FLAGNUMBER)
			left join ITEM I on (I.ITEM_ID = D.ITEM_ID)
			left join ROLE R on (R.ROLEID = D.ROLEID)
			where D.VALIDATIONID = @pnDataValidationID"	
End
Set @sSQLString = @sSQLStringSelect + @sSQLStringFrom
print @sSQLString
exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnDataValidationID int',
			@pnDataValidationID	= @pnDataValidationID

Set @pnRowCount = @@Rowcount

Return @nErrorCode
go

Grant exec on dbo.ipw_GetCaseDataValidation to Public
go