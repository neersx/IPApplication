-----------------------------------------------------------------------------------------------------------------------------
-- Modification of ipw_WorkflowSearch
-----------------------------------------------------------------------------------------------------------------------------
if exists (select *
from sysobjects
where id = object_id(N'[dbo].[ipw_CaseScreenDesignerSearch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
    print '**** Drop procedure dbo.ipw_CaseScreenDesignerSearch.'
    drop procedure dbo.ipw_CaseScreenDesignerSearch
    print '**** Creating procedure dbo.ipw_CaseScreenDesignerSearch...'
    print ''
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].ipw_CaseScreenDesignerSearch
    (
    @pnUserIdentityId             int,
    -- Mandatory
    @psCulture                    nvarchar(10)  = null,
    @psPurposeCode         nchar(1),
    @pnCaseOfficeID        int = null,
    @psProgramID           nvarchar(8) = null,
    @psCaseType                   nchar(1) = null,
    @psCountryCode         nvarchar(3) = null,
    @psPropertyType        nchar(1) = null,
    @psCaseCategory        nvarchar(2) = null,
    @psSubType                    nvarchar(2) = null,
    @psBasis               nvarchar(2) = null,
    @pnProfileKey          int = null,
    @pnRuleInUse         bit = null,
    @pbExactMatch        bit = null,
    @pbUserDefinedRule   bit = null,
    @psCriteriaNumbers   nvarchar(max) = null
)
-- PROCEDURE :       ipw_CaseScreenDesignerSearch
-- VERSION :  1
-- DESCRIPTION:      Lists Criteria that match the selection parameters.

-- Modifications
--
-- Date                    Who           Number        Version       Description
-- ------------      ------ -------              -------       ------------------------------------
-- 29/10/2019 SF            DR-53417      1             Procedure created.
-- 27/12/2019 SB            DR-52836      1             Added IsParent Logic.


AS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode         int
declare @sSql        nvarchar(max)
declare @sLookupCulture           nvarchar(10)
declare @sForceOrder nvarchar(30)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
set @sForceOrder = ' '

Set @sSql = 'Select CR.CRITERIANO as Id,
                     ' + dbo.fn_SqlTranslatedColumn('CRITERIA','DESCRIPTION',null,'CR',@sLookupCulture,0) + ' as CriteriaName,
                     O.OFFICEID as OfficeCode,
                     ' + dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,0) + ' as OfficeDescription,
                     CT.CASETYPE AS CaseTypeCode,
                     ' + dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'PR',@sLookupCulture,0) + ' as ProgramName,
                     PR.PROGRAMID AS ProgramId,
                     ' + dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0) + ' as CaseTypeDescription,
                     CN.COUNTRYCODE as JurisdictionCode,
                     ' + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CN',@sLookupCulture,0) + ' as JurisdictionDescription,
                     VP.PROPERTYTYPE as PropertyTypeCode,
                     ' + dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) + ' as PropertyTypeDescription,
                     coalesce(VC.CASECATEGORY, CC.CASECATEGORY) as CaseCategoryCode,
                     coalesce(' + dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) + ','
                              + dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0) + ') as CaseCategoryDescription,
                     coalesce(VS.SUBTYPE, ST.SUBTYPE) as SubTypeCode,
                     coalesce(' + dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0) + ','
                              + dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'ST',@sLookupCulture,0) + ') as SubTypeDescription,
                     coalesce(VB.BASIS, B.BASIS) as BasisCode,
                     coalesce(' + dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,0) + ','
                              + dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,0) + ') as BasisDescription,
                     ' + dbo.fn_SqlTranslatedColumn('PROFILES','PROFILENAME',null,'PF',@sLookupCulture,0) + ' as ProfileName,
                     PF.PROFILEID AS ProfileId,
                     cast(isnull(CR.RULEINUSE,0) as bit) as InUse,
					 CR.RULEINUSE as RuleInUse,
                     cast(case when isnull(CR.USERDEFINEDRULE,0) = 0 then 1 else 0 end as bit) as IsProtected,
                     cast(case when I.CRITERIANO is null then 0 else 1 end as bit) as IsInherited,
					 cast(case when exists(Select 1 from Inherits where FROMCRITERIA = CR.CRITERIANO) then 1 else 0 end as bit) as IsParent,'

