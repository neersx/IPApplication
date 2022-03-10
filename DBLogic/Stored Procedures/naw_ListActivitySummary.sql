-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListActivitySummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListActivitySummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListActivitySummary.'
	Drop procedure [dbo].[naw_ListActivitySummary]
	Print '**** Creating Stored Procedure dbo.naw_ListActivitySummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_ListActivitySummary
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey			int		= null,
	@pnOrganisationKey		int		= null,
	@pnCaseKey			int		= null,
	@pbCanViewContactActivities	bit		= 0,
	@pbCalledFromCentura		bit		= 0,
	@psResultsetsRequired		nvarchar(4000)	= null		-- comma seperated list to describe which resultset to return
)
AS
-- PROCEDURE:	naw_ListActivitySummary
-- VERSION:	11
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the ActivityByContact and ActivityByCategory data tables.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Dec 2004  TM	RFC2048	1	Procedure created
-- 16 Dec 2004	TM	RFC2048	2	Use a left join to Name as the Contact is not always present.
-- 16 Dec 2004	TM	RFC2048	3	Correct the filtering logic to suppress the rows when the 
--					access to the Contact Activity information security subject.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 17 Jul 2006	SW	RFC3828	5	Pass getdate() to fn_Permission..
-- 25 Aug 2006	SF	RFC4214	6	Add RowKey, Add ResultsetsRequired parameter
-- 01 Mar 2007	PY	SQA14425 7 	Reserved word [count]
-- 14 Jun 2011	JC	RFC100151	8	Improve performance by removing fn_GetTopicSecurity: authorisation is now given by the caller
-- 11 Apr 2013	DV	R13270	9	Increase the length of nvarchar to 11 when casting or declaring integer 
-- 02 Nov 2015	vql	R53910	10	Adjust formatted names logic (DR-15543).
-- 17 Aug 2018	DV  R74350	11	Return Contact activity details for non Crm cases

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
Set	@psResultsetsRequired = upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','

Set	@nErrorCode      = 0

-- Populate the ActivityByContact result set:
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
or CHARINDEX('ACTIVITYBYCONTACT,', @psResultsetsRequired) <> 0)
Begin	
	Set @sSQLString = "
	Select 	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
					as ContactName,
		N.NAMENO		as ContactKey,
		count(A.ACTIVITYNO)	as [Count],
		isnull(cast(N.NAMENO as nvarchar(11)),'NONE') as RowKey  -- RowKey cannot be null
	from 	ACTIVITY A
	left join    NAME N		on (N.NAMENO = A.NAMENO)
	where  (@pnCaseKey is null and (A.NAMENO 	= @pnNameKey
	or      A.RELATEDNAME 	= @pnNameKey
	or	A.RELATEDNAME 	= @pnOrganisationKey))
	or  (@pnCaseKey is not null and A.CASEID = @pnCaseKey)
	and 	@pbCanViewContactActivities 	= 1	
	group by N.NAMENO, N.NAME, N.FIRSTNAME, N.TITLE
	order by ContactName"	

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pbCanViewContactActivities	bit,
				  @pnNameKey			int,
				  @pnOrganisationKey		int,
				  @pnCaseKey			int',
				  @pbCanViewContactActivities	= @pbCanViewContactActivities,
				  @pnNameKey			= @pnNameKey,
				  @pnOrganisationKey	= @pnOrganisationKey,
				  @pnCaseKey			= @pnCaseKey 
	
End

-- Populate the ActivityByCategory result set:
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
or CHARINDEX('ACTIVITYBYCATEGORY,', @psResultsetsRequired) <> 0)
Begin	
	Set @sSQLString = "
	Select "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) 
				     +" as Category,
		A.ACTIVITYCATEGORY	as CategoryKey,
		count(A.ACTIVITYNO)	as [Count],
		cast(A.ACTIVITYCATEGORY as nvarchar(10)) as RowKey
	from 	ACTIVITY A
	join TABLECODES TC		on (TC.TABLECODE = A.ACTIVITYCATEGORY)
	where  (@pnCaseKey is null and (A.NAMENO 	= @pnNameKey
	or      A.RELATEDNAME 	= @pnNameKey
	or	A.RELATEDNAME 	= @pnOrganisationKey))
	or  (@pnCaseKey is not null and A.CASEID = @pnCaseKey)
	and 	@pbCanViewContactActivities 	= 1	
	group by TC.DESCRIPTION, TC.DESCRIPTION_TID, A.ACTIVITYCATEGORY
	order by Category"	

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pbCanViewContactActivities	bit,
				  @pnNameKey			int,
				  @pnOrganisationKey		int,
				  @pnCaseKey			int',
				  @pbCanViewContactActivities	= @pbCanViewContactActivities,
				  @pnNameKey			= @pnNameKey,
				  @pnOrganisationKey		= @pnOrganisationKey,
				  @pnCaseKey			= @pnCaseKey	
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListActivitySummary to public
GO
