-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_EmailTaskPlannerBody
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_EmailTaskPlannerBody]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_EmailTaskPlannerBody.'
	drop procedure dbo.ipw_EmailTaskPlannerBody
end
print '**** Creating procedure dbo.ipw_EmailTaskPlannerBody...'
print ''
go

create proc dbo.ipw_EmailTaskPlannerBody 
		@psEntryPoint			varchar(254)	= null,  -- Indicates Ad Hoc ('A') or Due Date/Reminder ('C')
		@pnEventOrAlertId		bigint			= null,	 -- ID of CaseEvent or Alert table
		@pnEmployeeReminderId	bigint			= null,	 -- ID of EmployeeReminder table
		@pnUserIdentityId		int				= null,	 -- Identity Id of current user
		@psCulture			nvarchar(10)	= null		 -- Culture preference of current user
		
as

-- PROCEDURE :	ipw_EmailTaskPlannerBody
-- VERSION :	3
-- DESCRIPTION:	Prepares task planner email body
-- COPYRIGHT	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26/07/2021	AK		1		Procedure created
-- 16/08/2021	LS		2		Used country adjective instead of country name
-- 19/08/2021	AK		3		used select to return resultset

set nocount on

declare	@ErrorCode int = 0

Declare @sLookupCulture		nvarchar(10)
Declare @sSQLString		nvarchar(max)
Declare @sResultString		nvarchar(max)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

/* Extracting Email Body for Ad Hoc Dates  */
if @psEntryPoint = 'A'
begin
	SET @sSQLString = '
			SELECT  @sResultString =
			CASE 
				WHEN A.CASEID IS NOT NULL THEN
					dbo.fn_GetTranslation(CO.COUNTRYADJECTIVE, null,CO.COUNTRYADJECTIVE_TID,@sLookupCulture) + '' '' + VP.PROPERTYNAME 
					+ case 
						when o.OFFICIALNUMBER is not null then '' - '' + o.OFFICIALNUMBER	
						else '''' 
						end	 
				WHEN A.NAMENO IS NOT NULL THEN
					dbo.fn_FormatNameUsingNameNo(A.NAMENO, null)
				ELSE 
					A.REFERENCE
			END  +  char(10) +
			''Reminder: '' + isnull(A.ALERTMESSAGE,'''') + char(10) +
			''Due on: '' + convert(nvarchar(30), A.DUEDATE, 106)  + char(10)
			FROM ALERT A WITH(NOLOCK)
			LEFT JOIN CASES C WITH(NOLOCK) ON (A.CASEID = C.CASEID)
			LEFT JOIN COUNTRY CO WITH(NOLOCK) ON (CO.COUNTRYCODE =  C.COUNTRYCODE)
			left Join VALIDPROPERTY VP with (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE
									 and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)
														   from VALIDPROPERTY VP1 with (NOLOCK)
														   where VP1.PROPERTYTYPE=C.PROPERTYTYPE
														   and   VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ''))) 		
			left join OFFICIALNUMBERS O on (O.CASEID=C.CASEID and O.ISCURRENT=1 
											and O.NUMBERTYPE=(select max(NUMBERTYPE) from OFFICIALNUMBERS O1
											where O1.CASEID=C.CASEID and O1.ISCURRENT=1 and O1.NUMBERTYPE in (''0'',''A'',''C'',''R'',''P'')))     
			WHERE A.ID = @pnEventOrAlertId'
	Execute @ErrorCode = sp_executesql @sSQLString,
							N'@pnEventOrAlertId      bigint,
							@sResultString	nvarchar(max) output,
							@sLookupCulture	nvarchar(10)',
							@pnEventOrAlertId,
							@sResultString output,
							@sLookupCulture		
	
end

/* Extracting Email Body for Due Dates  */
if @ErrorCode = 0 
	and @psEntryPoint = 'C' 
	and @pnEmployeeReminderId is null
