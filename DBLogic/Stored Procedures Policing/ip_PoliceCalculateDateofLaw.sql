-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCalculateDateofLaw
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCalculateDateofLaw]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCalculateDateofLaw.'
	drop procedure dbo.ip_PoliceCalculateDateofLaw
end
print '**** Creating procedure dbo.ip_PoliceCalculateDateofLaw...'
print ''
go

set QUOTED_IDENTIFIER off
GO
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceCalculateDateofLaw 
			@pnDebugFlag	tinyint 
as
-- PROCEDURE :	ip_PoliceCalculateDateofLaw
-- VERSION :	20
-- DESCRIPTION:	Calculates the Date of Act (Law) where appropriate for each row in #TEMPOPENACTION
-- CALLED BY :	ipu_Policing

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/07/2000	MF			Procedure created
-- 13/11/2001	MF	7190		Use sp_executesql to reduce the occurrence of recompilation
-- 28 Jul 2003	MF		10	Standardise the version number.
-- 17 Jun 2004	MF	10188	11	Not getting retrospective event associated with date of law.
-- 06 Aug 2004	AB	8035	12	Add collate database_default to temp table definitions
-- 24 May 2007	MF	14812	13	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	14	Reserve word [STATE]
-- 31 Jan 2008	MF	15895	15	When determining the Date Of Law for a Case Action, consider if there is an 
--					ActualCaseType associated with the CaseType of the Case being processed.
-- 02 Dec 2009	MF	18285	16	When determining the Date of Law to use then match on EventNo specified against
--					the VALIDACTDATES table in preference to the EventNo specified against the ACTIONS table.
--					This resolved a problem for an AU Trademark where Filing=1952 & Registration=1966.
-- 04 Aug 2010	MF	18963	17	Performance problem when large number of US TM cases are determine the date of law. Introduce new
--					temporary table as an interim step.
-- 29 Mar 2012	MF	R12128	18	If a new date of law is not found for those rows explicitly triggered to check the date of law then
--					set the STATE of the OPENACTION to 'C1' so it will not try and recalculate all events for no reason
-- 19 Apr 2012	MF	R12199	19	Revisit of RFC 12128. Ensure the STATE is set to 'C" if no NEWCRITERIANO exists as this indicates that
--					it must be calculated irrespective of whether a Date of Law exists.
-- 14 Nov 2018  AV  75198/DR-45358	20   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@dtCurrentDate	datetime,
		@dtNewDate	datetime,
		@sSQLString	nvarchar(4000)

-- A temporary table used to determine the Date of law

	Create Table #TEMPACTDATES (
		CASEID		integer		not null,
		EVENTNO		integer		not null,
		EVENTDATE	datetime	not null
	)

-- SQA18963
-- Temporary table introduced as performance improvement
	Create Table #TEMPACTION (
		CASEID		integer		not null,
		ACTION		nvarchar(3)	collate database_default not null,
		CASETYPE	nchar(1)	collate database_default not null,
		COUNTRYCODE	nvarchar(3)	collate database_default not null,
		PROPERTYTYPE	nchar(1)	collate database_default not null
	)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode=0
Set @nRowCount=0

If @ErrorCode=0
BEGIN
	-- SQA18963
	-- Performance improvement step
	Set @sSQLString="
	insert into #TEMPACTION(CASEID,ACTION,CASETYPE,COUNTRYCODE,PROPERTYTYPE)
	select	Distinct T.CASEID,T.ACTION,T.CASETYPE,T.COUNTRYCODE,T.PROPERTYTYPE
	from 	#TEMPOPENACTION T
	join	CRITERIA C	on (C.COUNTRYCODE  = T.COUNTRYCODE
				and C.PROPERTYTYPE = T.PROPERTYTYPE
				and(C.CASECATEGORY = T.CASECATEGORY or C.CASECATEGORY is null)
				and(C.SUBTYPE      = T.SUBTYPE      or C.SUBTYPE      is null)
				and C.ACTION	   = T.ACTION
				and C.DATEOFACT    is not null)
	where	T.[STATE] in ('C','CD')"

	Execute @ErrorCode = sp_executesql @sSQLString
	Set @nRowCount=@@Rowcount
