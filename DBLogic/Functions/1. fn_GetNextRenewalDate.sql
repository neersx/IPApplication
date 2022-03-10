-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetNextRenewalDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetNextRenewalDate') )
Begin
	Print '**** Drop Function dbo.fn_GetNextRenewalDate'
	Drop function [dbo].[fn_GetNextRenewalDate]
End
Print '**** Creating Function dbo.fn_GetNextRenewalDate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE FUNCTION dbo.fn_GetNextRenewalDate (	@pbUseHighestCycle		bit=0) 
RETURNS TABLE

AS
-- Function :	fn_GetNextRenewalDate
-- VERSION :	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the next renewal date, cycle and annuity for the Case taking into consideration CPA dates as well.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 29 Dec 2014	MF	R42684	1	Function created by moving code from stored proc cs_GetNextRenewalDate
-- 14 Jan 2015	MF	R34753	2	The CPA Renewal Date should not be returned if the CPA Start Pay Date is
--					a future date and the Inprotech NRD is earlier than the CPA Start Pay Date.
-- 22 Dec 2015	MF	R56554	3	The CPA Renewal Date should also not be returned if the Inprotech NRD is 
--					later than the CPA Stop Pay Date.
-- 26 Apr 2016	MF	R60825	4	Only return a CPA Renewal Date if the Case is flagged as reportable to CPA.
-- 08 Nov 2018  AV  75198/DR-45358	5   Date conversion errors when creating cases and opening names in Chinese DB

