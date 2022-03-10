-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_ReportCPASendSummary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_ReportCPASendSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_ReportCPASendSummary.'
	drop procedure dbo.cpa_ReportCPASendSummary
end
print '**** Creating procedure dbo.cpa_ReportCPASendSummary...'
print ''
go 


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE 	dbo.cpa_ReportCPASendSummary 
			@pnBatchNo 		int,
			@psPropertyType		nvarchar(2)	=null,
			@pbNotProperty		bit		=0,
			@psOfficeCPACode	nvarchar(3)	=null
as
-- PROCEDURE :	dbo.cpa_ReportCPASendSummary
-- VERSION :	1
-- DESCRIPTION:	Lists all columns from CPASEND table.
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07/10/2005	KR		1	Procedure Created

set nocount on


DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(1000)

set @ErrorCode=0

If @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT 	max(BATCHDATE), max(SYSTEMID),
		TRANSACTIONCODE, PROPERTYTYPE,
		Count(*)

	FROM	CPASEND
	
	WHERE	BATCHNO = @pnBatchNo
	AND	((PROPERTYTYPE = @psPropertyType and isnull(@pbNotProperty,0)= 0)
	  	or (PROPERTYTYPE <> @psPropertyType and @pbNotProperty=1)
	  	or  @psPropertyType is null)
	AND	(ALTOFFICECODE = @psOfficeCPACode or @psOfficeCPACode is null)
	GROUP BY TRANSACTIONCODE, PROPERTYTYPE
	ORDER BY TRANSACTIONCODE, PROPERTYTYPE"
		
		

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @psPropertyType	nvarchar(2),
				  @pbNotProperty	bit,
				  @psOfficeCPACode	nvarchar(3)',
				  @pnBatchNo=@pnBatchNo,
				  @psPropertyType=@psPropertyType,
				  @pbNotProperty=@pbNotProperty,
				  @psOfficeCPACode=@psOfficeCPACode


End

RETURN @ErrorCode 

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.cpa_ReportCPASendSummary to public
GO
