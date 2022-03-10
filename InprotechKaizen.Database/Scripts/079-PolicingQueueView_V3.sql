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

CREATE VIEW [dbo].[POLICINGQUEUE_VIEW]
as
-- VIEW:	POLICINGQUEUE_VIEW
-- VERSION:	1.1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	view of the current policing queue

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	----	---			------	-------	----------------------------------------------- 
-- 13 MAY 2016	SF		DR-20787	1		Procedure created
-- 31 MAY 2016	HM		DR-18866	2		Columns selection for Law Update Service
-- 15 JUN 2016	HM		DR-21255	3		Blockd status added, Cycle Column added		
	select
		P.REQUESTID as RequestId,
		case
			when P.ONHOLDFLAG = 9 THEN 'on-hold'
			when (P.ONHOLDFLAG=0 and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is not null) then 'blocked'
			when (P.ONHOLDFLAG in (0, 1) and COALESCE(P1.CASEID,P2.CASEID,P3.CASEID) is null) THEN 'waiting-to-start'
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
		CR.DESCRIPTION as [CriteriaDescription],
		CR.DESCRIPTION_TID as [CriteriaDescriptionTId],
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
	end as [TypeOfRequest],
	PTLAW.PROPERTYNAME as [PROPERTYNAME],
	PTLAW.PROPERTYNAME_TID as [PROPERTYNAMETId],
	CLAW.COUNTRY as [Jurisdiction],
	CLAW.COUNTRY_TID as [JurisdictionTId],
	p.SCHEDULEDDATETIME as [SCHEDULEDDATETIME],
	p.POLICINGNAME,
	p.CYCLE
	from POLICING P
	left join EVENTCONTROL EC on (EC.EVENTNO = P.EVENTNO and EC.CRITERIANO = P.CRITERIANO)
	left join EVENTS E1 ON ( E1.EVENTNO = P.EVENTNO )
	left join CASES C with(nolock) on (P.CASEID = C.CASEID)
	left join COUNTRY CN    on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join PROPERTYTYPE PTLAW on (PTLAW.PROPERTYTYPE=P.PROPERTYTYPE)
	left join COUNTRY CLAW on (CLAW.COUNTRYCODE=p.COUNTRYCODE)
	left join CRITERIA CR on P.CRITERIANO=CR.CRITERIANO
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
	-----------------------------------
-- Looking for BLOCKING rows caused
-- by an Action to be opened
-----------------------------------
left join (Select DISTINCT CASEID
	   from POLICING
	   where TYPEOFREQUEST=1
	   and SYSGENERATEDFLAG=1
	   and BATCHNO is null) P1	on (P1.CASEID=P.CASEID
					and P.ONHOLDFLAG=0
					and P.TYPEOFREQUEST<>1)

-----------------------------------
-- If the Case to be processed has
-- already commenced processing 
-- then this will block requests
-- for the same Case
-----------------------------------
left join (Select DISTINCT CASEID
	   from POLICING
	   where ONHOLDFLAG<>9
	   and SYSGENERATEDFLAG<>0
	   and SPIDINPROGRESS is not null) P2
					on (P2.CASEID=P.CASEID
					and P.ONHOLDFLAG=0)

-----------------------------------
-- if multiple Users have issued a 
-- request against the same Case
-- then TYPEOFREQUEST=1 requests
-- process first, otherwise the 
-- earlier request of a different
-- user will block a row from being
-- processed.
-----------------------------------
left join (Select CASEID, IDENTITYID, MIN(DATEENTERED) as DATEENTERED, MIN(TYPEOFREQUEST) as TYPEOFREQUEST
	   from	POLICING
	   where ONHOLDFLAG<3
	   and SYSGENERATEDFLAG>0
	   group by CASEID, IDENTITYID) P3	
					on (P3.CASEID     =P.CASEID
					and P3.IDENTITYID<>P.IDENTITYID
					and P3.DATEENTERED<P.DATEENTERED
					and(P3.TYPEOFREQUEST=1 and P.TYPEOFREQUEST=1 OR (P.TYPEOFREQUEST>1))
					and P.ONHOLDFLAG  =0)

	where P.SYSGENERATEDFLAG=1

GO

Grant REFERENCES, SELECT on dbo.POLICINGQUEUE_VIEW to public
GO

sp_refreshview 'dbo.POLICINGQUEUE_VIEW'
GO