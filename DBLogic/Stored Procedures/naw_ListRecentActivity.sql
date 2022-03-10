-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListRecentActivity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListRecentActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListRecentActivity.'
	Drop procedure [dbo].[naw_ListRecentActivity]
	Print '**** Creating Stored Procedure dbo.naw_ListRecentActivity...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListRecentActivity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int		= null,
	@pnOrganisationKey	int		= null,
	@pnCaseKey			int		= null,
	@pnTopRowCount		int		= null,
	@pbCalledFromCentura	bit		= 0,
	@psResultsetsRequired	nvarchar(200)	= null		-- comma seperated list to describe which resultset to return
)
AS
-- PROCEDURE:	naw_ListRecentActivity
-- VERSION:	7
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the RecentActivityTotal and RecentActivity data tables.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Dec 2004  TM	RFC2048	1	Procedure created
-- 16 Dec 2004	TM	RFC2048	2	In the RecentActivity result set Summary sort order to 2.
-- 07 Jul 2005	TM	RFC2654	3	Extract the required data directly from the naw_ListRecentActivity 
--					using sp_executesqlinstead of calling the mk_ListContactActivity.
-- 17 Jul 2006	SW	RFC3828	4	Pass getdate() to fn_Permission..
-- 25 Aug 2006	SF	RFC4214	5	Add RowKey, Add ResultsetRequired parameter.
-- 02 Nov 2015	vql	R53910	6	Adjust formatted names logic (DR-15543).
-- 17 Aug 2018	DV R74350	7	Return Contact activity details for non Crm cases

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(4000)
Declare @bHasAccess		bit
Declare @dtToday		datetime

set	@dtToday	 = getdate()
Set	@nErrorCode      = 0

-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
Set	@psResultsetsRequired = upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','

