-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_GetEventReminderSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_GetEventReminderSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_GetEventReminderSummary.'
	Drop procedure [dbo].[rmw_GetEventReminderSummary]
End
Print '**** Creating Stored Procedure dbo.rmw_GetEventReminderSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rmw_GetEventReminderSummary
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit	= 0,
	@pnEmployeeKey			int,
	@pdtReminderDateCreated	datetime
)
as
-- PROCEDURE:	rmw_GetEventReminderSummary
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return governing event and event text

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 FEB 2011	SF	9824	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)
declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	
		ER.EMPLOYEENO			as 'ReminderForKey',
		ER.MESSAGESEQ			as 'ReminderDateCreated',
		isnull("+
		dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura) + 
		","+
		dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) 
		+")						as 'GoverningEventDescription',
		isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE) as 'GoverningEventDate'
	from EMPLOYEEREMINDER ER
	join CASEEVENT CE		on (CE.CASEID=ER.CASEID
					and CE.EVENTNO=ER.EVENTNO
					and CE.CYCLE=ER.CYCLENO)
	left join CASEEVENT CE1		on (CE1.CASEID=CE.CASEID
					and CE1.EVENTNO=CE.GOVERNINGEVENTNO
					and CE1.CYCLE=(	select max(CE2.CYCLE)
							from CASEEVENT CE2
							where CE2.CASEID=CE1.CASEID
							and CE2.EVENTNO=CE1.EVENTNO
							and CE2.EVENTDATE is not null))
	left join EVENTS E			on (E.EVENTNO=CE1.EVENTNO)
	left join OPENACTION OA		on (OA.CASEID=CE1.CASEID
					and OA.ACTION=E.CONTROLLINGACTION
					and OA.CYCLE=(	select max(OA1.CYCLE)
							from OPENACTION OA1
							where OA1.CASEID=OA.CASEID
							and OA1.ACTION=OA.ACTION))
	left join EVENTCONTROL EC		on (EC.CRITERIANO=isnull(OA.CRITERIANO,CE1.CREATEDBYCRITERIA)
					and EC.EVENTNO=E.EVENTNO)							
	where 				ER.EMPLOYEENO = @pnEmployeeKey
					and   ER.MESSAGESEQ = @pdtReminderDateCreated
	"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnEmployeeKey			int,
				  @pdtReminderDateCreated	datetime',
				  @pnEmployeeKey			= @pnEmployeeKey,
				  @pdtReminderDateCreated	= @pdtReminderDateCreated

End

Return @nErrorCode
GO

Grant execute on dbo.rmw_GetEventReminderSummary to public
GO
