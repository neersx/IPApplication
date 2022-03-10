---------------------------------------------------------------------------------------------
-- Creation of dbo.mk_ListContactActivityData
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_ListContactActivityData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_ListContactActivityData.'
	drop procedure [dbo].[mk_ListContactActivityData]
	Print '**** Creating Stored Procedure dbo.mk_ListContactActivityData...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.mk_ListContactActivityData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnActivityKey		int		= null,	-- The key of an existing activity to be returned.  
--							   Either an ActivityKey, or the subsequent parameters 
--							   should be provided.
	@pnActivityTypeKey	int		= null,	-- The type of default activity to prepare.  
	@pbIsOutgoing		bit		= null,	-- The direction of the default activity.  
	@pnForNameKey		int		= null,	-- The key of the name for which a default activity record is to be prepared.  
	@pnForCaseKey		int		= null,	-- The key of the case for which a default activity record is to be prepared. 
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	mk_ListContactActivityData
-- VERSION:	16
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Activity Types.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10 Feb 2005  TM	RFC1743	1	Procedure created
-- 16 Feb 2005	TM	RFC1743	2	When an @pnActivityKey is supplied, @pnActivityTypeKey and @pbIsOutgoing should
--					not be used. Correct the IsOrganisation flag logic.
-- 02 Mar 2005	TM	RFC2398	3	Return the C.IRN as the CaseReference column and the CN.REFERENCENO as the 
--					ReferenceNo column when the CaseKey is supplied. 
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 24 May 2006	SW	RFC2985	5	Add ClientReference, modify defaulting for internal/external users,
--					restructure the SQL statment for defaulting
-- 14 Jul 2006	SW	RFC3828	6	Pass getdate() to fn_Permission..
-- 15 Oct 2007	SF	RFC5429	7	Also part of RFC5053 - add RowKey
-- 18 Sep 2008  LP      RFC7038 8       Do not return Regarding Name if Individual has multiple Employers.
-- 11 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 26 Nov 2010	SF	RFC9304	10	Filter Min SEQUENCENO by ACTIVITYNO
-- 10 Oct 2014	DV	R26412	11	Return LogDateTimeStamp field
-- 15 Dec 2014	MS	R38952	12	Added check for individual if not available as contact
-- 19 May 2015	DV	R47600	13	Remove check for WorkBench Attachments site control 
-- 27 May 2015  MS      R47576  14       Increased size of @sSummary from 100 to 254
-- 02 Nov 2015	vql	R53910	15	Adjust formatted names logic (DR-15543).
-- 13 Jul 2018	DV	R74078	16  Only return client request for external users.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(4000)
Declare @sSQLStringDoc		nvarchar(4000)
Declare @sSelect		nvarchar(4000)
Declare @sFrom			nvarchar(4000)
Declare @sWhere			nvarchar(4000)

Declare @bIsExternalUser	bit
Declare @bIsIndividual		bit
Declare @bIsOrganisation	bit
Declare @bIsStaff		bit
Declare @bIsIndividualInstructor bit
Declare @bIsAvailableAsContact bit

Declare @sCaseReference		nvarchar(30)
Declare @sSummary		nvarchar(254)

Declare @nDocItemKey		int

Declare @sSegment1		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

Set	@nErrorCode      	= 0
Set     @bIsIndividualInstructor= 0

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

Declare @nUserAccountKey int
If (@bIsExternalUser = 1)
Begin
Set @sSQLString = '
			Select 	@nUserAccountKey = ACCOUNTID
			from	USERIDENTITY
			where	IDENTITYID = @pnUserIdentityId'
	
		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@nUserAccountKey	int			OUTPUT,
					  @pnUserIdentityId	int',
					  @nUserAccountKey	= @nUserAccountKey	OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
End

