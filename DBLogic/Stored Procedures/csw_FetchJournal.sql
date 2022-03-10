-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchJournal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchJournal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchJournal.'
	Drop procedure [dbo].[csw_FetchJournal]
End
Print '**** Creating Stored Procedure dbo.csw_FetchJournal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_FetchJournal
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_FetchJournal
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Journal business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Sep 2010	MS	RFC9759	1	Procedure created
-- 01 Nov 2011	ASH	R11460 	2	CAST int CaseID column to nvarchar(11)
-- 05 Jan 2012  MS      R11186  3       Add LOGDATETIMESTAMP column in select list

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin	
        Set @sSQLString = "Select	
		CAST(CASEID as nvarchar(11)) + '^' + CAST(SEQUENCE as nvarchar(10)) as 'RowKey',
		CASEID          as 'CaseKey',
		SEQUENCE        as 'Sequence',
		JOURNALNO	as 'JournalNo',
		JOURNALPAGE	as 'JournalPage',
		JOURNALDATE     as 'JournalDate',
		LOGDATETIMESTAMP as 'LastModifiedDate'       		
		from JOURNAL 		
		where CASEID = @pnCaseKey
		order by 'JournalNo', 'JournalPage' "

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseKey		int',
		@pnCaseKey		= @pnCaseKey	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchJournal to public
GO
