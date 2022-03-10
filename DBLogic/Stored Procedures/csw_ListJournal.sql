-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListJournal 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListJournal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListJournal.'
	Drop procedure [dbo].[csw_ListJournal]
	Print '**** Creating Stored Procedure dbo.csw_ListJournal...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListJournal 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListJournal 
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates Journal datatable.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Oct 2004  TM	RFC1156	1	Procedure created
-- 27 Jun 2006	SW	RFC4038	2	Add rowkey
-- 24 Oct 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
-- Populating Journal datatable
If @nErrorCode = 0
and @pnCaseKey is not null
Begin	
	Set @sSQLString = "
	Select    cast(J.CASEID as nvarchar(11)) + '^'
		+ cast(J.[SEQUENCE] as nvarchar(10))
				as RowKey,
		J.CASEID	as CaseKey,
		J.JOURNALNO	as JournalNo,
		J.JOURNALPAGE	as JournalPage,
		J.JOURNALDATE 	as JournalDate
	from JOURNAL J	
	where J.CASEID = @pnCaseKey
	order by SEQUENCE"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
	Set @pnRowCount = @@Rowcount
End
Else
If @nErrorCode = 0
and @pnCaseKey is null
Begin	
	Select  null	as RowKey,
		null	as CaseKey,
		null	as JournalNo,
		null	as JournalPage,
		null 	as JournalDate
	where 1=0

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListJournal to public
GO
