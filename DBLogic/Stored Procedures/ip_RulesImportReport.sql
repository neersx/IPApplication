-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesImportReport
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesImportReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesImportReport.'
	drop procedure dbo.ip_RulesImportReport
end
print '**** Creating procedure dbo.ip_RulesImportReport...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.ip_RulesImportReport
		@psUserName		nvarchar(max)	= 'dbo', -- current user name which will have created the 'Imported_' tables
		@pbReportImported	bit		=1,
		@pbReportExisting	bit		=1,
		@pbReportDifferences	bit		=0,
		@psCountryCode		nvarchar(3)	=null,
		@psPropertyType		nchar(1)	=null
as
-- PROCEDURE :	ip_RulesImportReport
-- VERSION :	14
-- DESCRIPTION:	This stored procedure will report on the Rules that are available for importing
--		into the system.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Jun 2004	MF			Procedure Created
-- 15 Jul 2004	MF		2	Use global temporary tables and drop them if they already exist.
-- 22 Jul 2004	MF		3	Modified to allow an option to report on only Criteria with changes.
-- 30 Aug 2004	MF	10421	4	Adjustment against due date calculation was not being reported.
-- 06 Aug 2004	AB	8035	4	Add collate database_default to temp table definitions
-- 16 Sep 2004	MF	10473	5	Report on Must Exist flag.
-- 24 Jun 2005	MF	11549	6	Allow report to be filtered by Country and Property Type
-- 22 Sep 2005	MF	11549	7	Revisit to correct syntax error.
-- 15 Nov 2005	AB		8	Added collate database_default syntax to ##TEMPCURRENTRULES.PROPERTYTYPE
-- 02 May 2006	MF	12500	9	As we are no longer updating the descriptive names of fields then these
--					will be removed as a difference in the comparison
-- 28 Mar 2007	CR	10252	10	Change Global Temporary tables to local temporary tables.
-- 05 Jul 2013	vql	R13629	11	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 12 Jul 2013	MF	R13596	11	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	12	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
-- 26 Dec 2013	MF	R28126	13	Revisit of RFC13596 to handle situation where report is executed before the data has been imported.
-- 14 Nov 2018  AV  75198/DR-45358	14   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
set concat_null_yields_null off
-- Normally avoid using this setting as it can result in stored procedure recompile.
set ANSI_WARNINGS off

/* -- no longer required as these are local tables that will be dropped automatically 
once the stored procedure is complete
If exists(select * from tempdb.dbo.sysobjects where name = '##TEMPIMPORTRULES')
Begin
	drop table ##TEMPIMPORTRULES
End
*/

Create Table #TEMPIMPORTRULES	(
		PROPERTYTYPE	nchar(1)	collate database_default	null,
		COUNTRYCODE	nvarchar(3)	collate database_default	null,
		CASECATEGORY	nvarchar(2)	collate database_default	null,
		SUBTYPE		nvarchar(2)	collate database_default	null,
		DATEOFACT	nvarchar(11)	collate database_default	null,
		ACTION		nvarchar(2)	collate database_default	null,
		CRITERIANO	int		null,
		DISPLAYSEQUENCE	int		null,
		CRITERIADESC	nvarchar(100)	collate database_default	null,
		EVENTNO		int		null,
		CYCLE		smallint	null,
		CALCCOUNTRY	nvarchar(3)	collate database_default	null,
		EVENTDESC	nvarchar(100)	collate database_default	null,
		EVENTPARENT	nvarchar(100)	collate database_default	null,
		WHICHDUEDATE	nvarchar(32)	collate database_default	null,
		OPERATOR	nvarchar(8)	collate database_default	null,
		DEADLINEPERIOD	int		null,
		PERIODTYPE	nvarchar(17)	collate database_default	null,
		FROMEVENT	nvarchar(100)	collate database_default	null,
		FROMEVENTNO	int		null,
		ADJUSTMENTDESC	nvarchar(50)	collate database_default	null,
		MUSTEXIST	nchar(1)	collate database_default	null,
		ADJUSTMENTCOUNT	smallint	null
		)

