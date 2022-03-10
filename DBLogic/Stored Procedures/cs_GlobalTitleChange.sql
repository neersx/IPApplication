-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalTitleChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalTitleChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalTitleChange.'
	Drop procedure [dbo].[cs_GlobalTitleChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalTitleChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalTitleChange
(
	@pnResults		int		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnProcessId		int,		-- Identifier for the background process request
	@psGlobalTempTable	nvarchar(50),	
	@pbDebugFlag            bit             = 0,
	@pbCalledFromCentura	bit		= 0,
	@psErrorMsg nvarchar(max) = null output
)
as
-- PROCEDURE:	cs_GlobalTitleChange
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the Title field against the specified case. 
--              No concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Oct 2010	LP	RFC9321	1	Procedure created
-- 28 Oct 2013  MZ  RFC10491 2  Fixed global field update of family not working and error message not showing correctly
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Begin Try
declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)

CREATE TABLE #UPDATEDCASES(
	CASEID int NOT NULL
)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"UPDATE CASES
	Set TITLE = GC.TITLE
	OUTPUT INSERTED.CASEID
	INTO #UPDATEDCASES
	from CASES C
	join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
	join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
	
	set @pnResults = @@RowCount"
		
	If @pbDebugFlag = 1
	Begin
		Print @sSQLString
	End

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnProcessId	int,
				  @pnResults	int	output',
				  @pnProcessId	= @pnProcessId,
				  @pnResults	= @pnResults OUTPUT
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		UPDATE " +@psGlobalTempTable+ "
		SET TITLEUPDATED = 1
		from " +@psGlobalTempTable+ " C
		join #UPDATEDCASES UC on (UC.CASEID = C.CASEID)"
		
		exec @nErrorCode = sp_executesql @sSQLString
	End

End

End Try
Begin Catch
	SET @nErrorCode = ERROR_NUMBER()
	SET @psErrorMsg = ERROR_MESSAGE()
End Catch

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalTitleChange to public
GO
