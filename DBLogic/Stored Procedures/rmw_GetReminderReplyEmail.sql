-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_GetReminderReplyEmail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_GetReminderReplyEmail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_GetReminderReplyEmail.'
	Drop procedure [dbo].[rmw_GetReminderReplyEmail]
End
Print '**** Creating Stored Procedure dbo.rmw_GetReminderReplyEmail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rmw_GetReminderReplyEmail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnReminderForKey	int,
	@pdtReminderDateCreated datetime
)
as
-- PROCEDURE:	rmw_GetReminderReplyEmail
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure retrieves reminder reply email for Reminders application in the WorkBenches.
--

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 DEC 2009	SF	RFC5803	1	Procedure created
-- 17 Sep 2010	MF	RFC9777	2	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sLookupCulture nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	
	Set @sSQLString = "
		Select DISTINCT
			SC.COLCHARACTER							as 'EmailAddress',
			C.IRN									as 'CaseReference',
			ER.SHORTMESSAGE							as 'Message', 
			"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CC',@sLookupCulture,0) +" as 'CountryAdjective', 
			ISNULL("+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) +","
			+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,0) +") as 'PropertyTypeDescription',
			C.CURRENTOFFICIALNO						as 'CurrentOfficialNumber',
			ISNULL("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,0) +","
			+dbo.fn_SqlTranslatedColumn('[EVENTS]','EVENTDESCRIPTION',null,'E',@sLookupCulture,0) +") as 'EventDescription',
			ISNULL(CE.EVENTDUEDATE, ER.DUEDATE)		as 'DueDate',
			cast(case when CE.EVENTNO is null then 1 else 0 end	as bit)									
													as 'IsAdHocReminder',
			cast(isnull(CE.DATEDUESAVED, 0) as bit) as 'IsEnteredDueDate',
			"+dbo.fn_SqlTranslatedColumn('[EVENTS]','EVENTDESCRIPTION',null,'E1',@sLookupCulture,0) + " as 'GoverningEventDescription', 
			CE1.EVENTDATE							as 'GoverningEventDate', 
			"+dbo.fn_SqlTranslatedColumn('CASEEVENT','EVENTTEXT',null,'CE',@sLookupCulture,0) +" as 'EventText' 
		from EMPLOYEEREMINDER ER 
		left join SITECONTROL SC   on (SC.CONTROLID = 'Reminder Reply Email')
		left join CASES C	   on (C.CASEID = ER.CASEID)
		left join COUNTRY CC	   on (C.COUNTRYCODE = CC.COUNTRYCODE)
		left join PROPERTYTYPE P   on (P.PROPERTYTYPE=C.PROPERTYTYPE)
		left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=P.PROPERTYTYPE
						and VP.COUNTRYCODE =(select min(VP1.COUNTRYCODE)
						from VALIDPROPERTY VP1
						where VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE))) 
		left join CASEEVENT CE	on (CE.CASEID = ER.CASEID
					and CE.EVENTNO = ER.EVENTNO
					and CE.CYCLE = ER.CYCLENO)
		left join [EVENTS] E	on (E.EVENTNO = CE.EVENTNO) 
		left join OPENACTION OA	on (OA.CASEID = CE.CASEID
					and OA.ACTION = E.CONTROLLINGACTION)							
		left join EVENTCONTROL EC  
					on (EC.EVENTNO = CE.EVENTNO
					and EC.CRITERIANO = isnull(OA.CRITERIANO,CE.CREATEDBYCRITERIA))
		left join CASEEVENT CE1	on (CE1.CASEID=CE.CASEID
					and CE1.EVENTNO=CE.GOVERNINGEVENTNO
					and CE1.CYCLE=(	select max(CE2.CYCLE)
							from CASEEVENT CE2
							where CE2.CASEID=CE.CASEID
							and CE2.EVENTNO=CE.GOVERNINGEVENTNO
							and CE2.EVENTDATE is not null))									
		left join [EVENTS] E1	on (E1.EVENTNO = CE.GOVERNINGEVENTNO)
		where ER.MESSAGESEQ = @pdtReminderDateCreated
		and ER.EMPLOYEENO = @pnReminderForKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pdtReminderDateCreated	datetime,
				@pnReminderForKey int',
			@pdtReminderDateCreated	= @pdtReminderDateCreated,
			@pnReminderForKey		= @pnReminderForKey
End

Return @nErrorCode
GO

Grant execute on dbo.rmw_GetReminderReplyEmail to public
GO
