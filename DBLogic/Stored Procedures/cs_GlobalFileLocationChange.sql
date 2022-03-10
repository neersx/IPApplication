-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalFileLocationChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalFileLocationChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalFileLocationChange.'
	Drop procedure [dbo].[cs_GlobalFileLocationChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalFileLocationChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalFileLocationChange
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
-- PROCEDURE:	cs_GlobalFileLocationChange
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a new File Location record against a set of cases. 
--              No concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Oct 2010	LP	RFC9321	1	Procedure created
-- 15 Mar 2011  LP      RFC10087 2      Fix logic to delete older file location entries if over MAXLOCATIONS  
-- 06 Apr 2011  LP      RFC100491 3     Prevent errors in insert by checking if the same CASEID and WHENMOVED 
--                                      already exists in CASELOCATION table.
-- 28 Oct 2013  MZ      RFC10491 4      Fixed global field update of family not working and error message not showing correctly
-- 13 Apr 2015  MS      R34463  5       Added miliseconds to WhenMoved for handling multiple file parts
--                                      and also fixed delete caselocation query when it crosses max locations allowed

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Begin Try
declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @nMaxLocations  int

CREATE TABLE #UPDATEDCASES(
	CASEID int NOT NULL
)

-- Initialise variables
Set @nErrorCode = 0

-- Assign MAXLOCATIONS site control to variable
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @nMaxLocations = COLINTEGER 
		from SITECONTROL 
		where CONTROLID = 'MAXLOCATIONS'"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@nMaxLocations	int			OUTPUT',
				  @nMaxLocations	= @nMaxLocations	OUTPUT
End

-- Now insert the new CASELOCATION records
If @nErrorCode = 0
Begin
        Set @sSQLString = 
	"INSERT INTO CASELOCATION (CASEID, WHENMOVED, FILEPARTID, FILELOCATION, BAYNO, ISSUEDBY)	
	OUTPUT INSERTED.CASEID
	INTO #UPDATEDCASES
	SELECT C.CASEID, DATEADD(millisecond,10 * ROW_NUMBER() OVER (ORDER BY C.CASEID, FP.FILEPART),GC.WHENMOVED), FP.FILEPART, GC.FILELOCATION, GC.BAYNO, GC.ISSUEDBY
	from CASES C
	join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
	join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
	left join FILEPART FP on (FP.CASEID = C.CASEID)
	where not exists ( SELECT 1 from CASELOCATION CL
	                   WHERE CL.CASEID = C.CASEID
	                   AND CL.WHENMOVED = GC.WHENMOVED )
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
		SET FILELOCATIONUPDATED = 1
		from " +@psGlobalTempTable+ " C
		join #UPDATEDCASES UC on (UC.CASEID = C.CASEID)"
		
		exec @nErrorCode = sp_executesql @sSQLString
	End

End

-- Delete outdated CASELOCATION records if required
If @nErrorCode = 0
and @nMaxLocations > 0
Begin
	Set @sSQLString = "
	Delete from CASELOCATION
	from CASELOCATION C
	join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
        join (select CL.CASEID, CL.WHENMOVED, row_number() over (PARTITION BY CASEID ORDER BY WHENMOVED DESC) as ROWID
	       from CASELOCATION CL) DC on (DC.CASEID = C.CASEID and DC.WHENMOVED = C.WHENMOVED)
        WHERE DC.ROWID > @nMaxLocations"
		
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@nMaxLocations	int',
				  @nMaxLocations	= @nMaxLocations	
End

End Try
Begin Catch
	SET @nErrorCode = ERROR_NUMBER()
	SET @psErrorMsg = ERROR_MESSAGE()
End Catch

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalFileLocationChange to public
GO
