-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListNameTypeMetaData 									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListNameTypeMetaData ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListNameTypeMetaData .'
	Drop procedure [dbo].[csw_ListNameTypeMetaData ]
End
Print '**** Creating Stored Procedure dbo.csw_ListNameTypeMetaData ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListNameTypeMetaData 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		= null, -- The unique identifier for the case. Mandatory for a existing case.	
	@psNewCaseTypeCode	nchar(1)	= null,	-- The case type of a new case. Mandatory for a new case. Required to access screen control rules.
	@pbAllRows	bit	= 0 	-- Indicate that all rows will be returned
)
as
-- PROCEDURE:	csw_ListNameTypeMetaData 
-- VERSION:	14
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CaseNameMetaDataEntity business entity.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	----------	-------	-----------------------------------------------
-- 07 Dec 2005	TM	RFC3305		1	Procedure created
-- 08 Dec 2005	TM	RFC3305		2	Populate all fields for a new case. 
--						Add new NameTypeDescription column.
-- 02 May 2006	AU	RFC3305		3	Added new columns; Replaced hard-coding of name types
--						with call to dbo.fn_GetScreenControlNameTypes
-- 14 Jun 2006	IB	RFC3720		4	Add IsUpdatedFromParent column.
-- 15 Sep 2006	JEK	RFC4144		5	Obtain IsMandatory for new cases from client/server field control rules.
-- 08 Jan 2006	MF	SQA12298	6	Change of parameters for fn_GetCriteriaRows
-- 22 Jan 2007	AU	RFC4148		7	Add FutureNameTypeCode column. 
-- 10 Jun 2008	SF	RFC6643		8	Add IsCRMOnly, IsRestrictToSameNameType columns; Add @pbAllRows parameter
-- 07 Oct 2008	AT	RFC6895		9	Add support for CRM cases, filter out bulk name types.
-- 11 Dec 2008	MF	17136		10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Mar 2009	JC	RFC7209		11	Change PurposeCode from 'S' to 'W'
-- 14 Sep 2009  LP      RFC8047         12      Pass null as ProfileKey parameter for fn_GetCriteriaRows
-- 16 Sep 2014  SW      R27882          13      Applied Union with fnw_FilteredTopicNameTypes to get metadata for hidden name types
-- 19 Jul 2017	MF	71968		14	When determining the default Case program, first consider the Profile of the User.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @nNewCaseCriteriaNo	int
Declare	@sProgramKey 		nvarchar(8)
Declare @bIsCRMCaseType		bit
Declare @nScreenCriteriaKey     int
Declare @nProfileKey            int

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bIsCRMCaseType	= 0

-- Get the appropriate program key
If @nErrorCode = 0
Begin
	If @pnCaseKey is not null
	Begin
		Select @bIsCRMCaseType = isnull(CT.CRMONLY,0)
		from CASES C
		join CASETYPE CT ON (CT.CASETYPE = C.CASETYPE)
		where C.CASEID = @pnCaseKey

		Set @nErrorCode=@@ERROR
	End
	Else if (@psNewCaseTypeCode is not null)
	Begin
		Select @bIsCRMCaseType = isnull(CRMONLY,0)
		from CASETYPE 
		WHERE CASETYPE = @psNewCaseTypeCode

		Set @nErrorCode=@@ERROR
	End
End

If @nErrorCode = 0
Begin
	Select @sProgramKey = left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8),
	       @nProfileKey = U.PROFILEID 
	from  SITECONTROL S
	join USERIDENTITY U             on (U.IDENTITYID= @pnUserIdentityId)
	left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
					and PA.ATTRIBUTEID=2)	-- Default Cases Program
	where S.CONTROLID = CASE WHEN @bIsCRMCaseType=1 THEN 'CRM Screen Control Program'
						        ELSE 'Case Screen Default Program' 
			    END

	Set @nErrorCode=@@ERROR
End

-- For existing case get the screen criteria no
If @nErrorCode = 0
and @pnCaseKey is not null
Begin
    Set @nScreenCriteriaKey = dbo.fn_GetCaseScreenCriteriaKey(@pnCaseKey, 'W', @sProgramKey, @nProfileKey)
End

