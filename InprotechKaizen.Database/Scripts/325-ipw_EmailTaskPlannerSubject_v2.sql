-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_EmailTaskPlannerSubject
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_EmailTaskPlannerSubject]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_EmailTaskPlannerSubject.'
	drop procedure dbo.ipw_EmailTaskPlannerSubject
end
print '**** Creating procedure dbo.ipw_EmailTaskPlannerSubject...'
print ''
go

create proc dbo.ipw_EmailTaskPlannerSubject 
		@psEntryPoint			varchar(254)	= null, -- Indicates Ad Hoc ('A') or Due Date/Reminder ('C')
		@pnEventOrAlertId		bigint			= null, -- ID of CaseEvent or Alert table
		@pnEmployeeReminderId	bigint			= null, -- ID of EmployeeReminder table
		@pnUserIdentityId		int				= null, -- Identity Id of current user
		@psCulture			nvarchar(10)	= null		-- Culture preference of current user
		
as

-- PROCEDURE :	ipw_EmailTaskPlannerSubject
-- VERSION :	2
-- DESCRIPTION:	Prepares task planner email subject 
-- COPYRIGHT	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26/07/2021	AK		1		Procedure created
-- 19/08/2021	AK		2		used select to return resultset

set nocount on

declare	@ErrorCode int = 0
Declare @sSQLString		nvarchar(max)
Declare @sResultString		nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

/* Extracting Email Subject for Ad Hoc Dates  */
if @ErrorCode = 0 
	AND @psEntryPoint = 'A'
begin
	SET @sSQLString = 'SELECT @sResultString = ''Regarding '' +
						CASE 
							WHEN A.CASEID IS NOT NULL THEN C.IRN
							WHEN A.NAMENO IS NOT NULL THEN dbo.fn_FormatNameUsingNameNo(A.NAMENO, null)
													  ELSE  A.REFERENCE
						END	
						  + '' - Reminder''
						FROM ALERT A WITH(NOLOCK)
						LEFT JOIN CASES C WITH(NOLOCK) ON (A.CASEID = C.CASEID)						
						WHERE A.ID = @pnEventOrAlertId'
	Execute @ErrorCode= sp_executesql @sSQLString,
						N'@pnEventOrAlertId      bigint,
						@sResultString	nvarchar(max) output',
						@pnEventOrAlertId,
						@sResultString output
end

/* Extracting Email Subject for Due Dates  */
if @ErrorCode = 0 
  AND @psEntryPoint = 'C' 
  and @pnEmployeeReminderId is null
begin
		SET @sSQLString = 'SELECT @sResultString =
							''Regarding '' +  C.IRN + '' - '' 
							+ isnull(dbo.fn_GetTranslation(EC.EVENTDESCRIPTION,null,EC.EVENTDESCRIPTION_TID,@sLookupCulture),
									 dbo.fn_GetTranslation(E.EVENTDESCRIPTION,NULL,E.EVENTDESCRIPTION_TID,@sLookupCulture))
							+ '' - Due Date''
							FROM CASEEVENT CE WITH (NOLOCK)
							LEFT JOIN CASES C WITH(NOLOCK) ON (CE.CASEID = C.CASEID)
							left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
							left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																on (OX.CASEID = CE.CASEID and OX.ACTION = E.CONTROLLINGACTION)
							left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))
							WHERE CE.ID = @pnEventOrAlertId and  (CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0)'
		Execute @ErrorCode= sp_executesql @sSQLString,
							N'@pnEventOrAlertId      bigint,
							@sResultString	nvarchar(max) output,
							@sLookupCulture	nvarchar(10)',
							@pnEventOrAlertId,
							@sResultString output,
							@sLookupCulture							

end

/* Extracting Email Subject for Reminders  */

if @ErrorCode = 0  and 
	@psEntryPoint = 'C' 
	and @pnEmployeeReminderId is not null
begin

		SET @sSQLString = 'SELECT  @sResultString =
						''Regarding '' +  C.IRN + '' - '' 
						+ isnull(dbo.fn_GetTranslation(EC.EVENTDESCRIPTION,null,EC.EVENTDESCRIPTION_TID,@sLookupCulture),
									dbo.fn_GetTranslation(E.EVENTDESCRIPTION,NULL,E.EVENTDESCRIPTION_TID,@sLookupCulture))
						+ '' - Reminder''
						FROM EMPLOYEEREMINDER ER WITH (NOLOCK)
						LEFT JOIN CASES C WITH(NOLOCK) ON (ER.CASEID = C.CASEID)
						left join CASEEVENT CE  WITH (NOLOCK) ON (CE.CASEID = ER.CASEID and CE.EVENTNO = ER.EVENTNO and CE.CYCLE = ER.CYCLENO)
						left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
						left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX 
									on (OX.CASEID = CE.CASEID and OX.ACTION = E.CONTROLLINGACTION)
						left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))
						WHERE ER.ID = @pnEmployeeReminderId and (CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0 and ER.SOURCE=0)'
		Execute @ErrorCode= sp_executesql @sSQLString,
							N'@pnEmployeeReminderId   bigint,
							@sResultString	nvarchar(max) output,
							@sLookupCulture	nvarchar(10)',
							@pnEmployeeReminderId,
							@sResultString output,
							@sLookupCulture							

end

if @ErrorCode = 0 
begin
	SELECT @sResultString
end

Return @ErrorCode
go

grant execute on dbo.ipw_EmailTaskPlannerSubject to public
go
