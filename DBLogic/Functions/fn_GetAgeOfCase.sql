-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetAgeOfCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetAgeOfCase') )
Begin
	Print '**** Drop Function dbo.fn_GetAgeOfCase'
	Drop function [dbo].[fn_GetAgeOfCase]
End
Print '**** Creating Function dbo.fn_GetAgeOfCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE FUNCTION dbo.fn_GetAgeOfCase (	@pbNextRenewalOnly		bit=1,
					@pbUseHighestCycle		bit=0) -- This parameter is only considered when @pbNextRenewalOnly flag = 1
RETURNS TABLE

AS
-- Function :	fn_GetAgeOfCase
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the Age Of Case either for all possible renewals dates or the current Next Renewal date.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 29/12/2014	MF	R42684	1	Function created.

RETURN
	----------------------------------------------------------
	-- If the age of the current Next Renewal Date is required
	-- then use the funciton fn_GetNextRenewalDate
	----------------------------------------------------------
	select	CASEID,	
		RENEWALSTARTDATE,
		NEXTRENEWALDATE,
		CYCLE,
		CPARENEWALDATE, 
		ANNUITY
	from dbo.fn_GetNextRenewalDate(ISNULL(@pbUseHighestCycle,0))
	Where @pbNextRenewalOnly=1
	
	UNION ALL
	-----------------------------------------------------------
	-- When the Age of Case for each possible cycle is required
	-- then use the following query.
	-----------------------------------------------------------
	select	C.CASEID				as CASEID,
		ST.EVENTDATE				as RENEWALSTARTDATE,	
		isnull(CE.EVENTDATE, CE.EVENTDUEDATE)	as NEXTRENEWALDATE,
		CE.CYCLE				as CYCLE,
		NULL					as CPARENEWALDATE, 
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
			WHEN(2) THEN CE.CYCLE+isnull(VP.CYCLEOFFSET,0)
		END as ANNUITY
	from CASES C
	Join CASEEVENT CE	on (CE.CASEID = C.CASEID
				and CE.EVENTNO = -11
				and(CE.EVENTDATE is not null OR CE.EVENTDUEDATE is not null))
	left Join CASEEVENT ST	on (ST.CASEID = C.CASEID
				and ST.EVENTNO = -9
				and ST.CYCLE=1)	
	left join VALIDPROPERTY VP	
				on (VP.PROPERTYTYPE = C.PROPERTYTYPE
				and VP.COUNTRYCODE  = (	select min(VP1.COUNTRYCODE)
							from VALIDPROPERTY VP1
							where VP1.PROPERTYTYPE=C.PROPERTYTYPE
							and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))		
	Where isnull(@pbNextRenewalOnly,0)=0
GO

grant REFERENCES, SELECT on dbo.fn_GetAgeOfCase to public
go
