-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetCriteria.'
	Drop procedure [dbo].[ipw_GetCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_GetCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetCriteria
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, -- Language in which output is to be expressed
	@pnCaseCriteriaKey	int	= null,	-- Case Criteria Key
	@pnNameCriteriaKey	int	= null,	-- Name Criteria Key
	@pbCalledFromCentura	bit	= 0
)
as
-- PROCEDURE:	ipw_GetCriteria
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return details of a Criteria or a NameCriteria

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 JAN 2009	JC	RFC6732	1	Procedure created
-- 16 JUN 2009	KR	RFC6546 2	Modified for Name Screen Designer
-- 16 MAR 2010  DV      RFC8935 3       Modified to return the IsUserDefinedColumn for Case Criteria
-- 27 APR 2010  MS	RFC9053 4	Modified to return the IsUserDefinedColumn for Name Criteria
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode	= 0
Set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @pnCaseCriteriaKey IS NOT NULL
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"T.PURPOSECODE as 'PurposeCode',"+char(10)+
	"T.PROGRAMID as 'ProgramId',"+char(10)+
	dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'PG',@sLookupCulture,0)+" as 'ProgramDescription',"+char(10)+
	dbo.fn_SqlTranslatedColumn('CRITERIA','DESCRIPTION',null,'T',@sLookupCulture,0)+" as 'Description',"+char(10)+
	"T.CASETYPE as 'CaseType',"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as CaseTypeDescription,"+char(10)+
	"isnull(CT.CRMONLY,0) as 'IsCRMOnly',"+char(10)+
	"T.PROPERTYTYPE as 'PropertyType',"+char(10)+
	"isnull("+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0)+","
	         +dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0)+") as PropertyTypeDescription,"+char(10)+
	"CAST(isnull(T.PROPERTYUNKNOWN,0) as bit) as 'PropertyTypeUnknown',"+char(10)+
	"T.COUNTRYCODE as 'CountryCode',"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,0)+" as CountryDescription,"+char(10)+
	"CAST(isnull(T.COUNTRYUNKNOWN,0) as bit) as 'CountryUnknown',"+char(10)+
	"T.CASECATEGORY as 'CaseCategory',"+char(10)+
	"isnull("+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0)+","
	         +dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0)+") as CaseCategoryDescription,"+char(10)+
	"CAST(isnull(T.CATEGORYUNKNOWN,0) as bit) as 'CaseCategoryUnknown',"+char(10)+
	"T.SUBTYPE as 'SubType',"+char(10)+
	"isnull("+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0)+","
	         +dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0)+") as SubTypeDescription,"+char(10)+
	"CAST(isnull(T.SUBTYPEUNKNOWN,0) as bit) as 'SubTypeUnknown',"+char(10)+
	"T.BASIS as 'Basis',"+char(10)+
	"isnull("+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,0)+","
	         +dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,0)+") as BasisDescription,"+char(10)+
	"T.CASEOFFICEID as 'CaseOffice',"+char(10)+
	dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,0)+" as 'CaseOfficeDescription',"+char(10)+
	"CAST((CASE WHEN (select COUNT(*) from INHERITS I where I.FROMCRITERIA=@pnCriteriaKey)=0 THEN 0 ELSE 1 END) as bit) as 'HasChildren',"+char(10)+
	"CAST(isnull(T.USERDEFINEDRULE,0) as bit) as 'IsUserDefined'"+char(10)+
	"from CRITERIA T"+char(10)+

	"left join PROGRAM PG on (PG.PROGRAMID=T.PROGRAMID)"+char(10)+

	"left join CASETYPE CT on (CT.CASETYPE=T.CASETYPE)"+char(10)+

	"left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=T.PROPERTYTYPE"+char(10)+
	"				and VP.COUNTRYCODE =(	select min(VP1.COUNTRYCODE)"+char(10)+
	"							from VALIDPROPERTY VP1"+char(10)+
	"							where VP1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join PROPERTYTYPE P	on (P.PROPERTYTYPE=T.PROPERTYTYPE)"+char(10)+
								
	"left join COUNTRY C		on (C.COUNTRYCODE=T.COUNTRYCODE)"+char(10)+
	
	"left join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=T.PROPERTYTYPE"+char(10)+
	"				and VC.CASETYPE    =T.CASETYPE"+char(10)+
	"				and VC.CASECATEGORY=T.CASECATEGORY"+char(10)+
	"				and VC.COUNTRYCODE =(	select min(VC1.COUNTRYCODE)"+char(10)+
	"							from VALIDCATEGORY VC1"+char(10)+
	"							where VC1.CASETYPE=T.CASETYPE"+char(10)+
	"							and VC1.PROPERTYTYPE=T.PROPERTYTYPE"+char(10)+
	"							and VC1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))"+char(10)+
	
	"left join CASECATEGORY CC	on (CC.CASETYPE=T.CASETYPE"+char(10)+
	"				and CC.CASECATEGORY=T.CASECATEGORY)"+char(10)+
	
	"left join VALIDSUBTYPE VS	on (VS.PROPERTYTYPE=T.PROPERTYTYPE"+char(10)+
	"				and VS.CASETYPE    =T.CASETYPE"+char(10)+
	"				and VS.CASECATEGORY=T.CASECATEGORY"+char(10)+
	"				and VS.SUBTYPE     =T.SUBTYPE"+char(10)+
	"				and VS.COUNTRYCODE =(	select min(VS1.COUNTRYCODE)"+char(10)+
	"							from VALIDSUBTYPE VS1"+char(10)+
	"							where VS1.CASETYPE=T.CASETYPE"+char(10)+
	"							and VS1.PROPERTYTYPE=T.PROPERTYTYPE"+char(10)+
	"							and VS1.CASECATEGORY=T.CASECATEGORY"+char(10)+
	"							and VS1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))"+char(10)+
	
	"left join SUBTYPE S		on (S.SUBTYPE=T.SUBTYPE)"+char(10)+
	
	"left join VALIDBASIS VB		on (VB.PROPERTYTYPE=T.PROPERTYTYPE"+char(10)+
	"				and VB.BASIS=T.BASIS"+char(10)+
	"				and VB.COUNTRYCODE =(	select min(VB1.COUNTRYCODE)"+char(10)+
	"							from VALIDBASIS VB1"+char(10)+
	"							where VB1.PROPERTYTYPE=T.PROPERTYTYPE"+char(10)+
	"							and VB1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))"+char(10)+
	
	"left join APPLICATIONBASIS B	on (B.BASIS=T.BASIS)"+char(10)+
	
	"left join OFFICE O		on (O.OFFICEID=T.CASEOFFICEID)"+char(10)+
	
	"where T.CRITERIANO = @pnCriteriaKey"