RETURN
	select	C.CASEID				as CASEID,	
		ST.EVENTDATE				as RENEWALSTARTDATE,
		isnull(CE.EVENTDATE, CE.EVENTDUEDATE)	as NEXTRENEWALDATE,
		OA.CYCLE				as CYCLE,
		
		---------------------------------------------------------
		-- If CPA Start Pay Date is in the future and Inprotech's 
		-- NRD is earlier than the CPA Start Pay Date, or if
		-- Inprotech's NRD is later than CPA Stop Pay Date then do 
		-- not return the CPA Renewal Date at this time
		---------------------------------------------------------
		CASE WHEN(CPA.CPARENEWALDATE='18010101') -- '01-JAN-1801'
			THEN NULL
			-------------------------------------------------
			-- CPA Start Date is in the future and
			-- Inprotech NRD is earlier than the Start Date
			-- then do not return the CPA Renewal Date
			-------------------------------------------------
		     WHEN(isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)>GETDATE()
		      and isnull( CE.EVENTDATE, CE.EVENTDUEDATE)<isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE))
			THEN NULL
			-------------------------------------------------
			-- CPA Stop Date is in the past and the
			-- Inprotech NRD is after the Stop Date
			-- then do not return the CPA Renewal Date
			-------------------------------------------------
		     WHEN(CE2.EVENTDATE<GETDATE()
		      and isnull( CE.EVENTDATE, CE.EVENTDUEDATE)>CE2.EVENTDATE)
			THEN NULL
		
			ELSE CPA.CPARENEWALDATE 
		END					as CPARENEWALDATE, 
		
		isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)	as CPASTARTPAYDATE,
		
		CASE WHEN( EV.ANNUITY>0
		      and (CE1.CASEID IS NULL OR CE1.EVENTDATE<GETDATE())			    -- CPA Start Date is in the past or not defined
		      and (CE2.CASEID IS NULL OR isnull(CE2.EVENTDATE, CE2.EVENTDUEDATE)>GETDATE()) -- CPA Stop Date is in the future or not defined	
		          )
			THEN EV.ANNUITY
			ELSE
				CASE(VP.ANNUITYTYPE)
					WHEN(0) THEN NULL
					WHEN(1) THEN 
						CASE WHEN(datepart(m,ST.EVENTDATE)=datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))+1
						       or(datepart(m,ST.EVENTDATE)=1 and datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))=12))
						       THEN floor(datediff(mm,ST.EVENTDATE, isnull(CE.EVENTDATE, CE.EVENTDUEDATE))/11) + ISNULL(VP.OFFSET, 0)
						     WHEN( datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))=1 
						       and datepart(d,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))=1
						       and datepart(m,ST.EVENTDATE)<>datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE)) )
						       THEN datediff(yy,ST.EVENTDATE, isnull(CE.EVENTDATE, CE.EVENTDUEDATE)) + ISNULL(VP.OFFSET, 0)
						       ELSE floor(datediff(mm,ST.EVENTDATE, isnull(CE.EVENTDATE, CE.EVENTDUEDATE))/12) + ISNULL(VP.OFFSET, 0)
						END
					WHEN(2) THEN OA.CYCLE+isnull(VP.CYCLEOFFSET,0)
				END
		END as ANNUITY
	from CASES C
	left Join (	select max(O.CYCLE) as [CYCLE], O.CASEID
			from OPENACTION O
			join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
			where O.ACTION=SC.COLCHARACTER
			and O.POLICEEVENTS=1
			group by O.CASEID) OA on (OA.CASEID=C.CASEID)
	left Join CASEEVENT CE	on (CE.CASEID = OA.CASEID
				and CE.EVENTNO = -11
				and CE.CYCLE=OA.CYCLE)
	left Join CASEEVENT ST	on (ST.CASEID = OA.CASEID
				and ST.EVENTNO = -9
				and ST.CYCLE=1)
		--------------------------------------------------
		-- Get the CPA Start Pay Date 
		--------------------------------------------------
	left Join SITECONTROL S	on (S.CONTROLID='CPA Date-Start')
	left Join CASEEVENT CE1 on (CE1.CASEID =C.CASEID
				and CE1.EVENTNO=S.COLINTEGER
				and CE1.CYCLE  =1)	
		--------------------------------------------------
		-- Get the CPA Stop Pay Date 
		--------------------------------------------------
	left Join SITECONTROL P	on (P.CONTROLID='CPA Date-Stop')
	left Join CASEEVENT CE2 on (CE2.CASEID =C.CASEID
				and CE2.EVENTNO=P.COLINTEGER
				and CE2.CYCLE  =1)				
		-------------------------------------------------------------------------------------		
		-- The CPA Renewal Date is determined from the latest record available in the 3 files
		-- that CPA provide in the interface.  It is possible for there to be no Renewal Date
		-- in which case a date of 01 Jan 1801 is used in the calculation to avoid a 
		-- Null Eliminated warning message.
		-------------------------------------------------------------------------------------
	left join (	Select C1.CASEID, convert(datetime,substring(max(convert(char(8),isnull(P.ASATDATE,'18010101'),112)+convert(char(8),isnull(P.NEXTRENEWALDATE,'18010101'),112)),9,8)) as CPARENEWALDATE
			from CASES C1
			left Join (	select DATEOFPORTFOLIOLST as ASATDATE, NEXTRENEWALDATE, CASEID
					from CPAPORTFOLIO
					where STATUSINDICATOR='L'
					and NEXTRENEWALDATE is not null
					and TYPECODE not in ('A1','A6','AF','CI','CN','DE','DI','NW','SW')
					UNION ALL
					select EVENTDATE, NEXTRENEWALDATE, CASEID
					from CPAEVENT
					UNION ALL
					select BATCHDATE, RENEWALDATE, CASEID
					from CPARECEIVE
					where IPRURN is not null
					and NARRATIVE not like 'NON-RELEVANT AMEND%') P on (P.CASEID=C1.CASEID)
			group by C1.CASEID) CPA on (CPA.CASEID=C.CASEID
						and C.REPORTTOTHIRDPARTY=1)
		----------------------------------------
		-- The Annuity that CPA have determined.
		----------------------------------------
	left join CPAEVENT EV	on (EV.CEFNO=(	Select MAX(EV1.CEFNO)
						from CPAEVENT EV1
						where EV1.CASEID=C.CASEID
						and EV1.ANNUITY is not null
						and EV1.NEXTRENEWALDATE=CPA.CPARENEWALDATE
						and EV.TYPECODE<>'TM'))	
	left join VALIDPROPERTY VP	
				on (VP.PROPERTYTYPE = C.PROPERTYTYPE
				and VP.COUNTRYCODE  = (	select min(VP1.COUNTRYCODE)
							from VALIDPROPERTY VP1
							where VP1.PROPERTYTYPE=C.PROPERTYTYPE
							and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	Where @pbUseHighestCycle=1
	UNION ALL
	select	C.CASEID				as CASEID,
		ST.EVENTDATE				as RENEWALSTARTDATE,	
		isnull(CE.EVENTDATE, CE.EVENTDUEDATE)	as NEXTRENEWALDATE,
		OA.CYCLE				as CYCLE,
		
		---------------------------------------------------------
		-- If CPA Start Pay Date is in the future and Inprotech's 
		-- NRD is earlier than the CPA Start Pay Date, or if
		-- Inprotech's NRD is later than CPA Stop Pay Date then do 
		-- not return the CPA Renewal Date at this time
		---------------------------------------------------------
		CASE WHEN(CPA.CPARENEWALDATE= '18010101') --'01-JAN-1801'
			THEN NULL
			-------------------------------------------------
			-- CPA Start Date is in the future and
			-- Inprotech NRD is earlier than the Start Date
			-- then do not return the CPA Renewal Date
			-------------------------------------------------
		     WHEN(isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)>GETDATE()
		      and isnull( CE.EVENTDATE, CE.EVENTDUEDATE)<isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE))
			THEN NULL
			-------------------------------------------------
			-- CPA Stop Date is in the past and the
			-- Inprotech NRD is after the Stop Date
			-- then do not return the CPA Renewal Date
			-------------------------------------------------
		     WHEN(CE2.EVENTDATE<GETDATE()
		      and isnull( CE.EVENTDATE, CE.EVENTDUEDATE)>CE2.EVENTDATE)
			THEN NULL
			ELSE CPA.CPARENEWALDATE 
		END					as CPARENEWALDATE,
		
		isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)	as CPASTARTPAYDATE,
		
		CASE WHEN( EV.ANNUITY>0
		      and (CE1.CASEID IS NULL OR CE1.EVENTDATE<GETDATE())			    -- CPA Start Date is in the past or not defined
		      and (CE2.CASEID IS NULL OR isnull(CE2.EVENTDATE, CE2.EVENTDUEDATE)>GETDATE()) -- CPA Stop Date is in the future or not defined	
		          )
			THEN EV.ANNUITY
			ELSE
				CASE(VP.ANNUITYTYPE)
					WHEN(0) THEN NULL
					WHEN(1) THEN 
						CASE WHEN(datepart(m,ST.EVENTDATE)=datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))+1
						       or(datepart(m,ST.EVENTDATE)=1 and datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))=12))
						       THEN floor(datediff(mm,ST.EVENTDATE, isnull(CE.EVENTDATE, CE.EVENTDUEDATE))/11) + ISNULL(VP.OFFSET, 0)
						     WHEN( datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))=1 
						       and datepart(d,isnull(CE.EVENTDATE, CE.EVENTDUEDATE))=1
						       and datepart(m,ST.EVENTDATE)<>datepart(m,isnull(CE.EVENTDATE, CE.EVENTDUEDATE)) )
						       THEN datediff(yy,ST.EVENTDATE, isnull(CE.EVENTDATE, CE.EVENTDUEDATE)) + ISNULL(VP.OFFSET, 0)
						       ELSE floor(datediff(mm,ST.EVENTDATE, isnull(CE.EVENTDATE, CE.EVENTDUEDATE))/12) + ISNULL(VP.OFFSET, 0)
						END
					WHEN(2) THEN OA.CYCLE+isnull(VP.CYCLEOFFSET,0)
				END
		END as ANNUITY
	from CASES C
	left Join (	select min(O.CYCLE) as [CYCLE], O.CASEID
			from OPENACTION O
			join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')
			where O.ACTION=SC.COLCHARACTER
			and O.POLICEEVENTS=1
			group by O.CASEID) OA on (OA.CASEID=C.CASEID)
	left Join CASEEVENT CE	on (CE.CASEID = OA.CASEID
				and CE.EVENTNO = -11
				and CE.CYCLE=OA.CYCLE)
	left Join CASEEVENT ST	on (ST.CASEID = OA.CASEID
				and ST.EVENTNO = -9
				and ST.CYCLE=1)
		--------------------------------------------------
		-- Get the CPA Start Pay Date 
		--------------------------------------------------
	left Join SITECONTROL S	on (S.CONTROLID='CPA Date-Start')
	left Join CASEEVENT CE1 on (CE1.CASEID =C.CASEID
				and CE1.EVENTNO=S.COLINTEGER
				and CE1.CYCLE  =1)	
		--------------------------------------------------
		-- Get the CPA Stop Pay Date 
		--------------------------------------------------
	left Join SITECONTROL P	on (P.CONTROLID='CPA Date-Stop')
	left Join CASEEVENT CE2 on (CE2.CASEID =C.CASEID
				and CE2.EVENTNO=P.COLINTEGER
				and CE2.CYCLE  =1)	
		-------------------------------------------------------------------------------------		
		-- The CPA Renewal Date is determined from the latest record available in the 3 files
		-- that CPA provide in the interface.  It is possible for there to be no Renewal Date
		-- in which case a date of 01 Jan 1801 is used in the calculation to avoid a 
		-- Null Eliminated warning message.
		-------------------------------------------------------------------------------------
	left join (	Select C1.CASEID, convert(datetime,substring(max(convert(char(8),isnull(P.ASATDATE,'18010101'),112)+convert(char(8),isnull(P.NEXTRENEWALDATE,'18010101'),112)),9,8)) as CPARENEWALDATE
			from CASES C1
			left Join (	select DATEOFPORTFOLIOLST as ASATDATE, NEXTRENEWALDATE, CASEID
					from CPAPORTFOLIO
					where STATUSINDICATOR='L'
					and NEXTRENEWALDATE is not null
					and TYPECODE not in ('A1','A6','AF','CI','CN','DE','DI','NW','SW')
					UNION ALL
					select EVENTDATE, NEXTRENEWALDATE, CASEID
					from CPAEVENT
					UNION ALL
					select BATCHDATE, RENEWALDATE, CASEID
					from CPARECEIVE
					where IPRURN is not null
					and NARRATIVE not like 'NON-RELEVANT AMEND%') P on (P.CASEID=C1.CASEID)
			group by C1.CASEID) CPA on (CPA.CASEID=C.CASEID
						and C.REPORTTOTHIRDPARTY=1)
		----------------------------------------
		-- The Annuity that CPA have determined.
		----------------------------------------
	left join CPAEVENT EV	on (EV.CEFNO=(	Select MAX(EV1.CEFNO)
						from CPAEVENT EV1
						where EV1.CASEID=C.CASEID
						and EV1.ANNUITY is not null
						and EV1.NEXTRENEWALDATE=CPA.CPARENEWALDATE
						and EV.TYPECODE<>'TM'))		
	left join VALIDPROPERTY VP	
				on (VP.PROPERTYTYPE = C.PROPERTYTYPE
				and VP.COUNTRYCODE  = (	select min(VP1.COUNTRYCODE)
							from VALIDPROPERTY VP1
							where VP1.PROPERTYTYPE=C.PROPERTYTYPE
							and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))		
	Where isnull(@pbUseHighestCycle,0)=0
GO

grant REFERENCES, SELECT on dbo.fn_GetNextRenewalDate to public
go