begin
	SET @sSQLString = '
					SELECT  @sResultString =
					dbo.fn_GetTranslation(CO.COUNTRYADJECTIVE, null,CO.COUNTRYADJECTIVE_TID,@sLookupCulture) + '' '' + VP.PROPERTYNAME
					+ case 
						when o.OFFICIALNUMBER is not null then '' - '' + o.OFFICIALNUMBER	
						else '''' 
						end	 
					+ char(10) + 
					''For Event: '' + isnull(dbo.fn_GetTranslation(EC.EVENTDESCRIPTION,null,EC.EVENTDESCRIPTION_TID,@sLookupCulture),
											dbo.fn_GetTranslation(E.EVENTDESCRIPTION,NULL,E.EVENTDESCRIPTION_TID,@sLookupCulture)) +  char(10) +
					''Due on: '' +  convert(nvarchar(30), CE.EVENTDUEDATE, 106)  + char(10) +
					case
                         when Ge.EVENTDESCRIPTION is not null then
							''(Arising from: '' + dbo.fn_GetTranslation(GE.EVENTDESCRIPTION,null,GE.EVENTDESCRIPTION_TID,@sLookupCulture)  + '' on '' + convert(nvarchar(30), isnull(CE1.EVENTDATE, CE1.EVENTDUEDATE), 106) + '')'' 
					else '''' end  + CHAR(10)
					FROM CASEEVENT CE WITH (NOLOCK)
					LEFT JOIN CASES C WITH(NOLOCK) ON (CE.CASEID = C.CASEID)
					LEFT JOIN COUNTRY CO WITH(NOLOCK) ON (CO.COUNTRYCODE =  C.COUNTRYCODE)
					left Join VALIDPROPERTY VP with (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE
											 and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)
																   from VALIDPROPERTY VP1 with (NOLOCK)
																   where VP1.PROPERTYTYPE=C.PROPERTYTYPE
																   and   VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ'')))		
					left join OFFICIALNUMBERS O on (O.CASEID=C.CASEID and O.ISCURRENT=1 
												and O.NUMBERTYPE=(select max(NUMBERTYPE) from OFFICIALNUMBERS O1
												where O1.CASEID=C.CASEID and O1.ISCURRENT=1 and O1.NUMBERTYPE in (''0'',''A'',''C'',''R'',''P'')))  
					left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
					left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
														on (OX.CASEID = CE.CASEID and OX.ACTION = E.CONTROLLINGACTION)
					left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))
					LEFT JOIN CASEEVENT CE1 WITH(NOLOCK) ON (CE1.CASEID = CE.CASEID AND CE1.EVENTNO = CE.GOVERNINGEVENTNO)
					LEFT JOIN EVENTS GE WITH (NOLOCK) ON (CE.GOVERNINGEVENTNO = GE.EVENTNO)
					WHERE CE.ID = @pnEventOrAlertId and  (CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0)'
	Execute @ErrorCode = sp_executesql @sSQLString,
						N'@pnEventOrAlertId      bigint,
						@sResultString	nvarchar(max) output,
						@sLookupCulture	nvarchar(10)',
						@pnEventOrAlertId,
						@sResultString output,
						@sLookupCulture						

end

/* Extracting Email Body for Reminders  */
if @ErrorCode = 0 
	and @psEntryPoint = 'C' 
	and @pnEmployeeReminderId is not null
begin
	SET @sSQLString = '
					SELECT  @sResultString =
					dbo.fn_GetTranslation(CO.COUNTRYADJECTIVE, null,CO.COUNTRYADJECTIVE_TID,@sLookupCulture) + '' '' + VP.PROPERTYNAME
					+  case 
						when o.OFFICIALNUMBER is not null then '' - '' + o.OFFICIALNUMBER	
						else '''' 
						end	 
					+ char(10) + 
					''Reminder: '' + isnull(ER.SHORTMESSAGE, ER.LONGMESSAGE) + char(10) +
					''For Event: '' + isnull(dbo.fn_GetTranslation(EC.EVENTDESCRIPTION,null,EC.EVENTDESCRIPTION_TID,@sLookupCulture),
											dbo.fn_GetTranslation(E.EVENTDESCRIPTION,NULL,E.EVENTDESCRIPTION_TID,@sLookupCulture)) +  char(10) +
					''Due on: '' +  convert(nvarchar(30), ER.DUEDATE, 106)  + char(10) +
					case
                         when Ge.EVENTDESCRIPTION is not null then
							''(Arising from: '' + dbo.fn_GetTranslation(GE.EVENTDESCRIPTION,null,GE.EVENTDESCRIPTION_TID,@sLookupCulture)  + '' on '' + convert(nvarchar(30), isnull(CE1.EVENTDATE, CE1.EVENTDUEDATE), 106) + '')'' 
					else '''' end  + CHAR(10)
					
					FROM EMPLOYEEREMINDER ER WITH (NOLOCK)
					LEFT JOIN CASES C WITH(NOLOCK) ON (ER.CASEID = C.CASEID)
					LEFT JOIN COUNTRY CO WITH(NOLOCK) ON (CO.COUNTRYCODE =  C.COUNTRYCODE)
					left Join VALIDPROPERTY VP with (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE
											 and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)
																   from VALIDPROPERTY VP1 with (NOLOCK)
																   where VP1.PROPERTYTYPE=C.PROPERTYTYPE
																   and   VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ'')))		
					left join OFFICIALNUMBERS O on (O.CASEID=C.CASEID and O.ISCURRENT=1 
												and O.NUMBERTYPE=(select max(NUMBERTYPE) from OFFICIALNUMBERS O1
												where O1.CASEID=C.CASEID and O1.ISCURRENT=1 and O1.NUMBERTYPE in (''0'',''A'',''C'',''R'',''P''))) 
					left join CASEEVENT CE  WITH (NOLOCK) ON (CE.CASEID = ER.CASEID and CE.EVENTNO = ER.EVENTNO and CE.CYCLE = ER.CYCLENO)
					left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
					left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX 
								on (OX.CASEID = CE.CASEID and OX.ACTION = E.CONTROLLINGACTION)
					left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))
					LEFT JOIN CASEEVENT CE1 WITH(NOLOCK) ON (CE1.CASEID = CE.CASEID AND CE1.EVENTNO = CE.GOVERNINGEVENTNO)
					LEFT JOIN EVENTS GE WITH (NOLOCK) ON (CE.GOVERNINGEVENTNO = GE.EVENTNO)
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

grant execute on dbo.ipw_EmailTaskPlannerBody to public
go
