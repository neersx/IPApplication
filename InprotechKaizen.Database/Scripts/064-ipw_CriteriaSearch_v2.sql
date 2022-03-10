-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_CriteriaSearch
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_CriteriaSearch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_CriteriaSearch.'
	drop procedure dbo.ipw_CriteriaSearch
	print '**** Creating procedure dbo.ipw_CriteriaSearch...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_CriteriaSearch
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null,
	
	-- fn_GetCriteriaRowsForControl params
	@psPurposeCode		nchar(1),
	@pnCaseOfficeID		int = null,
	@psCaseType		nchar(1) = null,
	@psAction		nvarchar(2) = null,
	@psPropertyType		nchar(1) = null,
	@psCountryCode		nvarchar(3) = null,
	@psCaseCategory		nvarchar(2) = null,
	@psSubType		nvarchar(2) = null,
	@psBasis		nvarchar(2) = null,
	@pnLocalClientFlag	bit = null,
	@pdtDateOfAct		datetime = null,
	@pnRuleInUse		bit = null,
	@pbExactMatch		bit = null,
	@pbUserDefinedRule	bit = null,	
	@psCriteriaNumbers	nvarchar(max) = null,
	@pnEventNo		int = null,
	@pbEventReferenced	bit = 0
)	
-- PROCEDURE :	ipw_CriteriaSearch
-- VERSION :	2
-- DESCRIPTION:	Lists Criteria that match the selection parameters.

-- Modifications
--
-- Date		Who	Number	Version	Description
-- ------------	------	-------	-------	------------------------------------
-- 15/01/2016	AT	R56922	1	Procedure created.
-- 10/02/2016	AT	R51210	2	Add searching by Event.