End
Else
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"T.PURPOSECODE as 'PurposeCode',"+char(10)+
	"T.PROGRAMID as 'ProgramId',"+char(10)+
	dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'PG',@sLookupCulture,0)+" as 'ProgramDescription',"+char(10)+
	"cast((isnull(T.USEDASFLAG, 0) & 1) as bit)	as 'IsIndividual',"+char(10)+
	"~cast((isnull(T.USEDASFLAG, 0) & 1) as bit) as 'IsOrganisation',"+char(10)+
	"cast((isnull(T.USEDASFLAG, 0) & 2) as bit)	as 'IsStaff',"+char(10)+
	"cast((isnull(T.USEDASFLAG, 0) & 4) as bit)	as 'IsClient',"+char(10)+
	"cast(isnull(T.SUPPLIERFLAG, 0) as bit) as 'IsSupplier',"+char(10)+
	"CAST(isnull(T.DATAUNKNOWN,0) as bit) as 'DataUnknown',"+char(10)+
	"T.COUNTRYCODE as 'CountryCode',"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,0)+" as CountryDescription,"+char(10)+
	"T.LOCALCLIENTFLAG as 'LocalClientFlag',"+char(10)+
	"T.CATEGORY as 'Category',"+char(10)+
	"T.NAMETYPE as 'NameType',"+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+" as NameTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CRITERIA','DESCRIPTION',null,'T',@sLookupCulture,0)+" as 'Description',"+char(10)+
	"T.RELATIONSHIP as 'Relationship',"+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',@sLookupCulture,@pbCalledFromCentura)+" as RelationshipDescription,"+char(10)+
	"CAST((CASE WHEN (select COUNT(*) from NAMECRITERIAINHERITS I where I.FROMNAMECRITERIANO=@pnCriteriaKey)=0 THEN 0 ELSE 1 END) as bit) as 'HasChildren',"+char(10)+
	"CAST(isnull(T.USERDEFINEDRULE,0) as bit) as 'IsUserDefined'"+char(10)+
        "from NAMECRITERIA T"+char(10)+
	"left join PROGRAM PG on (PG.PROGRAMID=T.PROGRAMID)"+char(10)+
	"left join COUNTRY C		on (C.COUNTRYCODE=T.COUNTRYCODE)"+char(10)+
	"left join NAMETYPE NT on (NT.NAMETYPE=T.NAMETYPE)"+char(10)+
	"left join NAMERELATION NR on (NR.RELATIONSHIP = T.RELATIONSHIP)"+char(10)+
	"where T.NAMECRITERIANO = @pnCriteriaKey"
End

If @pnCaseCriteriaKey IS NOT NULL
Begin
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCriteriaKey int',	
		@pnCriteriaKey = @pnCaseCriteriaKey
End
Else
Begin
		exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCriteriaKey int',	
		@pnCriteriaKey = @pnNameCriteriaKey
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_GetCriteria to public
GO
