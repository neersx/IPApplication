-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListCaseScreenCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCaseScreenCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListCaseScreenCriteria.'
	Drop procedure [dbo].[ipw_ListCaseScreenCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_ListCaseScreenCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListCaseScreenCriteria
(			@pnRowCount		int		= 0	OUTPUT,
			@pnUserIdentityId	int,			-- Mandatory
			@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
			@psProgramID		nvarchar(8),		-- Mandatory
			@pnCaseId		int		= NULL,
			@pnCaseOfficeID		int		= NULL,
			@psCaseType		nchar(1)	= NULL,
			@psPropertyType		nchar(1)	= NULL,
			@psCountryCode		nvarchar(3)	= NULL,
			@psCaseCategory		nvarchar(2)	= NULL,
			@psSubType		nvarchar(2)	= NULL,
			@psBasis		nvarchar(2)	= NULL,
			@pnRuleInUse		bit		= NULL,
			@pnPropertyUnknown	bit		= NULL,
			@pnCountryUnknown	bit		= NULL,
			@pnCategoryUnknown	bit		= NULL,
			@pnSubTypeUnknown	bit		= NULL,
			@pbExactMatch		bit		= 0,	-- Set to 1 if non null parameters must match otherwisw Best Fit returned
			@pnProfileKey           int             = NULL
)
as
-- PROCEDURE:	ipw_ListCaseScreenCriteria
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the Case Screen Control criteria that matches the search
--		characteristics passed as input parameters.
--		If @pbExactMatch=1 then any non null input parameters must match Criteria column
--		If @pbExactMatch=0 then a Best Fit algorithm will return rows ordered with the 
--		best match in descending sequence.
--		Descriptions of codes will also be returned in the language requested if available.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Aug 2008	MF	RFC6921	1	Procedure created
-- 14 Sep 2009  LP      RFC8047 2       Added ProfileKey parameter

SET NOCOUNT ON

declare @nErrorCode		int
declare @sSQLString		nvarchar(4000)
declare @sLookupCulture		nvarchar(10)
declare @sCaseTypeDesc		nvarchar(200)
declare @sPropertyName		nvarchar(500)
declare @sCountry		nvarchar(200)
declare @sCaseCategoryDesc	nvarchar(500)
declare @sSubTypeDesc		nvarchar(500)
declare @sBasisDescription	nvarchar(500)
declare @sDescription		nvarchar(200)
declare @sOfficeDesc		nvarchar(200)

Set @nErrorCode=0

set @sLookupCulture= dbo.fn_GetLookupCulture(@psCulture, null, 0)
	
select	@sPropertyName	  ='isnull('+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0) +')',
				    
	@sCaseTypeDesc	  =dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0),
				    
	@sCountry	  =dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,0),
	
	@sCaseCategoryDesc='isnull('+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0) +')',
	
	@sSubTypeDesc	  ='isnull('+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0) +')',
	
	@sBasisDescription='isnull('+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,0) +')',
	
	@sDescription     =dbo.fn_SqlTranslatedColumn('CRITERIA','DESCRIPTION',null,'T',@sLookupCulture,0),
	
	@sOfficeDesc	  =dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,0)

