-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_FetchChecklistControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_FetchChecklistControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_FetchChecklistControlCriteria.'
	Drop procedure [dbo].[ipw_FetchChecklistControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_FetchChecklistControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_FetchChecklistControlCriteria
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,		
	@pbCalledFromCentura		bit		= 0,
	@pnCriteriaNo			int			-- Mandatory
)
as
-- PROCEDURE:	ipw_FetchChecklistControlCriteria
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Gets Criteria record on the basis of Criteria no.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2010	KR	RFC9193	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture	nvarchar(10)

declare		@pnIsCriteriaInherited	decimal(1,0)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @pnIsCriteriaInherited = 0

If 	exists(select * from INHERITS where FROMCRITERIA = @pnCriteriaNo) 
	or exists(select * from INHERITS where CRITERIANO = @pnCriteriaNo)
Begin
	Set @pnIsCriteriaInherited = 1
End

If  @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"	C.CRITERIANO as CriteriaNo,"+char(10)+	
	"	C.CHECKLISTTYPE as ChecklistTypeKey,"+char(10)+
	"	CL.CHECKLISTDESC as ChecklistTypeDescription,"+char(10)+
	"	C.CASEOFFICEID as CaseOfficeKey,"+char(10)+
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
		"C.SUBTYPE as SubTypeCode,"+char(10)+
	"	isnull("+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura)+","+
	dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+
	") as SubTypeDescription,"+char(10)+
	"	C.BASIS as ApplicationBasisCode,"+char(10)+
	"	isnull("+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,@pbCalledFromCentura)+","+
	dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura)+ 
	") as ApplicationBasisDescription,"+char(10)+
	"	C.RULEINUSE as RuleInUse,"+char(10)+
	"	case C.LOCALCLIENTFLAG when 1 then 1 
		     else 0 end as LocalClientFlagYes,"+char(10)+
	"	case C.LOCALCLIENTFLAG when 0 then 1 
		     else 0 end as LocalClientFlagNo,"+char(10)+
	"	case C.REGISTEREDUSERS when 'Y' then 1 
		     else case C.REGISTEREDUSERS when 'B' then 1 else 0 end
		      end as RegisteredUsersOwners,"+char(10)+	
	"	case C.REGISTEREDUSERS when 'N' then 1 
		     else case C.REGISTEREDUSERS when 'B' then 1 else 0 end
		     end as RegisteredUsersOthers,"+char(10)+
	"	C.DESCRIPTION as CriteriaName,"+char(10)+
	"	C.USERDEFINEDRULE as UserDefinedRule,"+char(10)+
	"	@pnIsCriteriaInherited as IsCriteriaInherited,"+char(10)+
	"	C.PROFILEID as ProfileKey,"+char(10)+
	"	PR.PROFILENAME as ProfileName"+char(10)+
	"from CRITERIA C"+char(10)+
	"Join CHECKLISTS CL on (CL.CHECKLISTTYPE = C.CHECKLISTTYPE)"+char(10)+
	"left join PROFILES PR on (PR.PROFILEID=C.PROFILEID)"+char(10)+
	"left join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)"+char(10)+
	"left join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"left join PROPERTYTYPE P on (P.PROPERTYTYPE=C.PROPERTYTYPE)"+char(10)+
	"left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"							and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
	"												from VALIDPROPERTY VP1"+char(10)+
	"												where VP1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"												and VP1.COUNTRYCODE = C.COUNTRYCODE))"+char(10)+	
	"left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"							and VC.CASETYPE=C.CASETYPE"+char(10)+
	"							and VC.CASECATEGORY=C.CASECATEGORY"+char(10)+
	"							and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)"+char(10)+
	"												from VALIDCATEGORY VC1"+char(10)+
	"												where VC1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
	"												and VC1.CASETYPE=C.CASETYPE"+char(10)+
	"												and VC1.CASECATEGORY=C.CASECATEGORY"+char(10)+
	"												and VC1.COUNTRYCODE = C.COUNTRYCODE))"+char(10)+
	"left join CASECATEGORY CC on (CC.CASECATEGORY = C.CASECATEGORY)"+char(10)+
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
	"													and VS1.COUNTRYCODE = C.COUNTRYCODE))"+char(10)+
	"left join APPLICATIONBASIS B on (B.BASIS = C.BASIS)"+char(10)+
	"left join VALIDBASIS VB on (VB.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	"							and VB.BASIS = C.BASIS"+char(10)+
	"							and VB.COUNTRYCODE = (select min(VB1.COUNTRYCODE)"+char(10)+
	"													from VALIDBASIS VB1"+char(10)+
	"													where VB1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	"													and VB1.BASIS = C.BASIS"+char(10)+
	"													and VB1.COUNTRYCODE = C.COUNTRYCODE))"+char(10)+	
	
	"where C.CRITERIANO = @pnCriteriaNo"


print @sSQLString
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCriteriaNo		int,
					@pnIsCriteriaInherited	decimal(1,0)',
					@pnCriteriaNo		=	@pnCriteriaNo,
					@pnIsCriteriaInherited = @pnIsCriteriaInherited			

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_FetchChecklistControlCriteria to public
GO
