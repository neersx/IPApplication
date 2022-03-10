If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_PurgeOldCaseFeeQueries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_PurgeOldCaseFeeQueries.'
	Drop procedure [dbo].[cs_PurgeOldCaseFeeQueries]
End
Print '**** Creating Stored Procedure dbo.cs_PurgeOldCaseFeeQueries...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_PurgeOldCaseFeeQueries
(
	@pnUserIdentityId	int		= null,		
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	cs_PurgeOldCaseFeeQueries
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Purge old case fees searches based on the date they were created.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Feb 2010	LP	RFC8865	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"delete QUERY"+char(10)+
	"where GROUPID in (-330,-331)"+char(10)+
	"and QUERYID in ("+char(10)+
	"select Q.QUERYID from QUERY Q"+char(10)+
	"join QUERY_iLOG Qi on (Qi.QUERYID = Q.QUERYID)"+char(10)+
	"join SITECONTROL SC on (SC.CONTROLID = 'Case Fees Queries Purge Days')"+char(10)+
	"where ISNULL(SC.COLINTEGER,0) > 0"+char(10)+
	"and Qi.CONTEXTID in (330,331)"+char(10)+
	"and Qi.LOGACTION = 'I'"+char(10)+
	"and Qi.LOGDATETIMESTAMP < dateadd(D, SC.COLINTEGER*-1, convert(datetime,floor(cast (getdate() as float)),112)))"
	
	exec @nErrorCode=sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.cs_PurgeOldCaseFeeQueries to public
GO
