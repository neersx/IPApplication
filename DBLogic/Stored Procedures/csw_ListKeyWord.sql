-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListKeyWord 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListKeyWord ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListKeyWord .'
	Drop procedure [dbo].[csw_ListKeyWord ]
	Print '**** Creating Stored Procedure dbo.csw_ListKeyWord ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListKeyWord 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListKeyWord 
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates KeyWord data table.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Oct 2004  TM	RFC1156	1	Procedure created
-- 29 Nov 2004	TM	RFC1156	2	Correct the comments.
-- 27 Jun 2006	SW	RFC4038	3	Add rowkey
-- 24 Oct 2011	ASH	R11460  4	Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
-- Populating KeyWord result set
If @nErrorCode = 0
and @pnCaseKey is not null
Begin	
	Set @sSQLString = "
	Select 	cast(C.CASEID as nvarchar(11)) + '^'
		+ cast(C.KEYWORDNO as nvarchar(11)) as RowKey,
		C.CASEID   as CaseKey,
		Y.KEYWORD  as KeyWord		
		from CASEWORDS C
		join  KEYWORDS Y on (Y.KEYWORDNO = C.KEYWORDNO)
		WHERE C.CASEID = @pnCaseKey 
		ORDER BY KeyWord"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int',
					  @pnCaseKey	= @pnCaseKey
	Set @pnRowCount = @@Rowcount
End
Else
If @nErrorCode = 0
and @pnCaseKey is null
Begin
	Select 	null  as RowKey,
		null  as CaseKey,
		null  as KeyWord
	where 1 = 0	

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListKeyWord  to public
GO
