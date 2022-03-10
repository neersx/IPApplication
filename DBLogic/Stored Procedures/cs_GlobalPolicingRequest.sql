-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalPolicingRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalPolicingRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalPolicingRequest.'
	Drop procedure [dbo].[cs_GlobalPolicingRequest]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalPolicingRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalPolicingRequest
(
	@pnResults		int		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnProcessId		int,		-- Identifier for the background process request
	@psGlobalTempTable	nvarchar(50),	
	@pbDebugFlag            bit             = 0,
	@pbCalledFromCentura	bit		= 0,
	@psErrorMsg             nvarchar(max)   = null output
)
as
-- PROCEDURE:	cs_GlobalPolicingRequest
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Do batch policing for the selected action on the case list

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Jun 2018	MS	R11355	1	Procedure created
-- 14 Nov 2018  AV  75198/DR-45358	2   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Begin Try
        declare	@nErrorCode	int
        declare @RowCount	int
        declare @nBatchNo	int
        declare @sSQLString	nvarchar(max)

        CREATE TABLE #tbPolicing (                
		        POLICINGSEQNO	        int	        identity,
                        CASEID                  int,
		        ACTION		        nvarchar(2)	collate database_default NOT NULL,
		        CYCLE		        smallint	NOT NULL     
 		        )

        CREATE TABLE #UPDATEDCASES(
	        CASEID int NOT NULL
        )

        -- Initialise variables
        Set @nErrorCode = 0

        If @nErrorCode = 0
        Begin
                exec @nErrorCode = dbo.ip_GetLastInternalCode
                                @pnUserIdentityId       = @pnUserIdentityId,
                                @psCulture              = @psCulture,
                                @psTable                = 'POLICINGBATCH',
                                @pnLastInternalCode     = @nBatchNo output
        End

        -- Insert a Policing Row for each OpenAction that needs recalculating. Need to 
        -- go via an interim temporary table in order to generate an internal 
        -- sequence number.

        If @nErrorCode=0
        Begin
	        Set @sSQLString="insert into #tbPolicing(CASEID, ACTION, CYCLE)
	        select C.CASEID, GC.ACTION, ISNULL(OA.CYCLE, 1)
	        from " + @psGlobalTempTable + " C
                join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
                left join OPENACTION OA on (OA.CASEID = C.CASEID and OA.ACTION = GC.ACTION and POLICEEVENTS=1)"

                exec @nErrorCode=sp_executesql @sSQLString,
			        N'@pnProcessId	int	        OUTPUT',
			          @pnProcessId  = @pnProcessId	OUTPUT

	        Select @RowCount=@@Rowcount

        End

        If  @nErrorCode=0
        and @RowCount >0
        Begin
	        insert into POLICING(	DATEENTERED, POLICINGSEQNO, POLICINGNAME,  
				        SYSGENERATEDFLAG, ONHOLDFLAG, ACTION ,CYCLE, TYPEOFREQUEST,
				        SQLUSER, BATCHNO, CASEID, IDENTITYID)
                OUTPUT INSERTED.CASEID INTO #UPDATEDCASES
	        select	getdate(), POLICINGSEQNO, convert(varchar,getdate(),126)+convert(varchar,POLICINGSEQNO), 
		        1, 1, ACTION ,CYCLE, 1, SYSTEM_USER, @nBatchNo, CASEID, @pnUserIdentityId
	        from #tbPolicing

	
	        Select @nErrorCode=@@Error,
	               @RowCount =@@Rowcount
        End

        If @nErrorCode = 0
        Begin
	        Set @sSQLString = "
		        UPDATE " +@psGlobalTempTable+ "
		        SET ISPOLICED = 1
		        from " +@psGlobalTempTable+ " C
		        join #UPDATEDCASES UC on (UC.CASEID = C.CASEID)"
		
		exec @nErrorCode = sp_executesql @sSQLString  
        End

        If  @nErrorCode=0
        and @RowCount >0
        and @nBatchNo is not null
        Begin
	        exec @nErrorCode=dbo.ipu_Policing
                                    @pnBatchNo          = @nBatchNo,
				    @pnUserIdentityId   = @pnUserIdentityId
        End

End Try
Begin Catch
	SET @nErrorCode = ERROR_NUMBER()
	SET @psErrorMsg = ERROR_MESSAGE()
End Catch

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalPolicingRequest to public
GO
