-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListWorkflowCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListWorkflowCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListWorkflowCriteria.'
	Drop procedure [dbo].[ipw_ListWorkflowCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_ListWorkflowCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListWorkflowCriteria
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,		
	@pbCalledFromCentura		bit		= 0,
	@ptXMLCriteriaList		ntext		-- Mandatory
	
)
as
-- PROCEDURE:	ipw_ListWorkflowCriteria
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Gets Criteria records on the basis of Criteria no.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	----------		-------	----------------------------------------------- 
-- 12 Aug 2011	SF	RFC9317		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sSQLFrom	nvarchar(4000)

Declare @sLookupCulture	nvarchar(10)
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument


Create table #TEMPCRITERIA (	CRITERIANO		int		not null primary key )

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
and datalength(@ptXMLCriteriaList) > 0 
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLCriteriaList
	
	Insert into #TEMPCRITERIA(CRITERIANO)
	Select	*
	from	OPENXML (@idoc, "//ipw_ListWorkflowCriteria/CriterionKey", 2)
	WITH (
	      CRITERIANO		int	'text()'
	     )
	
        -- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End

If  @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"	C.CRITERIANO as CriteriaNo,"+char(10)+
	"	C.CASEOFFICEID as CaseOfficeKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura)+ " as CaseOfficeDescription,"+char(10)+
	"	C.CASETYPE as CaseTypeCode,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+ " as CaseTypeDescription,"+char(10)+
	"	C.PROPERTYTYPE as PropertyTypeCode,"+char(10)+
	"	isnull("+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura) +","+
	dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)+ 
	") as PropertyTypeDescription,"+char(10)+	
	"	C.COUNTRYCODE as CountryCode,"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+
	" as CountryName,"+char(10)+	
	"	C.CASECATEGORY as CaseCategoryCode,"+char(10)+
	"	isnull("+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura)+","+
	dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,@pbCalledFromCentura)+ 
	") as CaseCategoryDescription,"+char(10)+
	"	C.ACTION as ActionKey,"+char(10)+
	"	isnull("+dbo.fn_SqlTranslatedColumn('VALIDACTION','ACTIONNAME',null,'VA',@sLookupCulture,@pbCalledFromCentura)+","+
	dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)+ 
	") as ActionName,"+char(10)+	
		"C.SUBTYPE as SubTypeCode,"+char(10)+
	"	isnull("+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura)+","+
	dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+
	") as SubTypeDescription,"+char(10)+
	"	C.BASIS as ApplicationBasisCode,"+char(10)+
	"	isnull("+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,@pbCalledFromCentura)+","+
	dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura)+ 
	") as ApplicationBasisDescription,"+char(10)+
	"	C.DATEOFACT as DateOfLaw,"+CHAR(10)+
	"	cast(C.LOCALCLIENTFLAG as bit) as IsLocalClient,"+CHAR(10)+
	"	CASE WHEN C.REGISTEREDUSERS in ('Y', 'B') THEN cast(1 as bit) ELSE cast(0 as bit) END as IsUsedByOwners,"+CHAR(10)+
	"	CASE WHEN C.REGISTEREDUSERS in ('N', 'B') THEN cast(1 as bit) ELSE cast(0 as bit) END as IsUsedByOthers,"+CHAR(10)+
	"	C.TABLECODE as ActionAttributeKey,"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+ 
	"	as ActionAttributeDescription,"+CHAR(10)+
	"	CASE WHEN A.ACTIONTYPEFLAG = 1 and TC.TABLETYPE = 17 THEN 'R'"+CHAR(10)+
	"	     WHEN A.ACTIONTYPEFLAG = 2 and TC.TABLETYPE = 8 THEN 'E'"+CHAR(10)+
	"	ELSE NULL END as ActionAttributeType,"+CHAR(10)+
	"	cast(C.RULEINUSE as bit) as IsRuleInUse,"+char(10)+
	"	C.DESCRIPTION as CriteriaName,"+char(10)+
	"	cast(isnull(C.USERDEFINEDRULE,0) as bit) as IsUserDefinedRule,"+char(10)+
	"	I.FROMCRITERIA as ParentCriterionKey"
	
	Set @sSQLFrom = "
	from CRITERIA C"+char(10)+
	"join #TEMPCRITERIA T on (T.CRITERIANO = C.CRITERIANO and C.PURPOSECODE = 'E')"+CHAR(10)+
	"left join INHERITS I on (C.CRITERIANO = I.CRITERIANO)"+CHAR(10)+
	"left join OFFICE O on (O.OFFICEID=C.CASEOFFICEID)"+CHAR(10)+
	"left join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)"+char(10)+
	"left join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"left join PROPERTYTYPE P on (P.PROPERTYTYPE=C.PROPERTYTYPE)"+char(10)+
	"left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"							and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
	"												from VALIDPROPERTY VP1"+char(10)+
	"												where VP1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"												and VP1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE)))"+char(10)+	
	"left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"							and VC.CASETYPE=C.CASETYPE"+char(10)+
	"							and VC.CASECATEGORY=C.CASECATEGORY"+char(10)+
	"							and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)"+char(10)+
	"												from VALIDCATEGORY VC1"+char(10)+
	"												where VC1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"												and VC1.CASETYPE=C.CASETYPE"+char(10)+
	"												and VC1.CASECATEGORY=C.CASECATEGORY"+char(10)+
	"												and VC1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))"+char(10)+
	"left join CASECATEGORY CC on (CC.CASECATEGORY = C.CASECATEGORY and C.CASETYPE = CC.CASETYPE)"+char(10)+
	"left join VALIDACTION VA on (VA.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"				and VA.CASETYPE = C.CASETYPE"+CHAR(10)+
	"				and VA.[ACTION] = C.[ACTION]"+CHAR(10)+
	"				and VA.COUNTRYCODE =( select min(VA1.COUNTRYCODE)"+CHAR(10)+
	"							from VALIDACTION VA1"+CHAR(10)+
	"							where VA1.CASETYPE = C.CASETYPE"+CHAR(10)+
	"							and VA1.[ACTION]=C.[ACTION]"+CHAR(10)+
	"							and VA1.PROPERTYTYPE = C.PROPERTYTYPE"+CHAR(10)+
	"							and VA1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE)))"+CHAR(10)+
	"left join ACTIONS A on (A.[ACTION]=C.[ACTION])"+CHAR(10)+
	"left join SUBTYPE S on (S.SUBTYPE = C.SUBTYPE)"+char(10)+
	"left join VALIDSUBTYPE VS on (VS.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	"							and VS.CASETYPE = C.CASETYPE"+char(10)+
	"							and VS.CASECATEGORY = C.CASECATEGORY"+char(10)+
	"							and VS.SUBTYPE = C.SUBTYPE"+char(10)+
	"							and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)"+char(10)+
	"													from VALIDSUBTYPE VS1"+char(10)+
	"													where VS1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	"													and VS1.CASETYPE = C.CASETYPE"+char(10)+
	"													and VS1.CASECATEGORY = C.CASECATEGORY"+char(10)+
	"													and VS1.SUBTYPE = C.SUBTYPE"+char(10)+
	"													and VS1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE)))"+char(10)+
	"left join APPLICATIONBASIS B on (B.BASIS = C.BASIS)"+char(10)+
	"left join VALIDBASIS VB on (VB.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	"							and VB.BASIS = C.BASIS"+char(10)+
	"							and VB.COUNTRYCODE = (select min(VB1.COUNTRYCODE)"+char(10)+
	"													from VALIDBASIS VB1"+char(10)+
	"													where VB1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	"													and VB1.BASIS = C.BASIS"+char(10)+
	"													and VB1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE)))"+CHAR(10)+
	"left join TABLECODES TC on (TC.TABLECODE = C.TABLECODE)"
	
	print @sSQLString
	print @sSQLFrom
	exec (@sSQLString + @sSQLFrom)
	
	Set @nErrorCode = @@ERROR

End

if @nErrorCode=0
Begin
	Drop table #TEMPCRITERIA
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListWorkflowCriteria to public
GO
