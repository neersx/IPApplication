-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalOfficeChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalOfficeChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalOfficeChange.'
	Drop procedure [dbo].[cs_GlobalOfficeChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalOfficeChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalOfficeChange
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
-- PROCEDURE:	cs_GlobalOfficeChange
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the Office field against the specified case. 
--              No concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 May 2010	LP	RFC6503	1	Procedure created
-- 12 Oct 2010	LP	RFC9321	2	Extend to update multiple cases at a time
-- 28 Oct 2013  MZ  RFC10491 3  Fixed global field update of family not working and error message not showing correctly
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
	Set OFFICEID = GC.OFFICEID
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
		SET OFFICEUPDATED = 1
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

Grant execute on dbo.cs_GlobalOfficeChange to public
GO
