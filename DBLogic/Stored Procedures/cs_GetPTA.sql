-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetPTA
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GetPTA]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GetPTA.'
	drop procedure dbo.cs_GetPTA
end
print '**** Creating procedure dbo.cs_GetPTA...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cs_GetPTA
		@pnCaseId 		int		= null,		-- the Case being reported on
		@pnRowCount		int		= null OUTPUT,
		@pbCalledFromCentura 	bit 		= 1,
		@pnUserIdentityId	int		= null,
		@pbIsExternalUser 	bit 		= null,
		@psCulture		nvarchar(10)	= null		-- the culture the output is required in
as
-- PROCEDURE 	: cs_GetPTA
-- VERSION 	: 6
-- DESCRIPTION	:	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 JUL 2003	IB	8260 	1	Procedure created
-- 17 MAR 2004  AB		2	Modify grant statement
-- 21 OCT 2004	TM	RFC1156	3	Add new @pbCalledFromCentura and @pbIsExternalUser parameters. When @pbCalledFromCentura = 0, 
--					return the new PTAEvent datatable.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 26 Jun 2006	SW	RFC4038	5	Return rowkey when @pbCalledFromCentura = 0
-- 24 Oct 2011	ASH	R11460  6	Cast integer columns as nvarchar(11) data type.

Declare	@sSQLString	nvarchar(4000)
Declare @ErrorCode	int

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode=0

If @ErrorCode=0
and @pbCalledFromCentura = 1
Begin
	Set @sSQLString="
	Select	distinct
		CE.EVENTNO,
		"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+" 
		as EVENTDESCRIPTION,				
		CE.EVENTDUEDATE,
		CE.EVENTDATE,
		CASE WHEN(EC.PTADELAY = 1)
			THEN	CASE WHEN (CE.EVENTDATE>CE.EVENTDUEDATE)
					THEN DATEDIFF(day, CE.EVENTDUEDATE, CE.EVENTDATE)
					ELSE NULL
				END
			ELSE	NULL
		END AS IPOFFICEDELAY,
		CASE WHEN(EC.PTADELAY = 2)
			THEN 	CASE WHEN (CE.EVENTDATE>CE.EVENTDUEDATE)
					THEN DATEDIFF(day, CE.EVENTDUEDATE, CE.EVENTDATE)
					ELSE NULL
				END
			ELSE	NULL
		END AS APPLDELAY, 
		EC.DISPLAYSEQUENCE
	From OPENACTION OA
	Join EVENTCONTROL EC 	on (EC.CRITERIANO=OA.CRITERIANO 
				and EC.PTADELAY IN (1, 2) )
	Join CASEEVENT CE	on (CE.CASEID=OA.CASEID
				and CE.EVENTNO=EC.EVENTNO
				and CE.OCCURREDFLAG<9)
	Where OA.CASEID = @pnCaseId
	order by EC.DISPLAYSEQUENCE"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseId	int',
					  @pnCaseId
	Set @pnRowCount=@@RowCount
End
Else
If @ErrorCode=0
and @pbCalledFromCentura = 0
Begin
	If @pnCaseId is not null
	and @pbIsExternalUser is not null
	Begin
		Set @sSQLString="
		Select	distinct
			cast(CE.CASEID as nvarchar(11)) + '^' +
			cast(CE.EVENTNO as nvarchar(11)) + '^' +
			cast(CE.CYCLE as nvarchar(10))
						as RowKey,
			CE.CASEID		as CaseKey,	
			CE.EVENTNO		as EventKey,
			"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+"
						as EventDescription,"+CHAR(10)+
			CASE WHEN @pbIsExternalUser = 0
			     THEN dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura) 
			     ELSE "E.DEFINITION"
			END+"			as EventDefinition,
			CE.EVENTDUEDATE		as EventDueDate,
			CE.EVENTDATE		as EventDate,
			CASE WHEN(EC.PTADELAY = 1)
				THEN	CASE WHEN (CE.EVENTDATE>CE.EVENTDUEDATE)
						THEN DATEDIFF(day, CE.EVENTDUEDATE, CE.EVENTDATE)
						ELSE NULL
					END
				ELSE	NULL
			END 			as IPOfficeDelay,
			CASE WHEN(EC.PTADELAY = 2)
				THEN 	CASE WHEN (CE.EVENTDATE>CE.EVENTDUEDATE)
						THEN DATEDIFF(day, CE.EVENTDUEDATE, CE.EVENTDATE)
						ELSE NULL
					END
				ELSE	NULL
			END 			as ApplicantDelay, 
			EC.DISPLAYSEQUENCE	as DisplaySequence
		From OPENACTION OA
		Join EVENTCONTROL EC 	on (EC.CRITERIANO=OA.CRITERIANO 
					and EC.PTADELAY IN (1, 2) )
		Join CASEEVENT CE	on (CE.CASEID=OA.CASEID
					and CE.EVENTNO=EC.EVENTNO
					and CE.OCCURREDFLAG<9)"+CHAR(10)+
		CASE WHEN @pbIsExternalUser = 0
		     THEN "join EVENTS E		on (E.EVENTNO=CE.EVENTNO)"	
		     WHEN @pbIsExternalUser = 1
		     THEN "join dbo.fn_FilterUserEvents(@pbIsExternalUser, @sLookupCulture, @pbIsExternalUser, @pbCalledFromCentura) E"+char(10)+
			  "				on (E.EVENTNO=CE.EVENTNO)"	     
		END+CHAR(10)+
		"Where OA.CASEID = @pnCaseId
		order by EC.DISPLAYSEQUENCE"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnCaseId		int,
						  @sLookupCulture		nvarchar(10),
						  @pnUserIdentityId	int,
						  @pbIsExternalUser	bit,
						  @pbCalledFromCentura	bit',
						  @pnCaseId		= @pnCaseId,
						  @sLookupCulture	= @sLookupCulture,
						  @pnUserIdentityId	= @pnUserIdentityId,
						  @pbIsExternalUser	= @pbIsExternalUser,
						  @pbCalledFromCentura	= @pbCalledFromCentura
		Set @pnRowCount=@@RowCount
	End
	-- If the CaseKey was not provided suppress then return an empty result set
	Else Begin
		Select	null	as RowKey,
			null	as CaseKey,	
			null	as EventKey,
			null	as EventDescription,
			null	as EventDefinition,
			null	as EventDueDate,
			null	as EventDate,
			null	as IPOfficeDelay,
			null	as ApplicantDelay, 
			null	as DisplaySequence
		where 1=0
		
		Set @pnRowCount=@@RowCount
	End

	
End
go

grant execute on dbo.cs_GetPTA to public
go