End

---------------------------------------------------------------------------------------------------------------------
-- Update DATEFORACT
-- This section is used to update TEMPOPENACTION with the date of the law (Act) to use for the particular combination
-- of Country, Propertytype and Action.
-- The DATEFORACT only needs to be calculated where there exists a Criteria for the Country, Property & Action
-- combination that actually makes use of a particular DATEOFACT.

If @ErrorCode=0
and @nRowCount>0
BEGIN		
	Set @sSQLString="
	insert into #TEMPACTDATES
	select	Distinct T.CASEID, TC.EVENTNO, TC.NEWEVENTDATE
	from 	#TEMPACTION T
	join	CASETYPE CT	on (CT.CASETYPE    = T.CASETYPE)
	join	VALIDACTION A	on (A.COUNTRYCODE  = (select min (COUNTRYCODE) 
						 	from VALIDACTION A1
							where A1.PROPERTYTYPE=A.PROPERTYTYPE
							and   A1.CASETYPE    =A.CASETYPE
							and   A1.ACTION	     =A.ACTION
							and   A1.COUNTRYCODE in (T.COUNTRYCODE,'ZZZ' ))
				and A.PROPERTYTYPE  = T.PROPERTYTYPE
				and A.CASETYPE	    in (CT.CASETYPE,CT.ACTUALCASETYPE)
				and A.ACTION	    = T.ACTION)
	join	VALIDACTDATES D	on ( D.COUNTRYCODE  = T.COUNTRYCODE
				and  D.PROPERTYTYPE = T.PROPERTYTYPE
				and (D.RETROSPECTIVEACTIO = T.ACTION OR  D.RETROSPECTIVEACTIO IS NULL ))

	join	#TEMPCASEEVENT TC
				on ( TC.CASEID  = T.CASEID
				and  TC.CYCLE   = 1
				and  TC.EVENTNO in (A.ACTEVENTNO, A.RETROEVENTNO, D.ACTEVENTNO, D.RETROEVENTNO, -13) --SQA10188
				and  TC.[STATE] not like 'D%'
				and  TC.NEWEVENTDATE is not null)"

	Execute @ErrorCode = sp_executesql @sSQLString
	Set @nRowCount=@@Rowcount
End

