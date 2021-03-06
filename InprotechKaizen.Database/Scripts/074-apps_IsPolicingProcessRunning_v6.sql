-----------------------------------------------------------------------------------------------------------------------------
-- Creation of apps_IsPolicingProcessRunning
-----------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[apps_IsPolicingProcessRunning]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	PRINT '**** Drop Stored Procedure dbo.apps_IsPolicingProcessRunning.'
	DROP PROCEDURE [dbo].apps_IsPolicingProcessRunning
END
PRINT '**** Creating Stored Procedure dbo.apps_IsPolicingProcessRunning...'
PRINT ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apps_IsPolicingProcessRunning]
(
	@pnType int
)
-- PROCEDURE :	apps_IsPolicingProcessRunning
-- VERSION :	6
-- DESCRIPTION:	Checks if background process is running.

-- Modifications
--
-- Date			Who		Number		Version	Description
-- ------------	------	-------		-------	------------------------------------
-- 13 MAY 2016	HM		DR15007		1		Procedure created
-- 13 SEP 2016	SF		DR17650		2		Ensure procedure is granted adequate permission
-- 24 JAN 2017	SF		DR21394		3		Track continuous policing process using the temp database method, if the paired Inprotech has that facility.
-- 29 MAY 2019	SF		SDR27975	4		Avoid evaluating the function multiple times
-- 07 NOV 2019	SF		DR53818		5		Check site control 'Police Continuously' also
-- 25 MAR 2021	SF		DR53818		6		Stricter check to ensure terminated policing runs are considered as not running
as
	set nocount on
	
	if @pnType=1
	begin 
		declare @sTable nvarchar(200)
		set @sTable = dbo.fn_PolicingContinuouslyTrackingTable('%')

		select 1 
		from tempdb.INFORMATION_SCHEMA.TABLES t 
		where t.TABLE_NAME like @sTable
		and exists (
			select * 
			from SITECONTROL SC 
			left join ASYNCCOMMAND AC on AC.COMMAND like '%ipu_Policing%' and AC.COMMAND like '% @psDelayLength=%'
			where SC.CONTROLID = N'Police Continuously' and SC.COLBOOLEAN = 1 and AC.COMMANDID is not null
		)
		option (KEEPFIXED PLAN)

	end
	else if @pnType=2
	begin
		-- compatibility with older inprotech releases.
		select 1 
		from PROCESSREQUEST PR	
		where PR.REQUESTTYPE = N'POLICING BACKGROUND'
		and exists (
			select * 
			from SITECONTROL SC 
			left join ASYNCCOMMAND AC on AC.COMMAND like '%ipu_Policing%' and AC.COMMAND like '% @psDelayLength=%'
			where SC.CONTROLID = N'Police Continuously' and SC.COLBOOLEAN = 1 and AC.COMMANDID is not null
		)
	end
GO

GRANT EXECUTE ON dbo.apps_IsPolicingProcessRunning TO PUBLIC
GO