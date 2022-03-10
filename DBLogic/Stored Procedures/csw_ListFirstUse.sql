-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFirstUse 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFirstUse ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFirstUse .'
	Drop procedure [dbo].[csw_ListFirstUse ]
	Print '**** Creating Stored Procedure dbo.csw_ListFirstUse ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListFirstUse 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbIsExternalUser 	bit,		-- Mandatory 		
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListFirstUse 
-- VERSION:	7
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates FirstUse datatable.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Oct 2004  TM	RFC1156	1	Procedure created
-- 27 Oct 2004	TM	RFC1156	2	Suppress the FirstUse result set if FirstUseDate, PlaceFirstUsed 
--					and ProposedUse are null.
-- 29 Nov 2004	TM	RFC1156	3	Remove unnecessary derived table.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 27 Jun 2006	SW	RFC4038	5	Add rowkey
-- 11 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Oct 2011	ASH	R11460  7	Cast integer columns as nvarchar(11) data type.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
-- Populating FirstUse datatable
If @nErrorCode = 0
and @pnCaseKey is not null
Begin	
	Set @sSQLString = "
	Select  cast(C.CASEID as nvarchar(11)) as RowKey, 
		C.CASEID 		as CaseKey, 
		CE.EVENTDATE 		as FirstUseDate,
		"+dbo.fn_SqlTranslatedColumn('PROPERTY','PLACEFIRSTUSED',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ "	as PlaceFirstUsed,
		"+dbo.fn_SqlTranslatedColumn('PROPERTY','PROPOSEDUSE',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ "	as ProposedUse	
	from CASES C
	left join SITECONTROL SC 	on (SC.CONTROLID = 'First Use Event')
	left join CASEEVENT CE		on (CE.EVENTNO = SC.COLINTEGER
					and CE.CASEID = @pnCaseKey
					and CE.CYCLE = 1) 
	left join PROPERTY P 		on (P.CASEID = C.CASEID) 
	where C.CASEID = @pnCaseKey
	and (CE.EVENTDATE is not null
	 or  P.PLACEFIRSTUSED  is not null
	 or  P.PROPOSEDUSE is not null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @pnUserIdentityId	int,
					  @psCulture		nvarchar(10),
					  @pbIsExternalUser	bit,
					  @pbCalledFromCentura	bit',
					  @pnCaseKey		= @pnCaseKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psCulture		= @psCulture,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbCalledFromCentura	= @pbCalledFromCentura
	Set @pnRowCount = @@Rowcount
End
Else
If @nErrorCode = 0
and @pnCaseKey is null
Begin	
	Select  null	as RowKey, 
		null	as CaseKey, 
		null	as FirstUseDate,
		null	as PlaceFirstUsed,
		null	as ProposedUse	
	where 1=0

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFirstUse  to public
GO