If @nErrorCode=0
and @pnCaseId is not null
Begin
	Set @sSQLString="
	select	@pnCaseOfficeID	=C.OFFICEID,
		@psCaseType	=C.CASETYPE,
		@psPropertyType	=C.PROPERTYTYPE,
		@psCountryCode	=C.COUNTRYCODE,
		@psCaseCategory	=C.CASECATEGORY,
		@psSubType	=C.SUBTYPE,
		@psBasis	=P.BASIS
	from CASES C
	left join PROPERTY P on (P.CASEID=C.CASEID)
	where C.CASEID=@pnCaseId"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseOfficeID	int		OUTPUT,
					  @psCaseType		nchar(1)	OUTPUT,
					  @psPropertyType	nchar(1)	OUTPUT,
					  @psCountryCode	nvarchar(3)	OUTPUT,
					  @psCaseCategory	nvarchar(2)	OUTPUT,
					  @psSubType		nvarchar(2)	OUTPUT,
					  @psBasis		nvarchar(2)	OUTPUT,
					  @pnCaseId		int',
					  @pnCaseOfficeID=@pnCaseOfficeID	OUTPUT,
					  @psCaseType 	 =@psCaseType		OUTPUT,
					  @psPropertyType=@psPropertyType	OUTPUT,
					  @psCountryCode =@psCountryCode	OUTPUT,
					  @psCaseCategory=@psCaseCategory	OUTPUT,
					  @psSubType	 =@psSubType		OUTPUT,
					  @psBasis	 =@psBasis		OUTPUT,
					  @pnCaseId	 =@pnCaseId