if (@psCriteriaNumbers is not null)
Begin
    if (@psCriteriaNumbers = '')
              Begin
        Set @sSql = @sSql + char(10) +  ' null AS BestFit from CRITERIA CR'
    End
              Else
              Begin
        Set @sSql = @sSql + char(10) + ' null AS BestFit from dbo.fn_Tokenise(@psCriteriaNumbers, '','') T join CRITERIA CR on (CR.CRITERIANO = T.Parameter)'
    End
End
Else
       Begin
    Set @sSql = @sSql + char(10) + ' CR.BESTFIT AS BestFit 
              from dbo.fn_GetCriteriaRowsForControl (
                           @psPurposeCode,
                           @pnCaseOfficeID,
                           @psCaseType,
                           null, --@psAction,
                           null, --@pnCheckListType,
                           @psProgramID, 
                           null, --@pnRateNo,
                           @psPropertyType,
                           @psCountryCode,
                           @psCaseCategory,
                           @psSubType,
                           @psBasis,
                           null, --@psRegisteredUsers,
                           null, --@pnTypeOfMark,
                           null, --@pnLocalClientFlag,
                           null, --@pnTableCode,
                           null, --@pdtDateOfAct,
                           @pnRuleInUse,
                           null, --@pnPropertyUnknown,
                           null, --@pnCountryUnknown,
                           null, --@pnCategoryUnknown,
                           null, --@pnSubTypeUnknown,
                           null, --@psNewCaseType,
                           null, --@psNewPropertyType,
                           null, --@psNewCountryCode,
                           null, --@psNewCaseCategory,
                           null, --@pnRuleType,
                           null, --@psRequestType,
                           null, --@pnDataSourceType,
                           null, --@pnDataSourceNameNo,
                           null, --@pnRenewalStatus,
                           null, --@pnStatusCode,
                           @pbExactMatch,
                           @pnProfileKey,
                           @pbUserDefinedRule,
                           null --@psNewSubType
                    ) CR'
End