-- Check if the user has access to the Contact Activity information security subject:
If @nErrorCode = 0
Begin
	-- Is the Contact Activity topic available?
	Set @sSQLString = "
	select @bHasAccess = IsAvailable
	from	dbo.fn_GetTopicSecurity(@pnUserIdentityId, 400, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @bHasAccess		bit		OUTPUT,
					  @dtToday		datetime',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @bHasAccess		= @bHasAccess	OUTPUT,
					  @dtToday		= @dtToday

End

-- Populate the RecentActivityTotal result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('RECENTACTIVITYTOTAL,', @psResultsetsRequired) <> 0)
Begin
	If @bHasAccess = 1
	Begin	
		Set @sSQLString = "
			Select count(*) as [TotalRows],
				'1' as [RowKey]
			from ACTIVITY A
			where ((@pnCaseKey is not null and A.CASEID = @pnCaseKey) 
			or (@pnCaseKey is null and (A.NAMENO = @pnNameKey
			or  A.RELATEDNAME = @pnNameKey"+char(10)+
			CASE 	WHEN @pnOrganisationKey is not null
		 		THEN "	or A.RELATEDNAME = @pnOrganisationKey"
			END+")))"
			
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey		int,
						@pnOrganisationKey	int,
						@pnCaseKey			int',
						@pnNameKey		= @pnNameKey,
						@pnOrganisationKey	= @pnOrganisationKey,
						@pnCaseKey		= @pnCaseKey

	End
	Else 
	Begin
		Select null as TotalRows
		where 1=0
	End
End

-- Populate the RecentActivity result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('RECENTACTIVITY,', @psResultsetsRequired) <> 0)
Begin
	If @bHasAccess = 1
	Begin	
		Set @sSQLString = 
		"Select Top "+cast(@pnTopRowCount as varchar(10))+"
		A.ACTIVITYNO as [ActivityKey], 
		A.ACTIVITYDATE as [ActivityDate], 
		ISNULL(A.LONGNOTES, A.NOTES) as [Notes], 
		A.SUMMARY as [Summary], 
		TC.DESCRIPTION as [ActivityCategory], 
		C.IRN as [CaseReference], 
		A.CASEID as [CaseKey], 
		cast(A.INCOMPLETE as bit) as [IsIncomplete], 
		dbo.fn_FormatNameUsingNameNo(NC1.NAMENO, null) as [CallerName], 
		NC1.NAMENO as [CallerNameKey],
		dbo.fn_FormatNameUsingNameNo(NC5.NAMENO, null) as [StaffName], 
		NC5.NAMENO as [StaffNameKey],
		dbo.fn_FormatNameUsingNameNo(NC2.NAMENO, null) as [ContactName], 
		NC2.NAMENO as [ContactNameKey],
		dbo.fn_FormatNameUsingNameNo(NC4.NAMENO, null) as [RegardingName], 
		NC4.NAMENO as [RegardingNameKey],
		dbo.fn_FormatNameUsingNameNo(NC3.NAMENO, null) as [ReferredToName], 
		NC3.NAMENO as [ReferredToNameKey],
		TC2.DESCRIPTION as [ActivityType], 
		A.REFERENCENO as [Reference], 
		ATCH.AttachmentCount as [AttachmentCount], 
		AA.FILENAME as [FilePath],
		A.CLIENTREFERENCE as [ClientReference],
		cast(A.ACTIVITYNO as nvarchar(10)) as [RowKey]
		from ACTIVITY A
		left join TABLECODES TC		on (TC.TABLECODE = A.ACTIVITYCATEGORY)
		left join CASES C		on (C.CASEID = A.CASEID)
		left join NAME NC1 		on (NC1.NAMENO = A.CALLER)
		left join NAME NC5 		on (NC5.NAMENO = A.EMPLOYEENO)
		left join NAME NC2 		on (NC2.NAMENO = A.NAMENO)
		left join NAME NC4 		on (NC4.NAMENO = A.RELATEDNAME)
		left join NAME NC3 		on (NC3.NAMENO = A.REFERREDTO)
		left join TABLECODES TC2 	on (TC2.TABLECODE = A.ACTIVITYTYPE)
		left join (Select ACT.ACTIVITYNO, count(*) as AttachmentCount
			from ACTIVITYATTACHMENT ACT
	      		join ACTIVITY A	on (A.ACTIVITYNO = ACT.ACTIVITYNO)		
			where ((@pnCaseKey is not null and A.CASEID = @pnCaseKey) 
			or (@pnCaseKey is null and (A.NAMENO = @pnNameKey
	   		or  A.RELATEDNAME = @pnNameKey"+char(10)+
			CASE WHEN @pnOrganisationKey is not null
		 		THEN "	or A.RELATEDNAME = @pnOrganisationKey"
			END+")))
			group by ACT.ACTIVITYNO) ATCH 	
						on (ATCH.ACTIVITYNO = A.ACTIVITYNO)
		left join ACTIVITYATTACHMENT AA on (AA.ACTIVITYNO = A.ACTIVITYNO
						and AA.SEQUENCENO = (Select min(AA2.SEQUENCENO)
	    											from ACTIVITYATTACHMENT AA2
	     								where AA2.ACTIVITYNO = AA.ACTIVITYNO))
		where ((@pnCaseKey is not null and A.CASEID = @pnCaseKey) 
			or (@pnCaseKey is null and (A.NAMENO = @pnNameKey
		or  A.RELATEDNAME = @pnNameKey"+char(10)+
		CASE WHEN @pnOrganisationKey is not null
	 		THEN "	or A.RELATEDNAME = @pnOrganisationKey"
		END+"))) 
		order by [ActivityDate] DESC ,[Summary] ASC" 

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					@pnOrganisationKey	int,
					@pnCaseKey			int',
					@pnNameKey		= @pnNameKey,
					@pnOrganisationKey	= @pnOrganisationKey,
					@pnCaseKey		= @pnCaseKey
	End
	Else 
	Begin
		Select  null as ActivityKey,
			null as ActivityDate,
			null as Notes,
			null as Summary, 
			null as ActivityCategory,
			null as CaseReference,
			null as CaseKey,
			null as IsIncomplete,
			null as CallerName, 
			null as StaffName,
			null as ContactName, 
			null as RegardingName, 
			null as ReferredToName, 
			null as ActivityType, 
			null as Reference,
			null as AttachmentCount, 
			null as FilePath				
		where 1=0
	End
End
Return @nErrorCode
GO

Grant execute on dbo.naw_ListRecentActivity to public
GO