-- Update the #TEMPOPENACTION table with the Date of Act to use when determining the law.
-- The UPDATE makes use of a sub-select surrounded by a number of functions.  I will explain the SQL starting from the
-- sub-select and work back.
--	The subselect is only allowed to return a single column and a single row.  The single row constraint has been
--	handled by using "TOP 1" to restrict the result to the first row only.
--	The constraint of a single column presented more of a challenge because part of the process of determining the
--	correct date was to ORDER on the COUNTRYCODE (ASC), a weighting (ASC) and finally the Date (DESC).  The "weighting"
--	had to be calculated which meant it had to be a part of the SELECT list.  The weighting values start at 9 (best)
--	and descend down to 0 (worst).
--	The solution was to concatenate the weighting value with the returned date in YYYYMMDD and then sort the result
--	in descending sequence.
--	The resulting concatenated column then has the DATE component extracted using SUBSTRING and finally the result
--	is converted back into DATETIME format.
If  @ErrorCode=0
and @nRowCount>0
Begin
	set @sSQLString="
	Update 	#TEMPOPENACTION 
	set	@dtCurrentDate=DATEFORACT,
		@dtNewDate    =convert(datetime,
				substring(
					(SELECT MAX(
					CASE WHEN (A.COUNTRYCODE='ZZZ')			THEN '0'
											ELSE '1'
					END +
					CASE WHEN (D.RETROSPECTIVEACTIO is NULL)
					     THEN CASE 	WHEN (E.EVENTNO=D.ACTEVENTNO) 	THEN '9'
					               	WHEN (E.EVENTNO=A.ACTEVENTNO) 	THEN '8'
				        	       	WHEN (E.EVENTNO=-13)          	THEN '5'
       	                       						             	ELSE '0'
				        	  END 
 					     ELSE CASE	WHEN (E.EVENTNO=D.RETROEVENTNO)	THEN '9'
							WHEN (E.EVENTNO=A.RETROEVENTNO)	THEN '8'
							WHEN (E.EVENTNO=D.ACTEVENTNO)  	THEN '7'
							WHEN (E.EVENTNO=A.ACTEVENTNO)  	THEN '6'
											ELSE '5'
						  END 
					END +
					convert(nvarchar,DATEOFACT,112))
					FROM	VALIDACTION A
					join	VALIDACTDATES D	on ( D.COUNTRYCODE	  = T.COUNTRYCODE
								and  D.PROPERTYTYPE	  = T.PROPERTYTYPE
								and (D.RETROSPECTIVEACTIO = T.ACTION OR  D.RETROSPECTIVEACTIO IS NULL ))
					join #TEMPACTDATES E	on ( E.CASEID = T.CASEID							
								and  E.EVENTNO in (A.ACTEVENTNO, A.RETROEVENTNO, D.ACTEVENTNO, D.RETROEVENTNO, -13))
					join CASETYPE CT	on (CT.CASETYPE=T.CASETYPE)
					WHERE (	A.COUNTRYCODE 	= T.COUNTRYCODE OR  A.COUNTRYCODE = 'ZZZ' )  
					AND	A.PROPERTYTYPE	= T.PROPERTYTYPE
					AND	A.CASETYPE 	in (CT.CASETYPE,CT.ACTUALCASETYPE)
					AND	A.ACTION 	= T.ACTION 
					AND	D.DATEOFACT <= E.EVENTDATE),
				3,8),
			112),
		DATEFORACT=@dtNewDate,
			
		[STATE]=CASE WHEN(T.NEWCRITERIANO is null)                                          THEN 'C'
			     WHEN(T.[STATE]='CD' and @dtNewDate=@dtCurrentDate)                     THEN 'C1'
			     WHEN(T.[STATE]='CD' and @dtNewDate is null and @dtCurrentDate is null) THEN 'C1'
			     ELSE 'C'
			END
			
	from	#TEMPOPENACTION T
	join	CRITERIA C	on (C.COUNTRYCODE  = T.COUNTRYCODE
				and C.PROPERTYTYPE = T.PROPERTYTYPE
				and C.ACTION	   = T.ACTION)
	where	T.[STATE] in ('C','CD')
	and	C.DATEOFACT is not null"

	Execute @ErrorCode = sp_executesql @sSQLString,
						N'@dtCurrentDate	datetime	output,
						  @dtNewDate		datetime	output',
						  @dtCurrentDate=@dtCurrentDate		output,
						  @dtNewDate    =@dtNewDate		output
End
						  
If @ErrorCode=0
Begin
	------------------------------------------------------------------
	-- Any OpenAction rows that were flagged to check the date of law
	-- are to be updated to set the STATE back to C1 if they have not
	-- already been updated unless the NEWCRITERIANO is null in which
	-- case STATE should be set to C.
	------------------------------------------------------------------
	Set @sSQLString="
	Update #TEMPOPENACTION
	set [STATE]=CASE WHEN(NEWCRITERIANO is null) THEN 'C' ELSE 'C1' END
	where [STATE]='CD'"
	
	Execute @ErrorCode = sp_executesql @sSQLString
End
		
If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set @sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCalculateDateofLaw',0,1,@sTimeStamp ) with NOWAIT


	If @pnDebugFlag>2
	begin
		set @sSQLString="
		Select	T.[STATE], * from #TEMPOPENACTION T
		order by T.[STATE], CASEID, ACTION"
		
		exec @ErrorCode=sp_executesql @sSQLString
	end
End

drop table #TEMPACTDATES

return @ErrorCode
go

grant execute on dbo.ip_PoliceCalculateDateofLaw  to public
go

