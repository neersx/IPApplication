-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListComparisonSystem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListComparisonSystem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListComparisonSystem.'
	Drop procedure [dbo].[csw_ListComparisonSystem]
End
Print '**** Creating Stored Procedure dbo.csw_ListComparisonSystem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListComparisonSystem
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbIsExternalUser 	bit,		-- Mandatory 		
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_ListComparisonSystem
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the list of data sources.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Sep 2005	TM	RFC3008	1	Procedure created
-- 28 Jun 2005	SW	RFC4038	2	Add RowKey
-- 12 Jul 2006	SW	RFC3828	3	Pass getdate() to fn_Permission..
-- 06 Sep 2006	LP	RFC3559	4	Populate result set from new DATAEXRACTMODULE data structure
-- 08 Jan 2006	MF	SQA12298 5	Change of parameters for fn_GetCriteriaRows
-- 14 Sep 2009  LP      RFC8047 6       Pass null as ProfileKey parameter for fn_GetCriteriaRows
-- 07 Sep 2018	AV	74738	7	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

Declare @bHasAccess	bit
Declare @nCaseOfficeID 	int
Declare @sCaseType 	nchar(1)
Declare @sPropertyType	nchar(1)
Declare @sCountryCode	nvarchar(3)	
Declare @nTableCode	int
Declare @dtToday	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @bHasAccess = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @dtToday	= getdate()

-- Check whether the user has access to View Case Data Comparison task:
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @bHasAccess = 1
	from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', 55, null, @dtToday) PG
	where (PG.CanExecute = 1)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @bHasAccess		bit			OUTPUT,
					  @dtToday		datetime',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @bHasAccess		= @bHasAccess 		OUTPUT,
					  @dtToday		= @dtToday
End

If @nErrorCode = 0
and @pnCaseKey is not null
and @bHasAccess = 1
Begin
	Set @sSQLString = " 
	Select  @nCaseOfficeID		= C.OFFICEID,
		@sCaseType		= C.CASETYPE,
		@sPropertyType		= C.PROPERTYTYPE,
		@sCountryCode		= C.COUNTRYCODE,
		@nTableCode		= TC.TABLECODE
	from CASES C 	
	left join PROPERTY P		on (P.CASEID = C.CASEID)
	left join STATUS RS		on (RS.STATUSCODE = P.RENEWALSTATUS)
	left join STATUS ST		on (ST.STATUSCODE = C.STATUSCODE)
	left join TABLECODES TC 	on (TC.TABLECODE = CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) THEN 7603
							        WHEN(ST.REGISTEREDFLAG=1) THEN 7602
							        ELSE 7601
							   END)
	where C.CASEID = @pnCaseKey" 

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nCaseOfficeID		int			OUTPUT,		  
					  @sCaseType			nchar(1)		OUTPUT,
					  @sPropertyType		nchar(1)		OUTPUT,
					  @sCountryCode			nvarchar(3)		OUTPUT,
					  @nTableCode			int			OUTPUT,
					  @pnCaseKey		 	int',
					  @nCaseOfficeID		= @nCaseOfficeID	OUTPUT,
					  @sCaseType			= @sCaseType	   	OUTPUT,
				   	  @sPropertyType		= @sPropertyType 	OUTPUT,
					  @sCountryCode			= @sCountryCode		OUTPUT,
					  @nTableCode			= @nTableCode		OUTPUT,
					  @pnCaseKey		 	= @pnCaseKey						  
End

--SELECT  @nCaseOfficeID AS 'OFFICE', @sCaseType AS 'CASE TYPE', @sPropertyType AS 'PROPERTY', 
--@sCountryCode AS 'COUNTRY', @nTableCode	 AS 'TABLECODE'

-- Populate ComparisonSystem result set
If @nErrorCode = 0
Begin	
	Set @sSQLString="
	Select 	cast(DE.DATAEXTRACTID as nvarchar(10)) 	as RowKey,
		@pnCaseKey 				as CaseKey,
		ISNULL(" + dbo.fn_SqlTranslatedColumn('DATAEXTRACTMODULE','EXTRACTNAME',null,'DE',@sLookupCulture,@pbCalledFromCentura) + ","
			 + dbo.fn_SqlTranslatedColumn('EXTERNALSYSTEM','SYSTEMNAME',null,'ES',@sLookupCulture,@pbCalledFromCentura) +  
							") as DataExtractName,
		CR.DATAEXTRACTID			as DataExtractKey
	from dbo.fn_GetCriteriaRows(	'D',		-- @psPurposeCode	
					@nCaseOfficeID,	-- @pnCaseOfficeID
					@sCaseType,	-- @psCaseType
					null,		-- @psAction
					null,		-- @pnCheckListType
					null,		-- @psProgramID
					null,		-- @pnRateNo
					@sPropertyType,	-- @psPropertyType
					@sCountryCode,	-- @psCountryCode
					null,		-- @psCaseCategory
					null,		-- @psSubType
					null,		-- @psBasis
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
	join DATAEXTRACTMODULE DE	on (DE.DATAEXTRACTID = CR.DATAEXTRACTID)	
	join EXTERNALSYSTEM ES		on (ES.SYSTEMID = DE.SYSTEMID)
	left join SITECONTROL SC	on (SC.CONTROLID = DE.SITECONTROLID)
	-- The result set should only be populated if the user has access to the View Case Data Comparison task.
	where @bHasAccess = 1
	and (DE.SITECONTROLID IS NULL or DE.SITECONTROLID='' or 
		(SC.DATATYPE='I' and SC.COLINTEGER is not null) or 
		(SC.DATATYPE='C' and SC.COLCHARACTER is not null) or 
		(SC.DATATYPE='D' and SC.COLDECIMAL is not null) or 
		(SC.DATATYPE='T' and SC.COLDATE is not null) or 
		(SC.DATATYPE='B' and SC.COLBOOLEAN = 1))
	order by CR.BESTFIT, DataExtractName"

	exec sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @nCaseOfficeID	int,
				  @sCaseType		nchar(1),
				  @sPropertyType	nchar(1),
				  @sCountryCode		nvarchar(3),
				  @nTableCode		int,
				  @bHasAccess		bit',
				  @pnCaseKey		= @pnCaseKey,
				  @nCaseOfficeID	= @nCaseOfficeID,
				  @sCaseType		= @sCaseType,
				  @sPropertyType	= @sPropertyType,
				  @sCountryCode		= @sCountryCode,
				  @nTableCode		= @nTableCode,
				  @bHasAccess		= @bHasAccess					
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListComparisonSystem to public
GO
