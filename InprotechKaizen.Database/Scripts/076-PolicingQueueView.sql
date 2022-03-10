-----------------------------------------------------------------------------------------------------------------------------
-- Creation of POLICINGQUEUE_VIEW
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[POLICINGQUEUE_VIEW]', 'V'))
Begin
	Print '**** Drop View dbo.POLICINGQUEUE_VIEW.'
	Drop view [dbo].[POLICINGQUEUE_VIEW]
End
Print '**** Creating View dbo.POLICINGQUEUE_VIEW...'
Print ''
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.POLICINGQUEUE_VIEW
as
-- VIEW:	POLICINGQUEUE_VIEW
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	view of the current policing queue

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	----	---			------	-------	----------------------------------------------- 
-- 13 MAY 2016	SF		DR-20787	1		Procedure created
	select
		P.REQUESTID as RequestId,
		case
			when P.ONHOLDFLAG = 9 THEN 'on-hold'
			when P.ONHOLDFLAG in (0, 1) THEN 'waiting-to-start'
			when (E.CASEID is NULL and P.ONHOLDFLAG = 4 and  datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) > 120) then 'failed'
			when (E.CASEID is NULL and P.ONHOLDFLAG in (2,3,4)) then 'in-progress'
			when (E.CASEID is not null) then 'in-error'
		end as [Status],
		P.DATEENTERED as [Requested],
		datediff(SECOND, P.LOGDATETIMESTAMP, getdate()) as [IdleFor],
		case
			when UIN.NAMENO is null
				then P.SQLUSER
				else dbo.fn_FormatName(UIN.NAME,UIN.FIRSTNAME, UIN.TITLE, UIN.NAMESTYLE)
		end as [User],
		case 
			when UIN.NAMENO is null
				then P.SQLUSER
				else cast(P.IDENTITYID as nvarchar(15))
		end as [UserKey],
		P.CASEID as [CaseId],
		C.IRN as [CaseReference],
		P.EVENTNO as [EventId],
		EC.EVENTDESCRIPTION as [EventControlDescription],
		EC.EVENTDESCRIPTION_TID as [EventControlDescriptionTId],
		E1.EVENTDESCRIPTION as [EventDescription],
		E1.EVENTDESCRIPTION_TID as [EventDescriptionTId],
		VA.ACTIONNAME as [ValidActionName],
		VA.ACTIONNAME_TID as [ValidActionNameTId],
		AC.ACTIONNAME as [ActionName],
		AC.ACTIONNAME_TID as [ActionNameTId],
		P.CRITERIANO as [CriteriaId],
		case
			when P.TYPEOFREQUEST=1 then 'open-action'
			when P.TYPEOFREQUEST=2 then 'due-date-changed'
			when P.TYPEOFREQUEST=3 then 'event-occurred'
			when P.TYPEOFREQUEST=4 then 'action-recalculation'
			when P.TYPEOFREQUEST=5 then 'designated-country-change'
			when P.TYPEOFREQUEST=6 then 'due-date-recalculation'
			when P.TYPEOFREQUEST=7 then 'patent-term-adjustment'
			when P.TYPEOFREQUEST=8 then 'document-case-changes'
			when P.TYPEOFREQUEST=9 then 'prior-art-distribution'
			else 'unknown'
	end as [TypeOfRequest]
	from POLICING P
	left join EVENTCONTROL EC on (EC.EVENTNO = P.EVENTNO and EC.CRITERIANO = P.CRITERIANO)
	left join EVENTS E1 ON ( E1.EVENTNO = P.EVENTNO )
	left join CASES C on (P.CASEID = C.CASEID)
	left join COUNTRY CN    on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join VALIDACTION VA
				on (VA.PROPERTYTYPE=C.PROPERTYTYPE
				and VA.CASETYPE    =C.CASETYPE
				and VA.ACTION      =P.ACTION
				and VA.COUNTRYCODE =(   Select MIN(VA1.COUNTRYCODE)
						from VALIDACTION VA1
						where VA1.PROPERTYTYPE=VA.PROPERTYTYPE
						and   VA1.CASETYPE    =VA.CASETYPE
						and   VA1.ACTION      =VA.ACTION
						and   VA1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	left join ACTIONS AC    on (AC.ACTION=P.ACTION
				and VA.ACTION is null)        -- Only if Valid row cannot be found
	left join (select distinct CASEID
				from POLICINGERRORS PE
				where PE.LOGDATETIMESTAMP >=( Select MIN(P1.DATEENTERED)
						from POLICING P1
						where PE.CASEID = P1.CASEID
						and P1.SYSGENERATEDFLAG=1
						and P1.ONHOLDFLAG between 2 and 4)
					) E on (E.CASEID=P.CASEID and P.ONHOLDFLAG between 2 and 4)

	left join USERIDENTITY UI on (P.IDENTITYID = UI.IDENTITYID)
	left join NAME UIN on (UI.NAMENO = UIN.NAMENO)
	where P.SYSGENERATEDFLAG=1

GO

Grant REFERENCES, SELECT on dbo.POLICINGQUEUE_VIEW to public
GO

sp_refreshview 'dbo.POLICINGQUEUE_VIEW'
GO