End

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	T.CRITERIANO,	"+@sDescription+"  as DESCRIPTION,
		T.CASETYPE,	"+@sCaseTypeDesc+" as CASETYPEDESC,
		T.PROPERTYTYPE, "+@sPropertyName+" as PROPERTYNAME, 
		T.PROPERTYUNKNOWN,
		T.COUNTRYCODE,  "+@sCountry+"          as COUNTRY,
		T.COUNTRYUNKNOWN,  
		T.CASECATEGORY,	"+@sCaseCategoryDesc+" as CASECATEGORYDESC,
		T.CATEGORYUNKNOWN,
		T.SUBTYPE,	"+@sSubTypeDesc+"      as SUBTYPEDESC,
		T.SUBTYPEUNKNOWN,  
		T.BASIS,	"+@sBasisDescription+" as BASISDESCRIPTION,  
		T.USERDEFINEDRULE,  
		T.RULEINUSE,  
		T.STARTDETAILENTRY,  
		T.PARENTCRITERIA,
		T.BELONGSTOGROUP,  
		T.CASEOFFICEID, "+@sOfficeDesc+ " as OFFICEDESC,
		T.BESTFIT,
		T.PROFILEID,
		PR.PROFILENAME as PROFILE
	from dbo.fn_GetCriteriaRows
			(
			'W',			-- @psPurposeCode 
 	 		@pnCaseOfficeID,
			@psCaseType,
			DEFAULT,		-- @psAction
			DEFAULT,		-- @pnCheckListType
			@psProgramID,
			DEFAULT,		-- @pnRateNo
			@psPropertyType,
			@psCountryCode,
			@psCaseCategory,
			@psSubType,
			@psBasis,
			DEFAULT,		-- @psRegisteredUsers
			DEFAULT,		-- @pnTypeOfMark
			DEFAULT,		-- @pnLocalClientFlag
			DEFAULT,		-- @pnTableCode
			DEFAULT,		-- @pdtDateOfAct
			@pnRuleInUse,
			@pnPropertyUnknown,
			@pnCountryUnknown,
			@pnCategoryUnknown,
			@pnSubTypeUnknown,
			DEFAULT,		-- @psNewCaseType
			DEFAULT,		-- @psNewPropertyType
			DEFAULT,		-- @psNewCountryCode
			DEFAULT,		-- @psNewCaseCategory
			DEFAULT,		-- @pnRuleType
			DEFAULT,		-- @psRequestType
			DEFAULT,		-- @pnDataSourceType
			DEFAULT,		-- @pnDataSourceNameNo
			DEFAULT,		-- @pnRenewalStatus
			DEFAULT,		-- @pnStatusCode
			@pbExactMatch,
			@pnProfileKey
			) T
	left join CASETYPE CT		on (CT.CASETYPE=T.CASETYPE)
	
	left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=T.PROPERTYTYPE
					and VP.COUNTRYCODE =(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))
	left join PROPERTYTYPE P	on (P.PROPERTYTYPE=T.PROPERTYTYPE)
								
	left join COUNTRY C		on (C.COUNTRYCODE=T.COUNTRYCODE)
	
	left join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=T.PROPERTYTYPE
					and VC.CASETYPE    =T.CASETYPE
					and VC.CASECATEGORY=T.CASECATEGORY
					and VC.COUNTRYCODE =(	select min(VC1.COUNTRYCODE)
								from VALIDCATEGORY VC1
								where VC1.CASETYPE=T.CASETYPE
								and VC1.PROPERTYTYPE=T.PROPERTYTYPE
								and VC1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))
	left join CASECATEGORY CC	on (CC.CASETYPE=T.CASETYPE
					and CC.CASECATEGORY=T.CASECATEGORY)
	
	left join VALIDSUBTYPE VS	on (VS.PROPERTYTYPE=T.PROPERTYTYPE
					and VS.CASETYPE    =T.CASETYPE
					and VS.CASECATEGORY=T.CASECATEGORY
					and VS.SUBTYPE     =T.SUBTYPE
					and VS.COUNTRYCODE =(	select min(VS1.COUNTRYCODE)
								from VALIDSUBTYPE VS1
								where VS1.CASETYPE=T.CASETYPE
								and VS1.PROPERTYTYPE=T.PROPERTYTYPE
								and VS1.CASECATEGORY=T.CASECATEGORY
								and VS1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))
	left join SUBTYPE S		on (S.SUBTYPE=T.SUBTYPE)
	
	left join VALIDBASIS VB		on (VB.PROPERTYTYPE=T.PROPERTYTYPE
					and VB.BASIS=T.BASIS
					and VB.COUNTRYCODE =(	select min(VB1.COUNTRYCODE)
								from VALIDBASIS VB1
								where VB1.PROPERTYTYPE=T.PROPERTYTYPE
								and VB1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ')))
	left join APPLICATIONBASIS B	on (B.BASIS=T.BASIS)
	left join OFFICE O		on (O.OFFICEID=T.CASEOFFICEID)
	left join PROFILES PR           on (PR.PROFILEID=T.PROFILEID)
	ORDER BY T.BESTFIT desc, 
		 T.CASETYPE,
		 T.PROPERTYTYPE,
		 T.COUNTRYCODE,
		 T.CASECATEGORY,
		 T.SUBTYPE,
		 T.BASIS,  
		 T.USERDEFINEDRULE desc"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@psProgramID		nvarchar(8),	
				  @pnCaseOfficeID	int,
				  @psCaseType		nchar(1),
				  @psPropertyType	nchar(1),
				  @psCountryCode	nvarchar(3),
				  @psCaseCategory	nvarchar(2),
				  @psSubType		nvarchar(2),
				  @psBasis		nvarchar(2),
				  @pnRuleInUse		bit,
				  @pnPropertyUnknown	bit,
				  @pnCountryUnknown	bit,
				  @pnCategoryUnknown	bit,
				  @pnSubTypeUnknown	bit,
				  @pbExactMatch		bit,
				  @pnProfileKey         int',
				  @psProgramID		=@psProgramID,
				  @pnCaseOfficeID	=@pnCaseOfficeID,
				  @psCaseType		=@psCaseType,
				  @psPropertyType	=@psPropertyType,
				  @psCountryCode	=@psCountryCode,
				  @psCaseCategory	=@psCaseCategory,
				  @psSubType		=@psSubType,
				  @psBasis		=@psBasis,
				  @pnRuleInUse		=@pnRuleInUse,
				  @pnPropertyUnknown	=@pnPropertyUnknown,
				  @pnCountryUnknown	=@pnCountryUnknown,
				  @pnCategoryUnknown	=@pnCategoryUnknown,
				  @pnSubTypeUnknown	=@pnSubTypeUnknown,
				  @pbExactMatch		=@pbExactMatch,
				  @pnProfileKey         =@pnProfileKey
	
	Set @pnRowCount=@@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListCaseScreenCriteria to public
GO