/* -- no longer required as these are local tables that will be dropped automatically 
once the stored procedure is complete
If exists(select * from tempdb.dbo.sysobjects where name = '##TEMPCURRENTRULES')
Begin
	drop table ##TEMPCURRENTRULES
End
*/
Create Table #TEMPCURRENTRULES	(
		PROPERTYTYPE	nchar(1)	collate database_default null,
		COUNTRYCODE	nvarchar(3)	collate database_default null,
		CASECATEGORY	nvarchar(2)	collate database_default	null,
		SUBTYPE		nvarchar(2)	collate database_default	null,
		DATEOFACT	nvarchar(11)	collate database_default null,
		ACTION		nvarchar(2)	collate database_default null,
		CRITERIANO	int		null,
		DISPLAYSEQUENCE	int		null,
		CRITERIADESC	nvarchar(100)	collate database_default null,
		EVENTNO		int		null,
		CYCLE		smallint	null,
		CALCCOUNTRY	nvarchar(3)	collate database_default null,
		EVENTDESC	nvarchar(100)	collate database_default null,
		EVENTPARENT	nvarchar(100)	collate database_default null,
		WHICHDUEDATE	nvarchar(32)	collate database_default null,
		OPERATOR	nvarchar(8)	collate database_default null,
		DEADLINEPERIOD	int		null,
		PERIODTYPE	nvarchar(17)	collate database_default null,
		FROMEVENT	nvarchar(100)	collate database_default null,
		FROMEVENTNO	int		null,
		ADJUSTMENTDESC	nvarchar(50)	collate database_default null,
		MUSTEXIST	nchar(1)	collate database_default null,
		ADJUSTMENTCOUNT	smallint	null
		)

declare	@ErrorCode		 int
declare	@sSQLString		 nvarchar(max)
declare @sLineFeed		 char(1)
declare @bCriteriaAllowedeExists bit

Set @ErrorCode=0
Set @sLineFeed=char(10)


--------------------------------------
-- Check if CRITERIAALLOWED has been
-- created already.
--------------------------------------
Set @bCriteriaAllowedeExists = 0

If  @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bCriteriaAllowedeExists = 1 
			 from sysobjects 
			 where id = object_id('"+@psUserName+".CRITERIAALLOWED')"
			 
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bCriteriaAllowedeExists	bit OUTPUT',
			  @bCriteriaAllowedeExists 	= @bCriteriaAllowedeExists OUTPUT
end

---------------------------------------------------
-- Create an interim table to hold the criteria
-- that are allowed to be imported for the purpose
-- of creating or update laws on the receiving
-- database
---------------------------------------------------
If  @ErrorCode=0
and @bCriteriaAllowedeExists=0
Begin
	Set @sSQLString="CREATE TABLE "+@psUserName+".CRITERIAALLOWED (CRITERIANO int not null PRIMARY KEY)"
	exec @ErrorCode=sp_executesql @sSQLString
	
	If @ErrorCode=0
	Begin
		-----------------------------------------
		-- Load the CRITERIA that are candidates
		-- to be imported into a temporary table.
		-- This allows rules defined by a firm to
		-- block or allow criteria.
		-----------------------------------------
		set @sSQLString="
		insert into "+@psUserName+".CRITERIAALLOWED (CRITERIANO)
		select distinct C.CRITERIANO
		from "+@psUserName+".Imported_CRITERIA C
		left join CRITERIA C1 on (C1.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( C.CASETYPE,	
												    C.ACTION,
												    C.PROPERTYTYPE,
												    C.COUNTRYCODE,
												    C.CASECATEGORY,
												    C.SUBTYPE,
												    C.BASIS,
												    C.DATEOFACT) )
		where isnull(C1.RULEINUSE,0)=0"
		
		exec @ErrorCode=sp_executesql @sSQLString
	End
end

-- Extract and format the imported rules ready for reporting

