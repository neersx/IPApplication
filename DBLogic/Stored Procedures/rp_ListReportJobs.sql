---------------------------------------------------------------------------------------------
-- Creation of dbo.rp_ListReportJobs
---------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[rp_ListReportJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.rp_ListReportJobs.'
	drop procedure dbo.rp_ListReportJobs
	print '**** Creating procedure dbo.rp_ListReportJobs...'
	print ''
end
go

CREATE PROCEDURE dbo.rp_ListReportJobs
(
	@pnRowCount	int		= null output,
	@pnJobId	int		= null,
	@psJobName	nvarchar(100)	= null
)
-- PROCEDURE :	rp_ListReportJobs
-- VERSION :	3
-- DESCRIPTION:	Retrieves a row from REPORTJOBS
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 28/06/2002	JB	Procedure created
-- 05/08/2002	JB	Standardised and renamed

AS
Declare @nError int
Select 	JOBID, JOBNAME, REPORTID, NOTES, OUTPUTMETHOD, OUTPUTOPTIONS, PARAMETERS
	from  	REPORTJOBS 
	where 	JOBNAME = @psJobName
		or JOBID = @pnJobId
		or (@pnJobId is null and @psJobName is null)

	Select @pnRowCount = @@ROWCOUNT, @nError = @@ERROR

RETURN @nError
GO

Grant execute on dbo.rp_ListReportJobs to public
GO
