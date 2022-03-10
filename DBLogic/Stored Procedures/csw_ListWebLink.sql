-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListWebLink 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListWebLink ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListWebLink .'
	Drop procedure [dbo].[csw_ListWebLink ]
End
Print '**** Creating Stored Procedure dbo.csw_ListWebLink ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListWebLink 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbIsExternalUser 	bit,		-- Mandatory 		
	@pbCalledFromCentura	bit		= 0,
	@psResultsetsRequired	nvarchar(4000) 	= null	-- comma seperated list to describe which resultset to return
)
AS
-- PROCEDURE:	csw_ListWebLink 
-- VERSION:	11
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populate the WebLinkGroup and WebLink data tables.  
-- COPYRIGHT :	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 05 Nov 2004  TM	R1233	1	Procedure created
-- 08 Nov 2004	TM	R1233	2	Remove the left join on the TABLECODES from second result set.
-- 15 May 2005	JEK	R2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 14 Jul 2005	JD	10717	4	Added the extra parameters required for dbo.fn_GetCriteriaRows.
-- 30 Jun 2006	SW	R4038	5	Add RowKey
-- 19 Jul 2006	SW	R3217	6	implement new param @psResultsetsRequired to optionally return resultset
-- 08 Jan 2006	MF	S12298	7	Change of parameters for fn_GetCriteriaRows
-- 14 Sep 2009  LP      R8047	8	Pass null as ProfileKey parameter for fn_GetCriteriaRows
-- 24 Oct 2011	ASH	R11460	9	Cast integer columns as nvarchar(11) data type.
-- 23 Aug 2012	MF	R12626	10	Case Links are to also include Category, Sub Type and Basis in the best fit search criteria.
-- 15 Apr 2013	DV	R13270	11	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Turn @psResultsetsRequired to '' if @psResultsetsRequired passed in as ',' or null,
-- remove spaces from @psResultsetsRequired and pad ',' to the end
Set @psResultsetsRequired = upper(replace(isnull(nullif(@psResultsetsRequired, ','), ''), ' ', '')) + ','

Declare @nCaseOfficeID 	int
Declare @sCaseType 	nchar(1)
Declare @sPropertyType	nchar(1)
Declare @nTableCode 	int 		
Declare @sCountryCode	nvarchar(3)	
Declare @sCategory	nvarchar(2)	
Declare @sSubType	nvarchar(2)	
Declare @sBasis		nvarchar(2)	

Set	@nErrorCode      = 0

