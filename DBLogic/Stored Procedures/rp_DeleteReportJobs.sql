-------------------------------------------------------------------------------------------
-- Creation of dbo.rp_DeleteReportJobs
-------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[rp_DeleteReportJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.rp_DeleteReportJobs.'
	drop procedure dbo.rp_DeleteReportJobs
	print '**** Creating procedure dbo.rp_DeleteReportJobs...'
	print ''
end
go

CREATE PROCEDURE dbo.rp_DeleteReportJobs
(
	@pnRowCount	int		= null output,
	@pnJobId	int		= null,
	@psJobName	nvarchar(100) 	= null
)

-- PROCEDURE :	rp_DeleteReportJobs
-- VERSION :	3
-- DESCRIPTION:	Deletes a row from REPORTJOBS
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 28/06/2002	JB	Procedure created
-- 05/08/2002	JB	Standardised and renamed

AS
Declare @nError int

Delete 
	from REPORTJOBS 
	where JOBID = @pnJobId
	or JOBNAME = @psJobName

Select @pnRowCount = @@ROWCOUNT, @nError = @@ERROR

RETURN @nError
GO

Grant execute on dbo.rp_DeleteReportJobs to public
GO
