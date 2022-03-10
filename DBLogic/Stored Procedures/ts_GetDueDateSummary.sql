-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_GetDueDateSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_GetDueDateSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_GetDueDateSummary.'
	Drop procedure [dbo].[ts_GetDueDateSummary]
	Print '**** Creating Stored Procedure dbo.ts_GetDueDateSummary...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.ts_GetDueDateSummary
(
	@pnUserIdentityId		int	    = null,
	@psCulture			nvarchar(10) = null,
	@pnNameNo			int,	
	@psNameType			nvarchar(3),
	@pnNumberOfDays			smallint
)

-- PROCEDURE :	ts_GetDueDateSummary
-- VERSION :	5
-- DESCRIPTION:	Returns a summary of the number of due dates by Importance Level
--		over the defined number of days.
-- NOTES:	
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21/02/2003	MF			Procedure created
-- 14/03/2003	MF	8072		Correction in original coding to ensure the correct cycle is used.
-- 29 Sep 2004	MF	RFC1846	3	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 10 Apr 2007	DL	SQA12427 4	Exclude draft cases.
-- 18 Nov 2008	MF	SQA17136 5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

AS

-- Settings

Set nocount on
Set concat_null_yields_null off

Declare @ErrorCode 	int
Declare @sSQLString	nvarchar(4000)

Set @ErrorCode=0

If @ErrorCode=0
Begin
	Set @sSQLString="
		select I.IMPORTANCEDESC, I.IMPORTANCELEVEL, count(*)
		from CASENAME CN

		join CASES C on (C.CASEID = CN.CASEID)
		join CASETYPE CT ON (CT.CASETYPE = C.CASETYPE  and CT.ACTUALCASETYPE IS  NULL)

		join CASEEVENT CE	on (CE.CASEID=CN.CASEID
					and CE.OCCURREDFLAG=0)
		join EVENTCONTROL EC	on (EC.EVENTNO=CE.EVENTNO)
		join OPENACTION OA	on (OA.CASEID=CN.CASEID
					and OA.CRITERIANO=EC.CRITERIANO
					and OA.POLICEEVENTS=1)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		join IMPORTANCE I	on (I.IMPORTANCELEVEL=EC.IMPORTANCELEVEL)
		left join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
		where CN.NAMENO=@pnNameNo
		and   CN.NAMETYPE=@psNameType
		and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		and   CE.EVENTDUEDATE<=dateadd(day, @pnNumberOfDays, getdate())
		and  (CE.CREATEDBYCRITERIA=EC.CRITERIANO OR CE.CREATEDBYCRITERIA is null)
		and   OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN CE.CYCLE ELSE OA.CYCLE END
		and ((OA.ACTION=SC.COLCHARACTER and EC.EVENTNO=-11) or EC.EVENTNO<>-11 OR SC.COLCHARACTER is null)
		group by I.IMPORTANCEDESC, I.IMPORTANCELEVEL
		order by I.IMPORTANCELEVEL desc"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnNameNo		int,
					  @psNameType		nvarchar(3),
					  @pnNumberOfDays	smallint',
					  @pnNameNo=@pnNameNo,
					  @psNameType=@psNameType,
					  @pnNumberOfDays=@pnNumberOfDays
End

Return @ErrorCode
go

grant execute on dbo.ts_GetDueDateSummary to public
go