If @nErrorCode = 0
and @pnCaseKey is not null
Begin
		Set @sSQLString = " 
		Select  @nCaseOfficeID		= C.OFFICEID,
			@sCaseType		= C.CASETYPE,
			@sPropertyType		= C.PROPERTYTYPE,
			@nTableCode		= TC.TABLECODE,
			@sCountryCode		= C.COUNTRYCODE,
			@sCategory		= C.CASECATEGORY,
			@sSubType		= C.SUBTYPE,
			@sBasis			= P.BASIS
		from CASES C 	
		left join PROPERTY P		on (P.CASEID = C.CASEID)
		left join STATUS RS		on (RS.STATUSCODE = P.RENEWALSTATUS)
		left join STATUS ST		on (ST.STATUSCODE = C.STATUSCODE)
		left join TABLECODES TC		on (TC.TABLECODE = CASE WHEN(ST.LIVEFLAG = 0 or RS.LIVEFLAG = 0) THEN 7603
				                                   	WHEN(ST.REGISTEREDFLAG = 1)           	 THEN 7602
					                                ELSE 7601  			                 
								   END)
		where C.CASEID = @pnCaseKey" 
	
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnCaseKey		 	int,
						  @nCaseOfficeID		int			  OUTPUT,
						  @sCaseType			nchar(1)		  OUTPUT,
						  @sPropertyType		nchar(1)		  OUTPUT,
						  @nTableCode			int			  OUTPUT,
						  @sCountryCode			nvarchar(3)		  OUTPUT,
						  @sCategory			nvarchar(2)		  OUTPUT,
						  @sSubType			nvarchar(2)		  OUTPUT,
						  @sBasis			nvarchar(2)		  OUTPUT',
						  @pnCaseKey		 	= @pnCaseKey,
						  @nCaseOfficeID		= @nCaseOfficeID	  OUTPUT,
						  @sCaseType			= @sCaseType		  OUTPUT,
					   	  @sPropertyType		= @sPropertyType	  OUTPUT,
						  @nTableCode			= @nTableCode		  OUTPUT,
						  @sCountryCode			= @sCountryCode		  OUTPUT,
						  @sCategory			= @sCategory		  OUTPUT,
						  @sSubType			= @sSubType		  OUTPUT,
						  @sBasis			= @sBasis		  OUTPUT

	If @nErrorCode = 0
	and (@psResultsetsRequired = ',' or CHARINDEX('WEBLINKGROUP,', @psResultsetsRequired) <> 0)
	Begin	
		-- Populate the new WebLinkGroup datatable
	
		Set @sSQLString="
		Select 	distinct
			CR.GROUPID 		as GroupKey,	
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+"
						as GroupName,
			@pnCaseKey		as CaseKey,
			  cast (@pnCaseKey as nvarchar(11)) + '^'
			+ cast (CR.GROUPID as nvarchar(11))	as RowKey
		from dbo.fn_GetCriteriaRows(	'L',		-- @psPurposeCode	
						@nCaseOfficeID,	-- @pnCaseOfficeID
						@sCaseType,	-- @psCaseType
						null,		-- @psAction
						null,		-- @pnCheckListType
						null,		-- @psProgramID
						null,		-- @pnRateNo
						@sPropertyType,	-- @psPropertyType
						@sCountryCode,	-- @psCountryCode
						@sCategory,	-- @psCaseCategory
						@sSubType,	-- @psSubType
						@sBasis,	-- @psBasis
						null,		-- @psRegisteredUsers
						null,		-- @pnTypeOfMark
						null,		-- @pnLocalClientFlag
						@nTableCode,	-- @pnTableCode
						null,		-- @pdtDateOfAct
						null,		-- @pnRuleInUse
						null,		-- @pnPropertyUnknown
						null,		-- @pnCountryUnknown
						null,		-- @pnCategoryUnknown
						null,		-- @pnSubTypeUnknown
						null,		-- @psNewCaseType
						null,		-- @psNewPropertyType
						null,		-- @psNewCountryCode
						null,		-- @psNewCaseCategory
						null,		-- @pnRuleType		--SQA12298
						null,		-- @psRequestType	--SQA12298
						null,		-- @pnDataSourceType	--SQA12298
						null,		-- @pnDataSourceNameNo	--SQA12298
						null,		-- @pnRenewalStatus	--SQA12298
						null,		-- @pnStatusCode	--SQA12298
						0,		-- @pbExactMatch
						null            -- @pnProfileKey
					   )	CR
		left join TABLECODES TC		on (TC.TABLECODE = CR.GROUPID)
		where CR.GROUPID is not null"+char(10)+
		-- For external users, select only links where ISPUBLIC=1.
		CASE 	WHEN @pbIsExternalUser = 1
			THEN "and   CR.ISPUBLIC = 1"
		END+CHAR(10)+
		"order by GroupName, GroupKey"
	
		exec sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @nCaseOfficeID	int,
					  @sCaseType		nchar(1),
					  @sPropertyType	nchar(1),
					  @nTableCode		int,
					  @sCountryCode		nvarchar(3),
					  @sCategory		nvarchar(2),
					  @sSubType		nvarchar(2),
					  @sBasis		nvarchar(2)',
					  @pnCaseKey		= @pnCaseKey,
					  @nCaseOfficeID	= @nCaseOfficeID,
					  @sCaseType		= @sCaseType,
					  @sPropertyType	= @sPropertyType,
					  @nTableCode		= @nTableCode,
					  @sCountryCode		= @sCountryCode,
					  @sCategory		= @sCategory,
					  @sSubType		= @sSubType,
					  @sBasis		= @sBasis
	
	End

	-- Populate the new WebLink datatable
	If @nErrorCode = 0
	and (@psResultsetsRequired = ',' or CHARINDEX('WEBLINK,', @psResultsetsRequired) <> 0)
	Begin	
		Set @sSQLString="
		Select 	@pnCaseKey		as CaseKey,
			CR.GROUPID 		as GroupKey,	
			"+dbo.fn_SqlTranslatedColumn('CRITERIA','LINKTITLE',null,'CR',@sLookupCulture,@pbCalledFromCentura)+"
						as LinkTitle,
			"+dbo.fn_SqlTranslatedColumn('CRITERIA','LINKDESCRIPTION',null,'CR',@sLookupCulture,@pbCalledFromCentura)+"
						as LinkDescription,
			CR.DOCITEMID		as DocItemKey,
			CR.URL			as URL,
			  cast (@pnCaseKey as nvarchar(11)) + '^'
			+ cast (CR.CRITERIANO as nvarchar(11))	as RowKey
		from dbo.fn_GetCriteriaRows(	'L',		-- @psPurposeCode	
						@nCaseOfficeID,	-- @pnCaseOfficeID
						@sCaseType,	-- @psCaseType
						null,		-- @psAction
						null,		-- @pnCheckListType
						null,		-- @psProgramID
						null,		-- @pnRateNo
						@sPropertyType,	-- @psPropertyType
						@sCountryCode,	-- @psCountryCode
						@sCategory,	-- @psCaseCategory
						@sSubType,	-- @psSubType
						@sBasis,	-- @psBasis
						null,		-- @psRegisteredUsers
						null,		-- @pnTypeOfMark
						null,		-- @pnLocalClientFlag
						@nTableCode,	-- @pnTableCode
						null,		-- @pdtDateOfAct
						null,		-- @pnRuleInUse
						null,		-- @pnPropertyUnknown
						null,		-- @pnCountryUnknown
						null,		-- @pnCategoryUnknown
						null,		-- @pnSubTypeUnknown
						null,		-- @psNewCaseType
						null,		-- @psNewPropertyType
						null,		-- @psNewCountryCode
						null,		-- @psNewCaseCategory
						null,		-- @pnRuleType		--SQA12298
						null,		-- @psRequestType	--SQA12298
						null,		-- @pnDataSourceType	--SQA12298
						null,		-- @pnDataSourceNameNo	--SQA12298
						null,		-- @pnRenewalStatus	--SQA12298
						null,		-- @pnStatusCode	--SQA12298
						0,		-- @pbExactMatch
						null            -- @pnProfileKey
					   )	CR"+char(10)+
		-- For external users, select only links where ISPUBLIC=1.
		CASE 	WHEN @pbIsExternalUser = 1
			THEN "where CR.ISPUBLIC = 1"
		END+CHAR(10)+
		"order by GroupKey, BESTFIT, LinkTitle"

		exec sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @nCaseOfficeID	int,
					  @sCaseType		nchar(1),
					  @sPropertyType	nchar(1),
					  @nTableCode		int,
					  @sCountryCode		nvarchar(3),
					  @sCategory		nvarchar(2),
					  @sSubType		nvarchar(2),
					  @sBasis		nvarchar(2)',
					  @pnCaseKey		= @pnCaseKey,
					  @nCaseOfficeID	= @nCaseOfficeID,
					  @sCaseType		= @sCaseType,
					  @sPropertyType	= @sPropertyType,
					  @nTableCode		= @nTableCode,
					  @sCountryCode		= @sCountryCode,
					  @sCategory		= @sCategory,
					  @sSubType		= @sSubType,
					  @sBasis		= @sBasis
	
	End
End
Else
If @nErrorCode = 0
and @pnCaseKey is null
Begin	

	If (@psResultsetsRequired = ',' or CHARINDEX('WEBLINKGROUP,', @psResultsetsRequired) <> 0)
	Begin
		Select  null	as GroupKey, 
			null	as GroupName,
			null	as CaseKey,
			null	as RowKey
		where 1=0
	End

	If (@psResultsetsRequired = ',' or CHARINDEX('WEBLINK,', @psResultsetsRequired) <> 0)
	Begin
		Select  null	as CaseKey, 
			null	as GroupKey,
			null	as LinkTitle,
			null	as LinkDescription,
			null	as DocItemKey,
			null	as URL,
			null	as RowKey
		where 1=0
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListWebLink  to public
GO
