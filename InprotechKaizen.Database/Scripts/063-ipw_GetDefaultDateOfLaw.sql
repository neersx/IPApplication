-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetDefaultDateOfLaw
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_GetDefaultDateOfLaw]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_GetDefaultDateOfLaw.'
	drop procedure dbo.ipw_GetDefaultDateOfLaw
end
print '**** Creating procedure dbo.ipw_GetDefaultDateOfLaw...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ipw_GetDefaultDateOfLaw 
			@pnCaseId int,
			@psActionId nvarchar(2)
as
-- PROCEDURE :	ipw_GetDefaultDateOfLaw
-- VERSION :	1
-- DESCRIPTION: Get the default Date Of Law for a best-fit criteria search.
-- CALLED BY :	ipw_GetDefaultDateOfLaw

-- MODIFICATION
-- Date		Who	RFC	Version	Description
-- ====         ===	=== 	=======	============================================
-- 02/02/2016	AT	51209	1	Procedure created.

set nocount on
set concat_null_yields_null off

DECLARE	@ErrorCode		int
DECLARE @sSql			nvarchar(max)

Set @ErrorCode = 0

create table #TEMPOPENACTION(
	CASEID			int		NOT NULL,
	ACTION			nvarchar(2)	collate database_default NOT NULL,
	CYCLE			smallint	NOT NULL,
	LASTEVENT		int		NULL,
	CRITERIANO		int		NULL,
	DATEFORACT		datetime	NULL,
	NEXTDUEDATE		datetime	NULL,
	POLICEEVENTS		decimal(1,0)	NULL,
	STATUSCODE		smallint	NULL,
	STATUSDESC		nvarchar(50)	collate database_default NULL,
	DATEENTERED		datetime	NULL,
	DATEUPDATED		datetime	NULL,
	CASETYPE		nchar(1)	collate database_default NULL,
	PROPERTYTYPE		nchar(1)	collate database_default NULL,
	COUNTRYCODE		nvarchar(3)	collate database_default NULL,
	CASECATEGORY		nvarchar(2)	collate database_default NULL,
	SUBTYPE			nvarchar(2)	collate database_default NULL,
	BASIS			nvarchar(2)	collate database_default NULL,
	REGISTEREDUSERS		nchar(1)	collate database_default NULL,
	LOCALCLIENTFLAG		decimal(1,0)	NULL,
	EXAMTYPE		int		NULL,
	RENEWALTYPE		int		NULL,
	CASEOFFICEID		int		NULL,
	NEWCRITERIANO		int		NULL,
	USERID			nvarchar(255)	collate database_default NULL,
	STATE			nvarchar(2)	collate database_default NULL,	/*C-Calculate,C1-CalculationDone,E-Error	*/
	IDENTITYID		int		NULL
)