-- For a new case, locate the screen control criteria rule
If @nErrorCode = 0
and @pnCaseKey is null
and isnull(@pbAllRows, 0) = 0
Begin

	Set @nErrorCode=@@ERROR

	If @nErrorCode = 0
	Begin
		Select top 1 @nNewCaseCriteriaNo=CRITERIANO
		from dbo.fn_GetCriteriaRows ( 'W',NULL,@psNewCaseTypeCode,NULL,NULL,@sProgramKey,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,null,1,1,1,1,1,NULL,NULL,NULL,NULL,
						null,		-- @pnRuleType		--SQA12298
						null,		-- @psRequestType	--SQA12298
						null,		-- @pnDataSourceType	--SQA12298
						null,		-- @pnDataSourceNameNo	--SQA12298
						null,		-- @pnRenewalStatus	--SQA12298
						null,		-- @pnStatusCode	--SQA12298,
						0,
						null            -- @pnProfileKey
						)
		order by BESTFIT desc

		Set @nErrorCode=@@ERROR

	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select
	NT.NAMETYPE	as NameTypeCode,
	"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+"	
			as NameTypeDescription,"+
	-- For an existing case, IsMandatory comes from NAMETYPE
	CASE	WHEN @pnCaseKey is not null or @pbAllRows = 1
		THEN "
	CASE	WHEN NT.MANDATORYFLAG =1
		THEN CAST(1 as bit) 
		ELSE CAST(0 as bit)
	END		as IsMandatory,"
	-- For a new case, IsMandatory comes from field control
		ELSE "
	cast(isnull(FC.IsMandatory,0) as bit)
			as IsMandatory,"
	END+char(10)+"
	NT.MAXIMUMALLOWED 	
			as MaximumOccurrence,
	CASE	WHEN NT.COLUMNFLAGS&64=64 
		THEN CAST(1 as bit) 
		ELSE CAST(0 as bit)
	END		as HasBillPercent,
	NT.KEEPSTREETFLAG
			as IsStreetAddressSaved,
	NT.PATHNAMETYPE
			as DefaultFromNameTypeCode,
	NT.PATHRELATIONSHIP
			as DefaultFromRelationshipCode,
	NT.HIERARCHYFLAG
			as UseHierarchy,
	NT.UPDATEFROMPARENT
			as IsUpdatedFromParent,
	NT.FUTURENAMETYPE
			as FutureNameTypeCode,
	"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT2',@sLookupCulture,@pbCalledFromCentura)+"	
			as FutureNameTypeDescription,
	CASE WHEN NT.PICKLISTFLAGS & 16 = 16 THEN CAST(1 as bit) ELSE CAST(0 as bit) END as IsRestrictToSameNameTypes, 
	CASE WHEN NT.PICKLISTFLAGS & 32 = 32 THEN CAST(1 as bit) ELSE CAST(0 as bit) END as IsCRMOnly 	
	from NAMETYPE NT
	left join NAMETYPE NT2 on (NT2.NAMETYPE = NT.FUTURENAMETYPE)"+
	CASE
		WHEN @pbAllRows = 1	THEN char(10) /* no filter */
		WHEN @pnCaseKey is not null 
		-- Only contains those name types currently implemented by WorkBenches
		THEN char(10)+"join ( select NAMETYPEKEY from dbo.fnw_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, default)
		                        UNION Select NAMETYPE AS NAMETYPEKEY from dbo.fnw_FilteredTopicNameTypes(@nScreenCriteriaKey,0) ) S on (S.NameTypeKey = NT.NAMETYPE) where isnull(NT.BULKENTRYFLAG,0) = 0"
		-- Only the name types hard coded on the New Cases Dialog 
		-- will be returned (Instructor, Owner, Staff)
		ELSE char(10)+"left join (
			Select case EC.ELEMENTNAME
				when 'pkInstructorName'	then 'I'
				when 'pkOwnerName'		then 'O'
				when 'pkStaffName'		then 'EMP'
			end				as NameType,
			EC.ISMANDATORY	as IsMandatory
			from 	WINDOWCONTROL WC
			join	TOPICCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO and TC.TOPICNAME='Case_NamesTopic' and TC.TOPICSUFFIX is NULL)
			join	ELEMENTCONTROL EC on (EC.TOPICCONTROLNO = TC.TOPICCONTROLNO
						and EC.ELEMENTNAME in ('pkInstructorName', 'pkOwnerName', 'pkStaffName'))
			where 	WC.WINDOWNAME = 'NewCaseForm'
			and	WC.CRITERIANO = @nNewCaseCriteriaNo
					) FC on (FC.NameType=NT.NAMETYPE)
		where NT.NAMETYPE in (N'I', N'O', N'EMP')"
	END+char(10)+	
	"order by NameTypeCode"

	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@pnUserIdentityId	int,
					@pnCaseKey		int,
					@nNewCaseCriteriaNo	int,
					@sProgramKey		nvarchar(8),
					@nScreenCriteriaKey     int',
					@pnUserIdentityId	= @pnUserIdentityId,
					@pnCaseKey		= @pnCaseKey,
					@nNewCaseCriteriaNo	= @nNewCaseCriteriaNo,
					@sProgramKey		= @sProgramKey,
					@nScreenCriteriaKey     = @nScreenCriteriaKey
					

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListNameTypeMetaData  to public
GO