Set @sSql = @sSql + char(10) + 'left join INHERITS I on (I.CRITERIANO = CR.CRITERIANO)
              left join OFFICE O      on (O.OFFICEID=CR.CASEOFFICEID)
              left join PROGRAM PR on (PR.PROGRAMID=CR.PROGRAMID)
              left join CASETYPE CT   on (CT.CASETYPE=CR.CASETYPE)
              left join COUNTRY CN    on (CN.COUNTRYCODE=CR.COUNTRYCODE)
              left join VALIDPROPERTY VP 
                             on (VP.PROPERTYTYPE=CR.PROPERTYTYPE
                             and VP.COUNTRYCODE =(   Select MIN(VP1.COUNTRYCODE)
                                             from VALIDPROPERTY VP1
                                             where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
                                             and   VP1.COUNTRYCODE in (CR.COUNTRYCODE,''ZZZ'')))
              left join VALIDCATEGORY VC
                             on (VC.PROPERTYTYPE=CR.PROPERTYTYPE
                             and VC.CASETYPE    =CR.CASETYPE
                             and VC.CASECATEGORY=CR.CASECATEGORY
                             and VC.COUNTRYCODE =(   Select MIN(VC1.COUNTRYCODE)
                                             from VALIDCATEGORY VC1
                                             where VC1.PROPERTYTYPE=VC.PROPERTYTYPE
                                             and   VC1.CASETYPE    =VC.CASETYPE
                                             and   VC1.CASECATEGORY=VC.CASECATEGORY
                                             and   VC1.COUNTRYCODE in (CR.COUNTRYCODE,''ZZZ'')))
              left join CASECATEGORY CC
                             on (CC.CASETYPE    =CR.CASETYPE
                             and CC.CASECATEGORY=CR.CASECATEGORY
                             and VC.CASECATEGORY is null)  -- Only if Valid row cannot be found
              left join VALIDSUBTYPE VS
                             on (VS.PROPERTYTYPE=CR.PROPERTYTYPE
                             and VS.CASETYPE    =CR.CASETYPE
                             and VS.CASECATEGORY=CR.CASECATEGORY
                             and VS.SUBTYPE     =CR.SUBTYPE
                             and VS.COUNTRYCODE =(   Select MIN(VS1.COUNTRYCODE)
                                             from VALIDSUBTYPE VS1
                                             where VS1.PROPERTYTYPE=VS.PROPERTYTYPE
                                             and   VS1.CASETYPE    =VS.CASETYPE
                                             and   VS1.CASECATEGORY=VS.CASECATEGORY
                                             and   VS1.SUBTYPE     =VS.SUBTYPE
                                             and   VS1.COUNTRYCODE in (CR.COUNTRYCODE,''ZZZ'')))
              left join SUBTYPE ST    on (ST.SUBTYPE=CR.SUBTYPE
                             and VS.SUBTYPE is null)       -- Only if Valid row cannot be found
              left join VALIDBASIS VB
                             on (VB.PROPERTYTYPE=CR.PROPERTYTYPE
                             AND VB.BASIS = CR.BASIS
                             and VB.COUNTRYCODE =(Select MIN(VB1.COUNTRYCODE)
                                             from VALIDBASIS VB1
                                             where VB1.PROPERTYTYPE=VB.PROPERTYTYPE
                                             and         VB1.BASIS     =VB.BASIS
                                             and   VB1.COUNTRYCODE in (CR.COUNTRYCODE,''ZZZ'')))
              left join APPLICATIONBASIS B    on (B.BASIS = CR.BASIS
                                         and VB.BASIS is null)       -- Only if Valid row cannot be found
              left join PROFILES PF on PF.PROFILEID = CR.PROFILEID
              where CR.PURPOSECODE = @psPurposeCode'

if (@psCriteriaNumbers is null)
       Begin
    Set @sSql = @sSql + char(10) + 'Order By CR.BESTFIT DESC'
End

Set @sSql = @sSql + @sForceOrder

print @sSql

exec @ErrorCode=sp_executesql @sSql, 
                           N'@psPurposeCode           nchar(1),
                                  @pnCaseOfficeID            int = null,
                                  @psProgramID         nvarchar(8) = null,
                                  @psCaseType                nchar(1) = null,
                                  @psCountryCode             nvarchar(3) = null,
                                  @psPropertyType            nchar(1) = null,
                                  @psCaseCategory            nvarchar(2) = null,
                                  @psSubType           nvarchar(2) = null,
                                  @psBasis             nvarchar(2) = null,
                                  @pnProfileKey        int = null,
                                  @pnRuleInUse         bit,
                                  @pbExactMatch        bit,
                                  @pbUserDefinedRule   bit,
                                  @psCriteriaNumbers   nvarchar(max)',
                           @psPurposeCode = @psPurposeCode,
                           @pnCaseOfficeID      = @pnCaseOfficeID,
                           @psProgramID = @psProgramID,             
                           @psCaseType = @psCaseType,
                           @psCountryCode = @psCountryCode,
                           @psPropertyType = @psPropertyType,
                           @psCaseCategory = @psCaseCategory,
                           @psSubType = @psSubType,
                           @psBasis = @psBasis,
                           @pnProfileKey=@pnProfileKey,
                           @pnRuleInUse = @pnRuleInUse,
                           @pbExactMatch = @pbExactMatch,
                           @pbUserDefinedRule = @pbUserDefinedRule,
                           @psCriteriaNumbers = @psCriteriaNumbers

RETURN @ErrorCode
GO

grant execute on dbo.ipw_CaseScreenDesignerSearch  to public
go

