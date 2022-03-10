-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCheckDateOfLaw
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCheckDateOfLaw]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCheckDateOfLaw.'
	drop procedure dbo.ip_PoliceCheckDateOfLaw
end
print '**** Creating procedure dbo.ip_PoliceCheckDateOfLaw...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceCheckDateOfLaw 
				@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceCheckDateOfLaw
-- VERSION :	17
-- DESCRIPTION:	This procedure looks at Events that have just occurred and checks to see if this will trigger
--		a change in law.  If they do then the Action(s) effected will be updated
--		on the #TEMPOPENACTION table to be recalculated.
-- CALLED BY :	ipu_Policing

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 27/09/2000	MF			Procedure created
-- 15/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles 
-- 10/06/2003	MF	8893		Change of law appears to be happening 1 cycle too late where the 
--					law is retrospective.  This is because the TEMPCASEEVENT rows with a STATE of
--					'RX' and 'IX' were not triggering the change.
-- 28 Jul 2003	MF		10	Standardise version number
-- 14 Feb 2005	MF	9784	11	Any Event that is used for determining the Date of Law is to trigger a
--					criteria recalculation if it changes.
-- 07 Jun 2006	MF	12417	12	Change order of columns returned in debug mode to make it easier to review
-- 31 May 2007	MF	14812	13	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	14	Reserve word [STATE]
-- 31 Jan 2008	MF	15895	15	When determining the Events that trigger a Date Of Law for a Case Action,
--					consider if there is an ActualCaseType associated with the CaseType of the 
--					Case being processed.
-- 29 Mar 2012	MF	R12128	16	Set the STATE on the OPENACTION to 'CD' to indicate that the date of law has
--					been requested to calculate. This will differentiate from those OpenAction rows
--					where we are forcing an entire recalculation
-- 14 Nov 2018  AV  75198/DR-45358	17   Date conversion errors when creating cases and opening names in Chinese DB
--		

set nocount on

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	Set @sSQLString="
	update	#TEMPOPENACTION
	set	[STATE]='CD'
	from	#TEMPOPENACTION T
	join	#TEMPCASEEVENT	TC on (TC.CASEID=T.CASEID)
	join	CASETYPE	CT on (CT.CASETYPE=T.CASETYPE)
	join	VALIDACTION	VA on (VA.CASETYPE	in (CT.CASETYPE, CT.ACTUALCASETYPE)
				   and VA.PROPERTYTYPE	= T.PROPERTYTYPE
				   and VA.ACTION	= T.ACTION
				   and TC.EVENTNO in (VA.ACTEVENTNO, VA.RETROEVENTNO)
				   and VA.COUNTRYCODE	= (select min(COUNTRYCODE)
							   from VALIDACTION VA1
							   where VA1.COUNTRYCODE in (T.COUNTRYCODE, 'ZZZ')
							   and   VA1.PROPERTYTYPE=VA.PROPERTYTYPE
							   and	 VA1.CASETYPE	 =VA.CASETYPE))
					
	where	T.POLICEEVENTS=1
	and	TC.[STATE] in ('R','I','RX','IX','D','DX')
	and	TC.NEWEVENTDATE is not null"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCheckDateOfLaw',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	T.[STATE], * from #TEMPOPENACTION T
		order by T.[STATE], T.CASEID, T.ACTION"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceCheckDateOfLaw  to public
go