If  @nErrorCode = 0
and @pnActivityKey is not null
Begin	
	Set @sSQLString = "
	Select  A.ACTIVITYNO	as 'ActivityKey',
		A.ACTIVITYNO	as 'RowKey',
		A.NAMENO	as 'ContactKey',
		dbo.fn_FormatNameUsingNameNo(NC2.NAMENO, null)
				as 'ContactName',
		NC2.NAMECODE	as 'ContactCode',
		"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
			     +" as 'ContactRestriction',		 
		DS.ACTIONFLAG	as 'ContactRestrictionActionKey',
		A.ACTIVITYDATE	as 'ActivityDate',
		A.EMPLOYEENO	as 'StaffKey',
		dbo.fn_FormatNameUsingNameNo(NC5.NAMENO, null)
				as 'StaffName',		
		NC5.NAMECODE	as 'StaffCode',
		A.CALLER	as 'CallerKey',
		dbo.fn_FormatNameUsingNameNo(NC1.NAMENO, null)
				as 'CallerName',
		NC1.NAMECODE	as 'CallerCode',
		A.RELATEDNAME	as 'RegardingKey',
		dbo.fn_FormatNameUsingNameNo(NC4.NAMENO, null)
				as 'RegardingName',
		NC4.NAMECODE	as 'RegardingCode',
		"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS4',@sLookupCulture,@pbCalledFromCentura)
			    + " as 'RegardingRestriction',		 
		DS4.ACTIONFLAG	as 'RegardingRestrictionActionKey',
		A.CASEID	as 'CaseKey',
		C.IRN		as 'CaseReference',
		A.REFERREDTO	as 'ReferredToKey',
		dbo.fn_FormatNameUsingNameNo(NC3.NAMENO, null)
				as 'ReferredToName',
		NC3.NAMECODE	as 'ReferredToCode',		
		cast(A.INCOMPLETE as bit)
				as 'IsIncomplete',
		A.SUMMARY	as 'Summary',
		CASE WHEN A.CALLTYPE is not null THEN cast(A.CALLTYPE as bit) ELSE NULL END
				as 'IsOutgoing',
		A.CALLSTATUS	as 'CallStatusCode',
		A.ACTIVITYCATEGORY	
				as 'ActivityCategoryKey',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',@sLookupCulture,@pbCalledFromCentura)	
			     +" as 'ActivityCategory',		
		A.ACTIVITYTYPE	as 'ActivityTypeKey',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCT',@sLookupCulture,@pbCalledFromCentura)
			     +" as 'ActivityType',
		A.REFERENCENO	as 'ReferenceNo',
		CASE 	WHEN A.LONGFLAG = 1 
			THEN A.LONGNOTES
			ELSE A.NOTES
		END		as 'Notes',	
		-- Only display attachments information if the Attachments topic available 
		CASE 	WHEN TS.IsAvailable = 1
			THEN ATCH.AttachmentCount
			ELSE NULL
		END		as 'AttachmentCount',		
		CASE 	WHEN TS.IsAvailable = 1
			THEN AA.FILENAME	
			ELSE NULL
		END 		as 'FirstAttachmentFilePath',
		A.CLIENTREFERENCE as 'ClientReference',
		A.LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from ACTIVITY A
	-- Contact data
	left join NAME NC2		on (NC2.NAMENO = A.NAMENO)
	left join IPNAME IP		on (IP.NAMENO = NC2.NAMENO)
	left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)
	-- Staff data
	left join NAME NC5 		on (NC5.NAMENO = A.EMPLOYEENO)
	-- Caller data
	left join NAME NC1 		on (NC1.NAMENO = A.CALLER)
	-- Regarding data
	left join NAME NC4 		on (NC4.NAMENO = A.RELATEDNAME)
	left join IPNAME IP4		on (IP4.NAMENO = NC2.NAMENO)
	left join DEBTORSTATUS DS4	on (DS4.BADDEBTOR = IP4.BADDEBTOR)
	-- Case data
	left join CASES C		on (C.CASEID = A.CASEID)
	-- Reffered To data
	left join NAME NC3 		on (NC3.NAMENO = A.REFERREDTO)
	-- Activity Category
	left join TABLECODES TCC	on (TCC.TABLECODE = A.ACTIVITYCATEGORY)
	-- Activity Type
	left join TABLECODES TCT	on (TCT.TABLECODE = A.ACTIVITYTYPE)
	-- AttachmentCount
	left join (Select ACT.ACTIVITYNO, count(*) as AttachmentCount
 		   from ACTIVITYATTACHMENT ACT		   
  		   group by ACT.ACTIVITYNO) ATCH 	
					on (ATCH.ACTIVITYNO = A.ACTIVITYNO) 
	left join ACTIVITYATTACHMENT AA on (AA.ACTIVITYNO = A.ACTIVITYNO
					and AA.SEQUENCENO = (Select min(AA2.SEQUENCENO)
				  		             from ACTIVITYATTACHMENT AA2
				  		             where AA2.ACTIVITYNO = A.ACTIVITYNO)) 
	-- Is Attachments topic available?
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 2, @pbCalledFromCentura, @dtToday) TS
					on (TS.IsAvailable=1)
	where A.ACTIVITYNO = @pnActivityKey and (@bIsExternalUser = 0 or A.ACTIVITYTYPE = 5808)"

	if(@bIsExternalUser = 1)
	Begin
	Set @sSQLString = @sSQLString + char(10) + "and exists (select	2"
		                      + char(10) + "            from	USERIDENTITY UI"
		                      + char(10) + "            where	UI.ACCOUNTID = " + cast(@nUserAccountKey as varchar(50))
		                      + char(10) + "            and	UI.NAMENO = A.NAMENO)"
	End


	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnActivityKey	int,
			  @pnUserIdentityId	int,
			  @pbCalledFromCentura	bit,
			  @dtToday		datetime,
			  @bIsExternalUser bit',
			  @pnActivityKey	= @pnActivityKey,
			  @pnUserIdentityId	= @pnUserIdentityId,
			  @pbCalledFromCentura	= @pbCalledFromCentura,
			  @dtToday		= @dtToday,
			  @bIsExternalUser = @bIsExternalUser