AS
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	declare @ErrorCode		int
	declare @sSql		nvarchar(max)
	declare @sLookupCulture		nvarchar(10)
	declare @sForceOrder	nvarchar(30)
	
	set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
	set @sForceOrder = ' '
      
	Set @sSql = 'Select 	CR.CRITERIANO as Id,
			' + dbo.fn_SqlTranslatedColumn('CRITERIA','DESCRIPTION',null,'CR',@sLookupCulture,0) + ' as CriteriaName,
			O.OFFICEID as OfficeCode,
			' + dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,0) + ' as OfficeDescription,
			CT.CASETYPE AS CaseTypeCode,
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
			coalesce(VA.ACTION, AC.ACTION) as ActionCode,
			coalesce(' + dbo.fn_SqlTranslatedColumn('VALIDACTION','ACTIONNAME',null,'VA',@sLookupCulture,0) + ','
				   + dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'AC',@sLookupCulture,0) + ') as ActionDescription,
			CR.DATEOFACT as DateOfLaw,
			cast(isnull(CR.LOCALCLIENTFLAG,0) as bit) as IsLocalClient,
			cast(isnull(CR.RULEINUSE,0) as bit) as InUse,
			cast(case when isnull(CR.USERDEFINEDRULE,0) = 0 then 1 else 0 end as bit) as IsProtected'
			
	if (@psCriteriaNumbers is not null)
	Begin
		if (@psCriteriaNumbers = '')
		Begin
			Set @sSql = @sSql + char(10) + 'from CRITERIA CR'			
		End
		Else
		Begin
			Set @sSql = @sSql + char(10) + 'from dbo.fn_Tokenise(@psCriteriaNumbers, '','') T join CRITERIA CR on (CR.CRITERIANO = T.Parameter)'
		End		
	End
	Else
	Begin
	Set @sSql = @sSql + char(10) + 'from dbo.fn_GetCriteriaRowsForControl (
				@psPurposeCode,
				@pnCaseOfficeID,
				@psCaseType,
				@psAction,
				null, --@pnCheckListType,
				null, --@psProgramID,
				null, --@pnRateNo,
				@psPropertyType,
				@psCountryCode,
				@psCaseCategory,
				@psSubType,
				@psBasis,
				null, --@psRegisteredUsers,
				null, --@pnTypeOfMark,
				@pnLocalClientFlag,
				null, --@pnTableCode,
				@pdtDateOfAct,
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
				null, --@pnProfileKey,
				@pbUserDefinedRule,
				null --@psNewSubType
		      ) CR'
	End

	if (@pnEventNo is not null)
	Begin
		Set @sForceOrder = ' OPTION (FORCE ORDER)'
		
		if (@pbEventReferenced = 0)
		Begin
			Set @sSql = @sSql + char(10) + 'join EVENTCONTROL EC on (EC.CRITERIANO = CR.CRITERIANO
										and EC.EVENTNO = @pnEventNo)'
		End
		Else
		Begin
			Set @sSql = @sSql + char(10) + 
				'join 
				(Select DISTINCT ECX.CRITERIANO
				From EVENTCONTROL ECX
				left join DUEDATECALC DDC on DDC.CRITERIANO = ECX.CRITERIANO
							and DDC.EVENTNO = ECX.EVENTNO
							and @pnEventNo in (DDC.FROMEVENT, DDC.COMPAREEVENT)
				left join DATESLOGIC DL on DL.CRITERIANO = ECX.CRITERIANO
							and DL.EVENTNO = ECX.EVENTNO	
							and DL.COMPAREEVENT = @pnEventNo		
				left join RELATEDEVENTS RE on RE.CRITERIANO = ECX.CRITERIANO
							and RE.EVENTNO = ECX.EVENTNO
							and RE.RELATEDEVENT = @pnEventNo
				left join DETAILDATES DD on DD.CRITERIANO = ECX.CRITERIANO
							and @pnEventNo in (DD.EVENTNO, DD.OTHEREVENTNO)
				left join DETAILCONTROL DC on DC.CRITERIANO = ECX.CRITERIANO
							and @pnEventNo in (DC.DISPLAYEVENTNO, DC.HIDEEVENTNO, DC.DIMEVENTNO)
				WHERE (ECX.EVENTNO = @pnEventNo or ECX.UPDATEFROMEVENT = @pnEventNo)
				or DDC.CRITERIANO IS NOT NULL
				or DL.CRITERIANO IS NOT NULL
				or RE.CRITERIANO IS NOT NULL
				or DD.CRITERIANO IS NOT NULL
				or DC.CRITERIANO IS NOT NULL) as EC on EC.CRITERIANO = CR.CRITERIANO'
		End
	End
		
	Set @sSql = @sSql + char(10) + 'left join OFFICE O      on (O.OFFICEID=CR.CASEOFFICEID)
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
						    and	  VB1.BASIS	  =VB.BASIS
						    and   VB1.COUNTRYCODE in (CR.COUNTRYCODE,''ZZZ'')))
		left join APPLICATIONBASIS B    on (B.BASIS = CR.BASIS
						and VB.BASIS is null)       -- Only if Valid row cannot be found
		left join VALIDACTION VA
				  on (VA.PROPERTYTYPE=CR.PROPERTYTYPE
				  and VA.CASETYPE    =CR.CASETYPE
				  and VA.ACTION      =CR.ACTION
				  and VA.COUNTRYCODE =(   Select MIN(VA1.COUNTRYCODE)
						    from VALIDACTION VA1
						    where VA1.PROPERTYTYPE=VA.PROPERTYTYPE
						    and   VA1.CASETYPE    =VA.CASETYPE
						    and   VA1.ACTION      =VA.ACTION
						    and   VA1.COUNTRYCODE in (CR.COUNTRYCODE,''ZZZ'')))
		left join ACTIONS AC    on (AC.ACTION=CR.ACTION
				  and VA.ACTION is null)        -- Only if Valid row cannot be found
		where CR.PURPOSECODE = @psPurposeCode'

	if (@psCriteriaNumbers is null)
	Begin
		Set @sSql = @sSql + char(10) + 'Order By CR.BESTFIT'
	End

	Set @sSql = @sSql + @sForceOrder

	exec @ErrorCode=sp_executesql @sSql, 
				N'@psPurposeCode	nchar(1),
				@pnCaseOfficeID		int,
				@psCaseType		nchar(1),
				@psAction		nvarchar(2),
				@psPropertyType		nchar(1),
				@psCountryCode		nvarchar(3),
				@psCaseCategory		nvarchar(2),
				@psSubType		nvarchar(2),
				@psBasis		nvarchar(2),
				@pnLocalClientFlag	bit,
				@pdtDateOfAct		datetime,
				@pnRuleInUse		bit,
				@pbExactMatch		bit,
				@pbUserDefinedRule	bit,
				@psCriteriaNumbers	nvarchar(max),
				@pnEventNo			int',
				@psPurposeCode = @psPurposeCode,
				@pnCaseOfficeID	= @pnCaseOfficeID,
				@psCaseType = @psCaseType,
				@psAction = @psAction,
				@psPropertyType = @psPropertyType,
				@psCountryCode = @psCountryCode,
				@psCaseCategory = @psCaseCategory,
				@psSubType = @psSubType,
				@psBasis = @psBasis,
				@pnLocalClientFlag = @pnLocalClientFlag,
				@pdtDateOfAct = @pdtDateOfAct,
				@pnRuleInUse = @pnRuleInUse,
				@pbExactMatch = @pbExactMatch,
				@pbUserDefinedRule = @pbUserDefinedRule,
				@psCriteriaNumbers = @psCriteriaNumbers,
				@pnEventNo = @pnEventNo

	RETURN @ErrorCode
go

grant execute on dbo.ipw_CriteriaSearch  to public
go

