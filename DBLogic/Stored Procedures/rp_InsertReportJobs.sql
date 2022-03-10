----------------------------------------------------------------------------------------------
-- Creation of dbo.rp_InsertReportJobs
----------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[rp_InsertReportJobs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.rp_InsertReportJobs.'
	drop procedure dbo.rp_InsertReportJobs
	print '**** Creating procedure dbo.rp_InsertReportJobs...'
	print ''
end
go

CREATE PROCEDURE dbo.rp_InsertReportJobs
(
	@pnRowCount		int		= null output,
	@psJobName		nvarchar(100),	-- mand
	@pnReportId		int,		-- mand??
	@psNotes		nvarchar(max)	= null,
	@psOutputMethod		nvarchar(1),	-- mand	
	@psOutputOptions 	nvarchar(max)	= null,
	@psParameters		nvarchar(max)	= null
)
-- PROCEDURE :	rp_InsertReportJobs
-- VERSION :	3
-- DESCRIPTION:	Adds a row to REPORTJOBS
-- CALLED BY :	

-- Date		Who	MODIFICTION HISTORY
-- ====         ===	================
-- 28/06/2002	JB	Procedure created
-- 05/08/2002	JB	Brought into line with standards
-- 22 Aug 2019	vql	DR-40133 Change all NTEXT columns for all other miscellaneous Inprotech tables

AS

Declare @nError int

insert into REPORTJOBS 
	(
		JOBNAME, 
		REPORTID, 
		NOTES, 
		OUTPUTMETHOD, 
		OUTPUTOPTIONS, 
		PARAMETERS	
	)
	values
	(
		@psJobName, 
		@pnReportId, 
		@psNotes,
		@psOutputMethod, 
		@psOutputOptions, 
		@psParameters
	)

	Select @pnRowCount = @@ROWCOUNT, @nError = @@ERROR

RETURN @nError
GO

Grant execute on dbo.rp_InsertReportJobs to public
GO