End
Else
If  @nErrorCode = 0
and @pnActivityKey is null
Begin	

	-- Extract flags if @pnForNameKey available
	If  @nErrorCode = 0
	and @pnForNameKey is not null
	Begin
		Set @sSQLString = "
			Select  @bIsStaff	= CASE WHEN N.USEDASFLAG&2 = 2 THEN 1 ELSE 0 END,
				@bIsIndividual	= CASE WHEN N.USEDASFLAG&1 = 1 THEN 1 ELSE 0 END,
				@bIsOrganisation= CASE WHEN N.USEDASFLAG&1 = 0 THEN 1 ELSE 0 END,
				@bIsAvailableAsContact = ISNULL(NTC.ALLOW,0)
			from NAME N	
			left join NAMETYPECLASSIFICATION NTC ON (NTC.NAMENO=N.NAMENO and NTC.NAMETYPE = '~CN')	
			where N.NAMENO = @pnForNameKey"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@bIsStaff			bit		OUTPUT,
							  @bIsIndividual		bit		OUTPUT,
							  @bIsOrganisation		bit		OUTPUT,
							  @bIsAvailableAsContact	bit		OUTPUT,
							  @pnForNameKey			int',			 
							  @bIsStaff			= @bIsStaff	OUTPUT,
							  @bIsIndividual		= @bIsIndividual OUTPUT,
							  @bIsOrganisation		= @bIsOrganisation OUTPUT,
							  @bIsAvailableAsContact	= @bIsAvailableAsContact OUTPUT,
							  @pnForNameKey			= @pnForNameKey
	End

	-- When @bIsIndividual = 1, check if is individual instructor?
	If  @nErrorCode = 0
	and @bIsIndividual = 1
	Begin
		Set @sSQLString = "
		Select  @bIsIndividualInstructor = 1
		from CASENAME CN	
		where CN.NAMENO = @pnForNameKey
		and   CN.NAMETYPE = 'I'
		and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@bIsIndividualInstructor	bit			   OUTPUT,
				  @pnForNameKey			int',
				  @bIsIndividualInstructor	= @bIsIndividualInstructor OUTPUT,
				  @pnForNameKey			= @pnForNameKey	
	End

	-- Extract @sSummary if @pnForCaseKey available and Activity Type = Client Request Activity Type
	If  @nErrorCode = 0
	and @pnForCaseKey is not null
	and @pnActivityTypeKey = 5808
	Begin
		-- Work out @nDocItemKey
		Set @sSQLStringDoc = "
			Select	@nDocItemKey  	= I.ITEM_ID
			from	ITEM I
			join 	SITECONTROL SC on (SC.CONTROLID = 'Client Request Case Summary')
			Where	I.ITEM_NAME = SC.COLCHARACTER"
	
		exec @nErrorCode=sp_executesql @sSQLStringDoc,
					N'@nDocItemKey		int		OUTPUT',
					  @nDocItemKey		= @nDocItemKey	OUTPUT

		If @nDocItemKey is not null
		Begin
			-- Work out @sCaseReference
			If @nErrorCode = 0
			Begin
				Set @sSQLStringDoc = "
					Select	@sCaseReference	= dbo.fn_WrapQuotes(C.IRN,0,0)
					from	CASES C
					Where	C.CASEID = @pnForCaseKey"
	
				exec @nErrorCode=sp_executesql @sSQLStringDoc,
							N'@sCaseReference		nvarchar(30)		OUTPUT,
							  @pnForCaseKey			int',
							  @sCaseReference		= @sCaseReference	OUTPUT,
							  @pnForCaseKey			= @pnForCaseKey
			End
			
			If @nErrorCode = 0 
			Begin
				exec @nErrorCode = dbo.pt_GetDocItemSql
						@psSegment1		= @sSegment1	output,
						@pnUserIdentityId	= @pnUserIdentityId,				
						@pnDocItemKey		= @nDocItemKey, 		
						@psSearchText1		= ':gstrEntryPoint',
						@psReplacementText1	= @sCaseReference
			End

			If @nErrorCode = 0 
			Begin
				-- strip off leading word 'select' (leading 6 chars)
				-- and add 'Select variablename =' to @sSegment1 to assign results to local variable
				Set @sSegment1 = 'Select @sSummary = ' + right(@sSegment1, len(@sSegment1) - 6) 

				-- Execute the DocItem SQL:
				exec @nErrorCode=sp_executesql @sSegment1,
						N'@sSummary		nvarchar(254)	OUTPUT',
						  @sSummary		= @sSummary	OUTPUT
			End
		End
	End

	-- 2985 Assemble segments of select statement for default values
	If @nErrorCode = 0
	Begin	
		-- Initialize @sSelect with ActivityKey setting
		-- ActivityKey
		Set @sSelect = "Select	-1			as 'ActivityKey'," + char(10) +
				"	-1			as 'RowKey'," + char(10) +
				"	null			as 'LogDateTimeStamp'," + char(10)
	
		-- Contact... columns
		Set @sSelect = @sSelect +
			CASE	WHEN (@bIsStaff = 1)
				THEN	"	null			as 'ContactKey'," + char(10) +
					"	null			as 'ContactName'," + char(10) +
					"	null			as 'ContactCode'," + char(10) +
					"	null			as 'ContactRestriction'," + char(10) +	 
					"	null			as 'ContactRestrictionActionKey'," + char(10)

				WHEN (@bIsIndividual = 1) and (@bIsAvailableAsContact=1)
				THEN	"	@pnForNameKey		as 'ContactKey'," + char(10) +
					"	dbo.fn_FormatNameUsingNameNo(NC.NAMENO, null)" + char(10) +
					"				as 'ContactName'," + char(10) +
					"	NC.NAMECODE		as 'ContactCode'," + char(10) +
					" 	" + dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura) + char(10) +
					"				as 'ContactRestriction'," + char(10) +	 
					"	DS.ACTIONFLAG		as 'ContactRestrictionActionKey'," + char(10)
	
				WHEN (@bIsOrganisation = 1
				or    @pnForCaseKey is not null)
				THEN	"	NC.NAMENO		as 'ContactKey'," + char(10) +
					"	dbo.fn_FormatNameUsingNameNo(NC.NAMENO, null)" + char(10) +
					"				as 'ContactName'," + char(10) +
					"	NC.NAMECODE		as 'ContactCode'," + char(10) +
					" 	" + dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura) + char(10) +
					"				as 'ContactRestriction'," + char(10) +	 
					"	DS.ACTIONFLAG		as 'ContactRestrictionActionKey'," + char(10)

				WHEN (@pnForNameKey is null and @pnForCaseKey is null and @bIsExternalUser = 1)
				THEN	"	NU.NAMENO		as 'ContactKey'," + char(10) +
					"	dbo.fn_FormatNameUsingNameNo(NU.NAMENO, null)" + char(10) +
					"				as 'ContactName'," + char(10) +
					"	NU.NAMECODE		as 'ContactCode'," + char(10) +
					" 	" + dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura) + char(10) +
					"				as 'ContactRestriction'," + char(10) +	 
					"	DS.ACTIONFLAG		as 'ContactRestrictionActionKey'," + char(10)
				
				ELSE	"	null			as 'ContactKey'," + char(10) +
					"	null			as 'ContactName'," + char(10) +
					"	null			as 'ContactCode'," + char(10) +
					"	null			as 'ContactRestriction'," + char(10) +	 
					"	null			as 'ContactRestrictionActionKey'," + char(10)
			END + char(10)
	
		-- ActivityDate
		Set @sSelect = @sSelect +
			"	null			as 'ActivityDate'," + char(10)
	
		-- Staff... column
		Set @sSelect = @sSelect +
			CASE	WHEN (@bIsExternalUser = 0)
				THEN	"	UI.NAMENO		as 'StaffKey'," + char(10) +
					"	dbo.fn_FormatNameUsingNameNo(NU.NAMENO, null)" + char(10) +
					"			 	as 'StaffName'," + char(10) +
					"	NU.NAMECODE 		as 'StaffCode'," + char(10)

				ELSE 	"	null			as 'StaffKey'," + char(10) +
					"	null			as 'StaffName'," + char(10) +
					"	null			as 'StaffCode'," + char(10)	
			END + char(10)
	
		-- Caller... column
		Set @sSelect = @sSelect +
			CASE	WHEN (@pbIsOutgoing = 1)
				THEN	"	UI.NAMENO		as 'CallerKey'," + char(10)+
					"	dbo.fn_FormatNameUsingNameNo(NU.NAMENO, null)" + char(10) +
					"			 	as 'CallerName'," + char(10)+
					"	NU.NAMECODE		as 'CallerCode'," + char(10)	

				ELSE	"	null			as 'CallerKey'," + char(10)+
					"	null			as 'CallerName'," + char(10)+
					"	null			as 'CallerCode'," + char(10)
			END + char(10)
	
		-- Regarding... column
		Set @sSelect = @sSelect +
			CASE	WHEN (@bIsStaff = 1)
				THEN	"	null			as 'RegardingKey'," +char(10)+
					"	null			as 'RegardingName'," +char(10)+
					"	null			as 'RegardingCode'," +char(10)+
					"	null			as 'RegardingRestriction'," +char(10)+	 
					"	null			as 'RegardingRestrictionActionKey'," +char(10)

				WHEN (@bIsIndividual = 1)
				THEN 	"	ISNULL(ORG.NAMENO, CASE 	WHEN @bIsIndividualInstructor = 1" + char(10)+
					"					THEN @pnForNameKey" + char(10)+
					"					ELSE NULL" + char(10)+
					"			    END)" + char(10)+
					"				as 'RegardingKey'," + char(10)+
					"	ISNULL(dbo.fn_FormatNameUsingNameNo(ORG.NAMENO, null)," + char(10)+
					"	       CASE 	WHEN @bIsIndividualInstructor = 1 " + char(10)+
					"			THEN dbo.fn_FormatNameUsingNameNo(NC.NAMENO, null)" + char(10)+
					"			ELSE NULL" + char(10)+
					"	       END) 		as 'RegardingName'," + char(10)+
					"	ISNULL(ORG.NAMECODE, " + char(10)+
					"  	     CASE	WHEN @bIsIndividualInstructor = 1 " + char(10)+
					"			THEN NC.NAMECODE" + char(10)+
					"			ELSE NULL" + char(10)+
					"	       END)		as 'RegardingCode'," + char(10)+
					"	ISNULL("+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DSO',@sLookupCulture,@pbCalledFromCentura)+"," + char(10)+
					"		CASE	WHEN @bIsIndividualInstructor = 1 " + char(10)+
					"			THEN "+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura) + char(10)+
					"			ELSE NULL" + char(10)+
					"		END)   		as 'RegardingRestriction'," + char(10)+ 
					"	ISNULL(DSO.ACTIONFLAG, CASE	WHEN @bIsIndividualInstructor = 1" + char(10)+
					"					THEN DS.ACTIONFLAG" + char(10)+
					"					ELSE NULL" + char(10)+
					"				END) as 'RegardingRestrictionActionKey'," + char(10)

				WHEN (@bIsOrganisation = 1)
				THEN 	"	N.NAMENO		as 'RegardingKey'," + char(10)+
					"	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)" + char(10)+
					"				as 'RegardingName'," + char(10)+
					"	N.NAMECODE		as 'RegardingCode'," + char(10)+
					" 	" + dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DSO',@sLookupCulture,@pbCalledFromCentura) + char(10)+
					"		     		as 'RegardingRestriction'," + char(10)+
					"	DSO.ACTIONFLAG		as 'RegardingRestrictionActionKey'," + char(10)

				WHEN (@pnForCaseKey is not null)
				THEN	"	NI.NAMENO		as 'RegardingKey'," + char(10)+
					"	dbo.fn_FormatNameUsingNameNo(NI.NAMENO, null)" + char(10)+
					"				as 'RegardingName'," + char(10)+
					"	NI.NAMECODE		as 'RegardingCode'," + char(10)+
					"	"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DSO',@sLookupCulture,@pbCalledFromCentura) + char(10)+
					"	      as 'RegardingRestriction'," + char(10)+	 
					"	DSO.ACTIONFLAG		as 'RegardingRestrictionActionKey'," + char(10)

				WHEN (@pnForNameKey is null and @pnForCaseKey is null and @bIsExternalUser = 1)
				THEN 	"	ORG.NAMENO		as 'RegardingKey'," + char(10)+
					"	dbo.fn_FormatNameUsingNameNo(ORG.NAMENO, null)" + char(10)+
					"				as 'RegardingName'," + char(10)+
					"	ORG.NAMECODE		as 'RegardingCode'," + char(10)+
					" 	" + dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DSO',@sLookupCulture,@pbCalledFromCentura) + char(10)+
					"		     		as 'RegardingRestriction'," + char(10)+
					"	DSO.ACTIONFLAG		as 'RegardingRestrictionActionKey'," + char(10)

				ELSE	"	null			as 'RegardingKey'," +char(10)+
					"	null			as 'RegardingName'," +char(10)+
					"	null			as 'RegardingCode'," +char(10)+
					"	null			as 'RegardingRestriction'," +char(10)+	 
					"	null			as 'RegardingRestrictionActionKey'," +char(10)
			END + char(10)
	
		-- Case... columns
		Set @sSelect = @sSelect +
			CASE	WHEN (@pnForCaseKey is not null)
				THEN	"	C.CASEID		as 'CaseKey'," +char(10)+
					"	C.IRN			as 'CaseReference'," +char(10)

				ELSE	"	null			as 'CaseKey'," +char(10)+
					"	null			as 'CaseReference'," +char(10)
			END + char(10)

		-- Referred... columns, IsIncomplete, Summary, IsOutgoing, CallStatusCode
		Set @sSelect = @sSelect +
			"	null			as 'ReferredToKey'," +char(10)+
			"	null			as 'ReferredToName'," +char(10)+
			"	null			as 'ReferredToCode'," +char(10)+
			"	null			as 'IsIncomplete'," +char(10)+
			"	@sSummary		as 'Summary'," +char(10)+
			"	@pbIsOutgoing		as 'IsOutgoing'," +char(10)+
			"	null			as 'CallStatusCode'," +char(10)

		-- Activity... columns
		Set @sSelect = @sSelect +
			"	null			as 'ActivityCategoryKey'," +char(10)+
			"	null			as 'ActivityCategory',"+char(10)+
			"	@pnActivityTypeKey	as 'ActivityTypeKey',"+char(10)+
			"	" + dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCT',@sLookupCulture,@pbCalledFromCentura)+char(10)+
			"				as 'ActivityType',"+char(10)

		-- ReferenceNo, Notes, AttachmentCount, FirstAttachmentFilePath, ClientReference
		Set @sSelect = @sSelect +
			CASE	WHEN (@bIsExternalUser = 0 and @pnForCaseKey is not null)
				-- The instructor reference for @pnForCaseKey.
				THEN "	CN.REFERENCENO		as 'ReferenceNo',"
				ELSE "	NULL			as 'ReferenceNo',"
			End + char(10) +
			"	null			as 'Notes',"+char(10)+
			"	null			as 'AttachmentCount',"+char(10)+
			"	null			as 'FirstAttachmentFilePath',"+char(10)+
			"	null			as 'ClientReference'"+char(10)

		-- Initialize @sFrom and @sWhere with USERIDENTITY
		Set @sFrom = "
			from USERIDENTITY UI	
			join [NAME] NU			on (NU.NAMENO = UI.NAMENO)
			left join TABLECODES TCT	on (TCT.TABLECODE = @pnActivityTypeKey)" + char(10)

		Set @sWhere = "
			where UI.IDENTITYID = " + str(@pnUserIdentityId)

		Set @sFrom = @sFrom +
			CASE 	WHEN	(@bIsStaff = 1)
				THEN	""

				WHEN	(@bIsIndividual = 1)
				THEN	"
					left join NAME NC		on (NC.NAMENO = @pnForNameKey)
					left join IPNAME IP		on (IP.NAMENO = NC.NAMENO)
					left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)
					-- Organisation for the employed by relationship on AssociatedName.
					left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = NC.NAMENO
									and EMP.RELATIONSHIP = 'EMP'
									and EMP.RELATEDNAME not in (SELECT RELATEDNAME as RELATEDNAMENO
					                                                                FROM ASSOCIATEDNAME
					                                                                WHERE RELATIONSHIP = 'EMP'
					                                                                and RELATEDNAME = NC.NAMENO
					                                                                GROUP BY RELATEDNAME
					                                                                HAVING COUNT (*) > 1)) 
					left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)			 
					left join IPNAME IPO		on (IPO.NAMENO = ORG.NAMENO)
					left join DEBTORSTATUS DSO	on (DSO.BADDEBTOR = IPO.BADDEBTOR)"

				WHEN	(@bIsOrganisation = 1)
				THEN	"
					left join NAME N 		on (N.NAMENO = @pnForNameKey)
					left join NAME NC		on (NC.NAMENO = N.MAINCONTACT)
					left join IPNAME IP		on (IP.NAMENO = NC.NAMENO)
					left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)
					left join IPNAME IPO		on (IPO.NAMENO = N.NAMENO)
					left join DEBTORSTATUS DSO	on (DSO.BADDEBTOR = IPO.BADDEBTOR)"

				WHEN	(@pnForCaseKey is not null)
				THEN	"
					left join CASES C		on (C.CASEID = @pnForCaseKey)
					left join CASENAME CN		on (CN.CASEID = C.CASEID
									and CN.NAMETYPE = 'I'
									and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))							
					left join NAME NI		on (NI.NAMENO = CN.NAMENO)" + char(10) +
			
					-- For internal user, join on instructor, for external join on UI.NAMENO as a contact
					CASE	WHEN @bIsExternalUser = 0
						THEN "					left join NAME NC		on (NC.NAMENO = ISNULL(CN.CORRESPONDNAME, NI.MAINCONTACT))"
						ELSE "					left join NAME NC		on (NC.NAMENO = UI.NAMENO)"
					END + char(10) + "
			
					left join IPNAME IP		on (IP.NAMENO = NC.NAMENO)
					left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)
					left join IPNAME IPO		on (IPO.NAMENO = NI.NAMENO)
					left join DEBTORSTATUS DSO	on (DSO.BADDEBTOR = IPO.BADDEBTOR)"

				
				WHEN	(@pnForNameKey is null and @pnForCaseKey is null and @bIsExternalUser = 0)
				THEN	"
					left join [NAME] NC		on (NC.NAMENO = NU.MAINCONTACT)
					left join IPNAME IP		on (IP.NAMENO = NC.NAMENO)
					left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)
					left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = NC.NAMENO
									and EMP.RELATIONSHIP = 'EMP'
									and EMP.RELATEDNAME not in (SELECT RELATEDNAME as RELATEDNAMENO
					                                                                FROM ASSOCIATEDNAME
					                                                                WHERE RELATIONSHIP = 'EMP'
					                                                                and RELATEDNAME = NC.NAMENO
					                                                                GROUP BY RELATEDNAME
					                                                                HAVING COUNT (*) > 1)) 
					-- Employing organization of ContactKey
					left join [NAME] ORG		on (ORG.NAMENO = EMP.NAMENO)	
					left join IPNAME IPO		on (IPO.NAMENO = EMP.NAMENO)
					left join DEBTORSTATUS DSO	on (DSO.BADDEBTOR = IPO.BADDEBTOR)"

				-- For external user, current user is the contact of itself
				WHEN	(@pnForNameKey is null and @pnForCaseKey is null and @bIsExternalUser = 1)
				THEN	"
					left join IPNAME IP		on (IP.NAMENO = NU.NAMENO)
					left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)
					left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = NU.NAMENO
									and EMP.RELATIONSHIP = 'EMP'
									and EMP.RELATEDNAME not in (SELECT RELATEDNAME as RELATEDNAMENO
					                                                                FROM ASSOCIATEDNAME
					                                                                WHERE RELATIONSHIP = 'EMP'
					                                                                and RELATEDNAME = NC.NAMENO
					                                                                GROUP BY RELATEDNAME
					                                                                HAVING COUNT (*) > 1))  
					-- Employing organization of ContactKey
					left join [NAME] ORG		on (ORG.NAMENO = EMP.NAMENO)	
					left join IPNAME IPO		on (IPO.NAMENO = EMP.NAMENO)
					left join DEBTORSTATUS DSO	on (DSO.BADDEBTOR = IPO.BADDEBTOR)"
			End

		Set @sSQLString = @sSelect + @sFrom + @sWhere
                
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnForCaseKey			int,
				  @pnForNameKey			int,
				  @pnActivityTypeKey		int,
				  @sSummary			nvarchar(254),
				  @pbIsOutgoing			bit,
				  @bIsIndividualInstructor 	bit',
				  @pnForCaseKey			= @pnForCaseKey,
				  @pnForNameKey			= @pnForNameKey,
				  @pnActivityTypeKey		= @pnActivityTypeKey,
				  @sSummary			= @sSummary,
				  @pbIsOutgoing			= @pbIsOutgoing,
				  @bIsIndividualInstructor	= @bIsIndividualInstructor
	End

End

Return @nErrorCode
GO

Grant exec on dbo.mk_ListContactActivityData to public
GO