CREATE TABLE #TEMPCASEEVENT(
	CASEID			int		NOT NULL,
        DISPLAYSEQUENCE		smallint	NULL,
	EVENTNO			int		NOT NULL,
	CYCLE			smallint	NOT NULL,
	OLDEVENTDATE		datetime	NULL,
	OLDEVENTDUEDATE		datetime	NULL,
	DATEREMIND		datetime	NULL,
	DATEDUESAVED		decimal(1,0)	NULL,
	OCCURREDFLAG		decimal(1,0)	NULL,
	CREATEDBYACTION		nvarchar(2)	collate database_default NULL,
	CREATEDBYCRITERIA	int		NULL,
	ENTEREDDEADLINE		smallint	NULL,
	PERIODTYPE		nchar(1)	collate database_default NULL,
	DOCUMENTNO		smallint	NULL,
	DOCSREQUIRED		smallint	NULL,
	DOCSRECEIVED		smallint	NULL,
	USEMESSAGE2FLAG		decimal(1,0)	NULL,
	SUPPRESSREMINDERS	decimal(1,0)	NULL,
	OVERRIDELETTER		int		NULL,
	GOVERNINGEVENTNO	int		NULL,
	[STATE]			nvarchar(2)	collate database_default NOT NULL,--C=calculate;I=insert;D=delete
	ADJUSTMENT		nvarchar(4)	collate database_default NULL,	 -- any adjustment to be made to the date
	IMPORTANCELEVEL		nvarchar(2)	collate database_default NULL,
	WHICHDUEDATE		nchar(1)	collate database_default NULL,
	COMPAREBOOLEAN		decimal(1,0)	NULL,
	CHECKCOUNTRYFLAG	int		NULL,
	SAVEDUEDATE		smallint	NULL,
	STATUSCODE		smallint	NULL,
	SPECIALFUNCTION		nchar(1)	collate database_default NULL,
	INITIALFEE		int		NULL,
	PAYFEECODE		nchar(1)	collate database_default NULL,
	CREATEACTION		nvarchar(2)	collate database_default NULL,
	STATUSDESC		nvarchar(50)	collate database_default NULL,
	CLOSEACTION		nvarchar(2)	collate database_default NULL,
	RELATIVECYCLE		smallint	NULL,
	INSTRUCTIONTYPE		nvarchar(3)	collate database_default NULL,
	FLAGNUMBER		smallint	NULL,
	SETTHIRDPARTYON		decimal(1,0)	NULL,
	COUNTRYCODE		nvarchar(3)	collate database_default NULL,
	NEWEVENTDATE		datetime	NULL,
	NEWEVENTDUEDATE		datetime	NULL,
	NEWDATEREMIND		datetime	NULL,
	USEDINCALCULATION	nchar(1)	collate database_default NULL,
	LOOPCOUNT		smallint	NULL,
	REMINDERTOSEND		smallint	NULL,
	UPDATEFROMPARENT	tinyint		NULL,
	PARENTEVENTDATE		datetime	NULL,
	USERID			nvarchar(255)	collate database_default NULL,
	EVENTUPDATEDMANUALLY	tinyint		NULL,
	CRITERIANO		int		NULL,
	ACTION			varchar(2)	collate database_default NULL,
	UNIQUEID		int		identity(10,10),
	ESTIMATEFLAG		decimal(1,0)	NULL,
	EXTENDPERIOD		smallint	NULL,
	EXTENDPERIODTYPE	nchar(1)	collate database_default NULL,
	INITIALFEE2		int		NULL,
	PAYFEECODE2		nchar(1)	collate database_default NULL,
	ESTIMATEFLAG2		decimal(1,0)	NULL,
	PTADELAY		smallint	NULL,
	IDENTITYID		int		NULL,
	SETTHIRDPARTYOFF	bit		NULL,
	CHANGENAMETYPE		nvarchar(3)	collate database_default NULL,
	COPYFROMNAMETYPE	nvarchar(3)	collate database_default NULL,
	COPYTONAMETYPE		nvarchar(3)	collate database_default NULL,
	DELCOPYFROMNAME		bit		NULL,
	DIRECTPAYFLAG		bit		NULL,
	DIRECTPAYFLAG2		bit		NULL,
	FROMCASEID		int		NULL,
	LIVEFLAG		bit		default(0),
	RESPNAMENO		int		NULL,
	RESPNAMETYPE		nvarchar(3)	collate database_default NULL,
	LOADNUMBERTYPE		nchar(1)	collate database_default NULL,	--SQA17773
	PARENTNUMBER		nvarchar(36)	collate database_default NULL,	--SQA17773
	RECALCEVENTDATE		bit		NULL,	-- SQA19252,	
	SUPPRESSCALCULATION	bit		NULL,	-- SQA21404
	DELETEDPREVIOUSLY	tinyint		NULL	-- RFC40815 Counter used to avoid continuously triggering an Event as deleted
)


	set @sSql = '
		INSERT INTO #TEMPOPENACTION (CASEID, ACTION, CYCLE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE, BASIS, [STATE])
		SELECT C.CASEID, @psActionId, 1, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE, P.BASIS, ''C''
		FROM CASES C
		JOIN PROPERTY P ON P.CASEID = C.CASEID
		WHERE C.CASEID = @pnCaseId'

	exec @ErrorCode = sp_executesql @sSql,
				N'@psActionId nvarchar(2),
				  @pnCaseId int',
				  @psActionId = @psActionId,
				  @pnCaseId = @pnCaseId

if @ErrorCode = 0
Begin
	set @sSql = 'INSERT INTO #TEMPCASEEVENT (CASEID, CYCLE, EVENTNO, [STATE], NEWEVENTDATE)
		select C.CASEID, 1, E.EVENTNO, ''C'', E.EVENTDATE
		FROM CASES C
		JOIN CASEEVENT E ON E.CASEID = C.CASEID
		WHERE C.CASEID = @pnCaseId'

	exec @ErrorCode = sp_executesql @sSql,
				N'@psActionId nvarchar(2),
				  @pnCaseId int',
				  @psActionId = @psActionId,
				  @pnCaseId = @pnCaseId
End

if @ErrorCode = 0
Begin
	exec @ErrorCode = ip_PoliceCalculateDateofLaw 0
End

if @ErrorCode = 0
Begin
	SELECT DATEFORACT FROM #TEMPOPENACTION
End

if @ErrorCode = 0
Begin
	drop table #TEMPOPENACTION
	drop table #TEMPCASEEVENT
End

return @ErrorCode
go

grant execute on dbo.ipw_GetDefaultDateOfLaw  to public
go