If  @ErrorCode=0
and @pbReportImported=1
Begin
	Set @sSQLString="
	insert into #TEMPIMPORTRULES(CRITERIANO, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, DATEOFACT, ACTION, DISPLAYSEQUENCE, CRITERIADESC,
				    EVENTNO, EVENTDESC, WHICHDUEDATE, EVENTPARENT, 
				    CYCLE, CALCCOUNTRY, OPERATOR, DEADLINEPERIOD, PERIODTYPE, FROMEVENT, FROMEVENTNO,
				    ADJUSTMENTDESC, MUSTEXIST, ADJUSTMENTCOUNT)
	Select	C.CRITERIANO, C.COUNTRYCODE, C.PROPERTYTYPE, C.CASECATEGORY, C.SUBTYPE, 
		convert(nvarchar,C.DATEOFACT,112), C.ACTION, EC.DISPLAYSEQUENCE,
		rtrim(isnull(CT.COUNTRY,'Default')+' '+VP.PROPERTYNAME+' '+VC.CASECATEGORYDESC+' '+VS.SUBTYPEDESC),
		EC.EVENTNO,
		EC.EVENTDESCRIPTION,
		CASE WHEN(DC.NOOFCALCULATIONS=1) THEN 	'Calculated as...'
		     WHEN(DC.NOOFCALCULATIONS>1) THEN 	CASE WHEN(EC.WHICHDUEDATE='E') 
								THEN 'Calculated as the Earliest of...' 
								ELSE 'Calculated as the Latest of...' 
							END
		END,
		-- Report text
		CASE WHEN(EC.UPDATEFROMEVENT is not null)
			THEN 'May be loaded from '+E.EVENTDESCRIPTION+' of '+
			     CASE WHEN(EC.FROMRELATIONSHIP is not null)	THEN CR.RELATIONSHIPDESC
				  WHEN(EC.FROMANCESTOR=1)  		THEN 'parent' 
									ELSE 'this case'
			     END+
			     nullif(' adjusted : '+A.ADJUSTMENTDESC, ' adjusted : ')
		END, 
		DD.CYCLENUMBER, 
		CASE WHEN(C.COUNTRYCODE<>DD.COUNTRYCODE) THEN DD.COUNTRYCODE END,

		CASE(DD.OPERATOR) WHEN('A') THEN 'Add' 
				  WHEN('S') THEN 'Subtract' 
		END,

		DD.DEADLINEPERIOD,

		CASE(DD.PERIODTYPE)
			WHEN('D') THEN 'day'
			WHEN('W') THEN 'week'
			WHEN('M') THEN 'month'
			WHEN('Y') THEN 'year'
		END +
		CASE WHEN(DD.DEADLINEPERIOD not in (1,-1)) THEN 's' END+
		CASE(DD.PERIODTYPE)
			WHEN('E') THEN 'entered period'
			WHEN('1') THEN 'standing period 1'
			WHEN('2') THEN 'standing period 2'
			WHEN('3') THEN 'standing period 3'
		END,

		CASE WHEN(DD.OPERATOR='A') THEN '  to '
		     WHEN(DD.OPERATOR='S') THEN 'from '
		END +	
		isnull(FE.EVENTDESCRIPTION,E1.EVENTDESCRIPTION)+

		CASE(DD.RELATIVECYCLE)
			WHEN(0) THEN '[first]'
			WHEN(1) THEN '[previous]'
			WHEN(2) THEN '[next]'
			WHEN(4) THEN '[last]'
		END+

		CASE(DD.EVENTDATEFLAG)
			WHEN(2) THEN '{due}'
			WHEN(3) THEN '{event/due}'
		END+

		CASE WHEN(DD.MUSTEXIST=1) THEN '(must exist)' END,

		DD.FROMEVENT,

		A1.ADJUSTMENTDESC,

		CASE WHEN(DD.MUSTEXIST=1) THEN 'Y' END, 

		DA.ADJUSTMENTCOUNT
	FROM "+@psUserName+".Imported_CRITERIA C
	join "+@psUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
	join "+@psUserName+".Imported_COUNTRY CT	on (CT.COUNTRYCODE=C.COUNTRYCODE)
	join "+@psUserName+".Imported_VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
				and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
							from "+@psUserName+".Imported_VALIDPROPERTY VP1
							where VP1.PROPERTYTYPE=C.PROPERTYTYPE
							and VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	left join "+@psUserName+".Imported_VALIDCATEGORY VC	
				on (VC.CASETYPE=C.CASETYPE
				and VC.PROPERTYTYPE=C.PROPERTYTYPE
				and VC.CASECATEGORY=C.CASECATEGORY
				and VC.COUNTRYCODE=(	select min(VC1.COUNTRYCODE)
							from "+@psUserName+".Imported_VALIDCATEGORY VC1
							where VC1.CASETYPE=C.CASETYPE
							and VC1.PROPERTYTYPE=C.PROPERTYTYPE
							and VC1.CASECATEGORY=C.CASECATEGORY
							and VC1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	left join "+@psUserName+".Imported_VALIDSUBTYPE VS
				on (VS.CASETYPE=C.CASETYPE
				and VS.PROPERTYTYPE=C.PROPERTYTYPE
				and VS.CASECATEGORY=C.CASECATEGORY
				and VS.SUBTYPE=C.SUBTYPE
				and VS.COUNTRYCODE=(	select min(VS1.COUNTRYCODE)
							from "+@psUserName+".Imported_VALIDSUBTYPE VS1
							where VS1.CASETYPE=C.CASETYPE
							and VS1.PROPERTYTYPE=C.PROPERTYTYPE
							and VS1.CASECATEGORY=C.CASECATEGORY
							and VS1.SUBTYPE=C.SUBTYPE
							and VS1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	join "+@psUserName+".Imported_EVENTCONTROL EC 	on (EC.CRITERIANO=C.CRITERIANO)
	left join "+@psUserName+".Imported_EVENTS E 	on (E.EVENTNO=EC.UPDATEFROMEVENT)
	left join "+@psUserName+".Imported_CASERELATION CR on (CR.RELATIONSHIP=EC.FROMRELATIONSHIP)
	left join "+@psUserName+".Imported_ADJUSTMENT A on (A.ADJUSTMENT=EC.ADJUSTMENT)
	left join "+@psUserName+".Imported_DUEDATECALC DD 	on (DD.CRITERIANO=C.CRITERIANO
								and DD.EVENTNO=EC.EVENTNO
								and DD.COMPARISON is null)
	left join "+@psUserName+".Imported_EVENTCONTROL FE 	on (FE.CRITERIANO=C.CRITERIANO
								and FE.EVENTNO=DD.FROMEVENT)
	left join "+@psUserName+".Imported_EVENTS E1 		on (E1.EVENTNO=DD.FROMEVENT)
	left join "+@psUserName+".Imported_ADJUSTMENT A1	on (A1.ADJUSTMENT=DD.ADJUSTMENT)
	left join (select CRITERIANO, EVENTNO, CYCLENUMBER, COUNT(*) as NOOFCALCULATIONS
		   from "+@psUserName+".Imported_DUEDATECALC
		   where COMPARISON is null
		   group by CRITERIANO, EVENTNO, CYCLENUMBER) DC on(DC.CRITERIANO=DD.CRITERIANO
								and DC.EVENTNO=DD.EVENTNO
								and DC.CYCLENUMBER=DD.CYCLENUMBER)
	left join (select CRITERIANO, EVENTNO, COUNT(*) as ADJUSTMENTCOUNT
		   from "+@psUserName+".Imported_DUEDATECALC
		   where COMPARISON is null
		   and ADJUSTMENT is not null
		   group by CRITERIANO, EVENTNO) DA 		on (DA.CRITERIANO=DD.CRITERIANO
								and DA.EVENTNO=DD.EVENTNO)
	Where C.ACTION in ('~1', '~2')"+
	CASE WHEN(@psCountryCode='ZZZ')		THEN char(10)+char(9)+"and C.COUNTRYCODE is null"
	     WHEN(@psCountryCode is not null)	THEN char(10)+char(9)+"and C.COUNTRYCODE=@psCountryCode"
	END+
	CASE WHEN(@psPropertyType is not null)	THEN char(10)+char(9)+"and C.PROPERTYTYPE=@psPropertyType"
	END+"
	and C.RULEINUSE=1
	and EC.IMPORTANCELEVEL=9"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psCountryCode	nvarchar(3),
					  @psPropertyType	nchar(1)',
					  @psCountryCode =@psCountryCode,
					  @psPropertyType=@psPropertyType
End

-- Extract and format the existing rules ready for reporting

If  @ErrorCode=0
and @pbReportExisting=1
Begin
	Set @sSQLString="
	insert into #TEMPCURRENTRULES(CRITERIANO, COUNTRYCODE, PROPERTYTYPE, CASECATEGORY, SUBTYPE, DATEOFACT, ACTION, DISPLAYSEQUENCE, CRITERIADESC,
				    EVENTNO, EVENTDESC, WHICHDUEDATE, EVENTPARENT, 
				    CYCLE, CALCCOUNTRY, OPERATOR, DEADLINEPERIOD, PERIODTYPE, FROMEVENT, FROMEVENTNO,
				    ADJUSTMENTDESC, MUSTEXIST, ADJUSTMENTCOUNT)
	Select	C.CRITERIANO, C.COUNTRYCODE, C.PROPERTYTYPE, C.CASECATEGORY, C.SUBTYPE, 
		convert(nvarchar,C.DATEOFACT,112), C.ACTION, EC.DISPLAYSEQUENCE,
		rtrim(CT.COUNTRY+' '+VP.PROPERTYNAME+' '+VC.CASECATEGORYDESC+' '+VS.SUBTYPEDESC),
		EC.EVENTNO,
		EC.EVENTDESCRIPTION,
		CASE WHEN(DC.NOOFCALCULATIONS=1) THEN 	'Calculated as...'
		     WHEN(DC.NOOFCALCULATIONS>1) THEN 	CASE WHEN(EC.WHICHDUEDATE='E') 
								THEN 'Calculated as the Earliest of...' 
								ELSE 'Calculated as the Latest of...' 
							END
		END,
		-- Report text
		CASE WHEN(EC.UPDATEFROMEVENT is not null)
			THEN 'May be loaded from '+E.EVENTDESCRIPTION+' of '+
			     CASE WHEN(EC.FROMRELATIONSHIP is not null)	THEN CR.RELATIONSHIPDESC
				  WHEN(EC.FROMANCESTOR=1)  		THEN 'parent' 
									ELSE 'this case'
			     END+
			     nullif(' adjusted : '+A.ADJUSTMENTDESC, ' adjusted : ')
		END, 
		DD.CYCLENUMBER, 
		CASE WHEN(C.COUNTRYCODE<>DD.COUNTRYCODE) THEN DD.COUNTRYCODE END,

		CASE(DD.OPERATOR) WHEN('A') THEN 'Add' 
				  WHEN('S') THEN 'Subtract' 
		END,

		DD.DEADLINEPERIOD,

		CASE(DD.PERIODTYPE)
			WHEN('D') THEN 'day'
			WHEN('W') THEN 'week'
			WHEN('M') THEN 'month'
			WHEN('Y') THEN 'year'
		END +
		CASE WHEN(DD.DEADLINEPERIOD not in (1,-1)) THEN 's' END+
		CASE(DD.PERIODTYPE)
			WHEN('E') THEN 'entered period'
			WHEN('1') THEN 'standing period 1'
			WHEN('2') THEN 'standing period 2'
			WHEN('3') THEN 'standing period 3'
		END,

		CASE WHEN(DD.OPERATOR='A') THEN '  to '
		     WHEN(DD.OPERATOR='S') THEN 'from '
		END +	
		isnull(FE.EVENTDESCRIPTION,E1.EVENTDESCRIPTION)+

		CASE(DD.RELATIVECYCLE)
			WHEN(0) THEN '[first]'
			WHEN(1) THEN '[previous]'
			WHEN(2) THEN '[next]'
			WHEN(4) THEN '[last]'
		END+

		CASE(DD.EVENTDATEFLAG)
			WHEN(2) THEN '{due}'
			WHEN(3) THEN '{event/due}'
		END+

		CASE WHEN(DD.MUSTEXIST=1) THEN '(must exist)' END,

		DD.FROMEVENT,

		A1.ADJUSTMENTDESC,

		CASE WHEN(DD.MUSTEXIST=1) THEN 'Y' END,

		DA.ADJUSTMENTCOUNT
	FROM CRITERIA C
	join COUNTRY CT	on (CT.COUNTRYCODE=C.COUNTRYCODE)
	join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
				and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
							from VALIDPROPERTY VP1
							where VP1.PROPERTYTYPE=C.PROPERTYTYPE
							and VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	left join VALIDCATEGORY VC	
				on (VC.CASETYPE=C.CASETYPE
				and VC.PROPERTYTYPE=C.PROPERTYTYPE
				and VC.CASECATEGORY=C.CASECATEGORY
				and VC.COUNTRYCODE=(	select min(VC1.COUNTRYCODE)
							from VALIDCATEGORY VC1
							where VC1.CASETYPE=C.CASETYPE
							and VC1.PROPERTYTYPE=C.PROPERTYTYPE
							and VC1.CASECATEGORY=C.CASECATEGORY
							and VC1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	left join VALIDSUBTYPE VS
				on (VS.CASETYPE=C.CASETYPE
				and VS.PROPERTYTYPE=C.PROPERTYTYPE
				and VS.CASECATEGORY=C.CASECATEGORY
				and VS.SUBTYPE=C.SUBTYPE
				and VS.COUNTRYCODE=(	select min(VS1.COUNTRYCODE)
							from VALIDSUBTYPE VS1
							where VS1.CASETYPE=C.CASETYPE
							and VS1.PROPERTYTYPE=C.PROPERTYTYPE
							and VS1.CASECATEGORY=C.CASECATEGORY
							and VS1.SUBTYPE=C.SUBTYPE
							and VS1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	join EVENTCONTROL EC 	on (EC.CRITERIANO=C.CRITERIANO)
	left join EVENTS E 	on (E.EVENTNO=EC.UPDATEFROMEVENT)
	left join CASERELATION CR on (CR.RELATIONSHIP=EC.FROMRELATIONSHIP)
	left join ADJUSTMENT A on (A.ADJUSTMENT=EC.ADJUSTMENT)
	left join DUEDATECALC DD 	on (DD.CRITERIANO=C.CRITERIANO
					and DD.EVENTNO=EC.EVENTNO
					and DD.COMPARISON is null)
	left join EVENTCONTROL FE 	on (FE.CRITERIANO=C.CRITERIANO
					and FE.EVENTNO=DD.FROMEVENT)
	left join EVENTS E1 		on (E1.EVENTNO=DD.FROMEVENT)
	left join ADJUSTMENT A1	on (A1.ADJUSTMENT=DD.ADJUSTMENT)
	left join (select CRITERIANO, EVENTNO, CYCLENUMBER, COUNT(*) as NOOFCALCULATIONS
		   from DUEDATECALC
		   where COMPARISON is null
		   group by CRITERIANO, EVENTNO, CYCLENUMBER) DC on(DC.CRITERIANO=DD.CRITERIANO
								and DC.EVENTNO=DD.EVENTNO
								and DC.CYCLENUMBER=DD.CYCLENUMBER)
	left join (select CRITERIANO, EVENTNO, COUNT(*) as ADJUSTMENTCOUNT
		   from DUEDATECALC
		   where COMPARISON is null
		   and ADJUSTMENT is not null
		   group by CRITERIANO, EVENTNO) DA 		on (DA.CRITERIANO=DD.CRITERIANO
								and DA.EVENTNO=DD.EVENTNO)
	Where C.ACTION in ('~1','~2')"+
	CASE WHEN(@psCountryCode='ZZZ')		THEN char(10)+char(9)+"and C.COUNTRYCODE is null"
	     WHEN(@psCountryCode is not null)	THEN char(10)+char(9)+"and C.COUNTRYCODE=@psCountryCode"
	END+
	CASE WHEN(@psPropertyType is not null)	THEN char(10)+char(9)+"and C.PROPERTYTYPE=@psPropertyType"
	END+"
	and C.RULEINUSE=1
	and EC.IMPORTANCELEVEL=9"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psCountryCode	nvarchar(3),
					  @psPropertyType	nchar(1)',
					  @psCountryCode =@psCountryCode,
					  @psPropertyType=@psPropertyType
End

-- Now extract the output to be passed into the report template.

If @ErrorCode=0
Begin
	Set @sSQLString="
	select	isnull(I.PROPERTYTYPE, C.PROPERTYTYPE), 
		isnull(I.COUNTRYCODE,C.COUNTRYCODE), 
		isnull(I.DATEOFACT,X.IMPORTACTDATE), 
		isnull(I.CRITERIANO,C.CRITERIANO), 
		I.DISPLAYSEQUENCE, 
		isnull(I.CRITERIADESC,X.IMPORTDESC), 
		isnull(I.EVENTNO, C.EVENTNO),
		isnull(I.CYCLE,C.CYCLE),
		CN.COUNTRY,
		IE.EVENTDESC, 
		IE.EVENTPARENT, 
		IE.WHICHDUEDATE, 
		I.OPERATOR, 
		I.DEADLINEPERIOD, 
		I.PERIODTYPE, 
		I.FROMEVENT, 
		I.ADJUSTMENTDESC, 
		I.MUSTEXIST, 
		IE.ADJUSTMENTCOUNT,

		isnull(C.DATEOFACT,X.CURRENTACTDATE), 
		isnull(C.CRITERIANO,X.CRITERIANO), 
		C.DISPLAYSEQUENCE, 
		isnull(C.CRITERIADESC,X.CURRENTDESC), 
		C.EVENTNO, 
		C.CYCLE,
		CE.EVENTDESC,
		CE.EVENTPARENT,
		CE.WHICHDUEDATE,
		C.OPERATOR,
		C.DEADLINEPERIOD,
		C.PERIODTYPE,
		C.FROMEVENT, 
		C.ADJUSTMENTDESC,
		C.MUSTEXIST,
		CE.ADJUSTMENTCOUNT,
		CASE WHEN(X.IMPORTACTDATE <>X.CURRENTACTDATE) THEN '1' ELSE '0' END as DIFFERENTACTDATE,
		CASE WHEN(CHECKSUM(X.CURRCOUNTRY,X.CURRPROPERTY,X.CURRCATEGORY,X.CURRSUBTYPE)
		       <> CHECKSUM(X.IMPCOUNTRY, X.IMPPROPERTY, X.IMPCATEGORY, X.IMPSUBTYPE))
		                                              THEN '1' ELSE '0' END as DIFFERENTCRITERIA,
		CASE WHEN(IE.EVENTNO      <>CE.EVENTNO)       THEN '1' ELSE '0' END as DIFFERENTEVENT,
		CASE WHEN(IE.EVENTPARENT  <>CE.EVENTPARENT)   THEN '1' ELSE '0' END as DIFFERENTEVENTPARENT,
		CASE WHEN(IE.WHICHDUEDATE <>CE.WHICHDUEDATE)  THEN '1' ELSE '0' END as DIFFERENTWHICHDUEDATE,
		CASE WHEN(I.OPERATOR      <>C.OPERATOR    )   THEN '1' ELSE '0' END as DIFFERENTOPERATOR,
		CASE WHEN(I.DEADLINEPERIOD<>C.DEADLINEPERIOD) THEN '1' ELSE '0' END as DIFFERENTPERIOD,
		CASE WHEN(I.FROMEVENTNO   <>C.FROMEVENTNO)    THEN '1' ELSE '0' END as DIFFERENTFROMEVENT,
		CASE WHEN(I.ADJUSTMENTDESC<>C.ADJUSTMENTDESC) THEN '1' ELSE '0' END as DIFFERENTADJUSTMENT,
		CASE WHEN(I.MUSTEXIST     <>C.MUSTEXIST)      THEN '1' ELSE '0' END as DIFFERENTMUSTEXIST,
		CASE WHEN(I.PERIODTYPE    <>C.PERIODTYPE)     THEN '1' ELSE '0' END as DIFFERENTPERIODTYPE
	from #TEMPIMPORTRULES I
	Full Join #TEMPCURRENTRULES C	on (C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.COUNTRYCODE =I.COUNTRYCODE
					and C.CRITERIANO  =I.CRITERIANO
					and C.EVENTNO     =I.EVENTNO
					and(C.CYCLE	  =I.CYCLE       or (C.CYCLE       is null and I.CYCLE       is null))
					and(C.CALCCOUNTRY =I.CALCCOUNTRY or (C.CALCCOUNTRY is null and I.CALCCOUNTRY is null))
					and(C.FROMEVENTNO =I.FROMEVENTNO or (C.FROMEVENTNO is null and I.FROMEVENTNO is null)))
	left join COUNTRY CN		on (CN.COUNTRYCODE=isnull(I.CALCCOUNTRY,C.CALCCOUNTRY))
	left join (	select I1.CRITERIANO, I1.CRITERIADESC as IMPORTDESC, C1.CRITERIADESC as CURRENTDESC, 
			I1.COUNTRYCODE as IMPCOUNTRY, I1.PROPERTYTYPE as IMPPROPERTY, I1.CASECATEGORY as IMPCATEGORY, I1.SUBTYPE as IMPSUBTYPE,
			C1.COUNTRYCODE as CURRCOUNTRY,C1.PROPERTYTYPE as CURRPROPERTY,C1.CASECATEGORY as CURRCATEGORY,C1.SUBTYPE as CURRSUBTYPE,
			min(I1.DATEOFACT) as IMPORTACTDATE, min(C1.DATEOFACT) as CURRENTACTDATE
			from #TEMPIMPORTRULES I1
			join #TEMPCURRENTRULES C1 on (C1.CRITERIANO=I1.CRITERIANO)
			group by I1.CRITERIANO,  I1.CRITERIADESC, C1.CRITERIADESC,
				 I1.COUNTRYCODE, I1.PROPERTYTYPE, I1.CASECATEGORY, I1.SUBTYPE,
				 C1.COUNTRYCODE ,C1.PROPERTYTYPE, C1.CASECATEGORY ,C1.SUBTYPE) 
							X on (X.CRITERIANO=isnull(I.CRITERIANO,C.CRITERIANO))
	left join (	select distinct CRITERIANO, EVENTNO, EVENTDESC, EVENTPARENT, WHICHDUEDATE, ADJUSTMENTCOUNT
			from #TEMPIMPORTRULES T
			where CYCLE=(select min(T1.CYCLE) from #TEMPIMPORTRULES T1 Where T1.CRITERIANO=T.CRITERIANO and T1.EVENTNO=T.EVENTNO)
			or CYCLE is null) IE 	on (IE.CRITERIANO=isnull(I.CRITERIANO, C.CRITERIANO)
						and IE.EVENTNO   =isnull(I.EVENTNO,    C.EVENTNO))
	left join (	select distinct CRITERIANO, EVENTNO, EVENTDESC, EVENTPARENT, WHICHDUEDATE, ADJUSTMENTCOUNT
			from #TEMPCURRENTRULES T
			where CYCLE=(select min(T1.CYCLE) from #TEMPCURRENTRULES T1 Where T1.CRITERIANO=T.CRITERIANO and T1.EVENTNO=T.EVENTNO) 
			or CYCLE is null) CE	on (CE.CRITERIANO=isnull(C.CRITERIANO, I.CRITERIANO)
						and CE.EVENTNO   =isnull(C.EVENTNO,    I.EVENTNO))"

	If @pbReportDifferences=1
	Begin
		Set @sSQLString=@sSQLString+"
				-- This derived table is used to find any Criteria where there is a mismatch between the
				-- imported data and the current data.  The use of the CHECKSUM function is a technique
				-- for finding differences between a number of columns.
				-- Descriptive information is not included in the comparison.
		join (	select distinct isnull(I.CRITERIANO, C.CRITERIANO) as CRITERIANO
				from #TEMPIMPORTRULES I
				Full Join #TEMPCURRENTRULES C	
						on (C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.COUNTRYCODE =I.COUNTRYCODE
						and C.CRITERIANO  =I.CRITERIANO
						and C.EVENTNO     =I.EVENTNO
						and(C.CYCLE	  =I.CYCLE       or (C.CYCLE       is null and I.CYCLE       is null))
						and(C.CALCCOUNTRY =I.CALCCOUNTRY or (C.CALCCOUNTRY is null and I.CALCCOUNTRY is null))
						and(C.FROMEVENTNO =I.FROMEVENTNO or (C.FROMEVENTNO is null and I.FROMEVENTNO is null)))
				where CHECKSUM(I.ACTION, I.CRITERIANO, I.DISPLAYSEQUENCE, I.EVENTNO, I.CYCLE, I.CALCCOUNTRY, I.EVENTPARENT, I.WHICHDUEDATE, I.OPERATOR, I.DEADLINEPERIOD, I.PERIODTYPE, I.FROMEVENTNO, I.ADJUSTMENTDESC, I.MUSTEXIST, I.ADJUSTMENTCOUNT)
				  <>  CHECKSUM(C.ACTION, C.CRITERIANO, C.DISPLAYSEQUENCE, C.EVENTNO, C.CYCLE, C.CALCCOUNTRY, C.EVENTPARENT, C.WHICHDUEDATE, C.OPERATOR, C.DEADLINEPERIOD, C.PERIODTYPE, C.FROMEVENTNO, C.ADJUSTMENTDESC, C.MUSTEXIST, C.ADJUSTMENTCOUNT)) CS
							on (CS.CRITERIANO=isnull(I.CRITERIANO,C.CRITERIANO))"
	End

	-- Now add in the order by clause
	Set @sSQLString=@sSQLString+"
	order by isnull(I.PROPERTYTYPE, C.PROPERTYTYPE), isnull(I.COUNTRYCODE,C.COUNTRYCODE), isnull(I.DATEOFACT,C.DATEOFACT),
		 isnull(I.ACTION, C.ACTION), isnull(I.CRITERIANO,C.CRITERIANO), isnull(I.DISPLAYSEQUENCE,C.DISPLAYSEQUENCE), 
		 isnull(I.EVENTNO,C.EVENTNO), CN.COUNTRY, isnull(I.CYCLE,C.CYCLE)"

	exec @ErrorCode=sp_executesql @sSQLString
End

Return @ErrorCode
go

grant execute on dbo.ip_RulesImportReport to public
go

