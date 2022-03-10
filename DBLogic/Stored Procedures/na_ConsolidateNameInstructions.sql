-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ConsolidateNameInstructions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[na_ConsolidateNameInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.na_ConsolidateNameInstructions.'
	drop procedure dbo.na_ConsolidateNameInstructions
end
print '**** Creating procedure dbo.na_ConsolidateNameInstructions...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.na_ConsolidateNameInstructions
as
-- PROCEDURE :	na_ConsolidateNameInstructions
-- VERSION :	3
-- DESCRIPTION:	Cleans up the NAMEINSTRUCTIONS table by creating NameNo default Instructions
--		that may be used as an alternative to Case specific instructions which can
--		then be removed. 
--		NOTE:
--		This procedure could be further enhanced by looping through each NameInstruction
--		and deleting it if the next "best fit" Name Instruction has identical attributes.
--
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Sep 2007	MF		1	Procedure Created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 01 Jul 2010	MF	18758	3	Increase the column size of Instruction Type to allow for expanded list.	

set nocount on


CREATE TABLE #TEMPNAMEINSTRUCTIONS (
	NAMENO			int 		NOT NULL,
	INTERNALSEQUENCE	int 		NULL,
	RESTRICTEDTONAME	int 		NULL,
	INSTRUCTIONCODE		smallint	NULL,
	COUNTRYCODE		nvarchar(3) 	collate database_default NULL,
	PROPERTYTYPE		nchar(1)	collate database_default NULL,
	PERIOD1AMT		smallint	NULL,
	PERIOD1TYPE		nchar(1)	collate database_default NULL,
	PERIOD2AMT		smallint	NULL,
	PERIOD2TYPE		nchar(1)	collate database_default NULL,
	PERIOD3AMT		smallint	NULL,
	PERIOD3TYPE		nchar(1)	collate database_default NULL,
	ADJUSTMENT		nvarchar(4)	collate database_default NULL,
	ADJUSTDAY		tinyint		NULL,
	ADJUSTSTARTMONTH	tinyint		NULL,
	ADJUSTDAYOFWEEK		tinyint		NULL,
	ADJUSTTODATE		datetime	NULL,
	GENERATEDSEQUENCE	int 		identity(0,1),
	CASECOUNT		smallint	NULL
)

CREATE INDEX XPKTEMPNAMEINSTRUCTION ON #TEMPNAMEINSTRUCTIONS
(
	NAMENO
)

create table #TEMPCASEINSTRUCTIONS (
	CASEID			int		NOT NULL, 
	INSTRUCTIONTYPE		nvarchar(3)	collate database_default NULL,
	COMPOSITECODE		nchar(22)	collate database_default NULL,
	INSTRUCTIONCODE		smallint	NULL,
	PERIOD1AMT		smallint	NULL,
	PERIOD1TYPE		nchar(1)	collate database_default NULL,
	PERIOD2AMT		smallint	NULL,
	PERIOD2TYPE		nchar(1)	collate database_default NULL,
	PERIOD3AMT		smallint	NULL,
	PERIOD3TYPE		nchar(1)	collate database_default NULL,
	ADJUSTMENT		nvarchar(4)	collate database_default NULL,
	ADJUSTDAY		tinyint		NULL,
	ADJUSTSTARTMONTH	tinyint		NULL,
	ADJUSTDAYOFWEEK		tinyint		NULL,
	ADJUSTTODATE		datetime	NULL
)

CREATE INDEX XPKTEMPCASEINSTRUCTION ON #TEMPCASEINSTRUCTIONS
(
	CASEID
)

Declare @TranCountStart int
Declare @ErrorCode	int
Declare	@nSequenceNo	int
Declare @nNameNo	int
Declare	@sSQLString	nvarchar(4000)

Set @ErrorCode=0

-- Where there are standing instructions against CASES but no default standing instruction for 
-- the NAME we should load a default.  This will later allow the standing instructions held against
-- the Case to be removed
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPNAMEINSTRUCTIONS(NAMENO,INSTRUCTIONCODE,PROPERTYTYPE,COUNTRYCODE,PERIOD1AMT,PERIOD1TYPE,PERIOD2AMT,PERIOD2TYPE, 
					  PERIOD3AMT,PERIOD3TYPE,ADJUSTMENT,ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,
					  ADJUSTTODATE,CASECOUNT)
	select 	NI.NAMENO, NI.INSTRUCTIONCODE, isnull(C.PROPERTYTYPE,NI.PROPERTYTYPE), isnull(C.COUNTRYCODE,NI.COUNTRYCODE), NI.PERIOD1AMT, NI.PERIOD1TYPE, NI.PERIOD2AMT, NI.PERIOD2TYPE, 
		NI.PERIOD3AMT, NI.PERIOD3TYPE, NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,
		NI.ADJUSTTODATE,COUNT(*)
	from NAMEINSTRUCTIONS NI
	join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	left join CASES C   on (C.CASEID=NI.CASEID)
	where (C.CASEID is not null OR (NI.PROPERTYTYPE is null and NI.COUNTRYCODE is not null))
	and not exists
	(select * from NAMEINSTRUCTIONS NI1
	 join INSTRUCTIONS I1 on (I1.INSTRUCTIONCODE=NI1.INSTRUCTIONCODE)
	 where NI1.NAMENO=NI.NAMENO
	 and I1.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
	 and NI1.INSTRUCTIONCODE<>NI.INSTRUCTIONCODE
	 and NI1.COUNTRYCODE=isnull(C.COUNTRYCODE,NI.COUNTRYCODE)
	 and NI1.PROPERTYTYPE=isnull(C.PROPERTYTYPE,NI.PROPERTYTYPE))
	group by NI.NAMENO, NI.INSTRUCTIONCODE,isnull(C.PROPERTYTYPE,NI.PROPERTYTYPE), isnull(C.COUNTRYCODE,NI.COUNTRYCODE), NI.PERIOD1AMT, NI.PERIOD1TYPE, NI.PERIOD2AMT, NI.PERIOD2TYPE, 
		 NI.PERIOD3AMT, NI.PERIOD3TYPE,NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,
		 NI.ADJUSTTODATE"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Start the Transaction
If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
End

-- For each different Instruction Type create a default Standing Instruction for the Name, PropertyType and 
-- CountryCode combination by choosing the instruction that has the most Cases referencing it.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into NAMEINSTRUCTIONS(NAMENO,INTERNALSEQUENCE,INSTRUCTIONCODE,PROPERTYTYPE, COUNTRYCODE,PERIOD1AMT,PERIOD1TYPE,PERIOD2AMT,PERIOD2TYPE, 
				     PERIOD3AMT,PERIOD3TYPE,ADJUSTMENT,ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,
				     ADJUSTTODATE)
	select	NI.NAMENO, (select max(INTERNALSEQUENCE) from NAMEINSTRUCTIONS NI2 where NI2.NAMENO=NI.NAMENO)+NI.GENERATEDSEQUENCE,
		NI.INSTRUCTIONCODE,NI.PROPERTYTYPE, NI.COUNTRYCODE, NI.PERIOD1AMT,NI.PERIOD1TYPE,NI.PERIOD2AMT,NI.PERIOD2TYPE,NI.PERIOD3AMT,NI.PERIOD3TYPE,
		NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,NI.ADJUSTTODATE
	from #TEMPNAMEINSTRUCTIONS NI
	join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	left join (select N.NAMENO, N.PROPERTYTYPE, N.COUNTRYCODE, I1.INSTRUCTIONTYPE
		   from NAMEINSTRUCTIONS N
		   join INSTRUCTIONS I1 on (I1.INSTRUCTIONCODE=N.INSTRUCTIONCODE)
		   where N.CASEID is NULL
		   and N.RESTRICTEDTONAME is null
		   and N.PROPERTYTYPE is not null
		   and N.COUNTRYCODE  is not null) NI1	on (NI1.NAMENO=NI.NAMENO
							and NI1.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
							and NI1.PROPERTYTYPE=NI.PROPERTYTYPE
							and NI1.COUNTRYCODE =NI.COUNTRYCODE)
	where NI1.NAMENO is null
	and convert(char(5), NI.CASECOUNT)+convert(char(11), NI.GENERATEDSEQUENCE)
		=(	select max(convert(char(5), T.CASECOUNT)+convert(char(11), T.GENERATEDSEQUENCE))
			from #TEMPNAMEINSTRUCTIONS T
			join INSTRUCTIONS I1 on (I1.INSTRUCTIONCODE=T.INSTRUCTIONCODE)
			where I1.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
			and T.PROPERTYTYPE=NI.PROPERTYTYPE
			and T.COUNTRYCODE=NI.COUNTRYCODE)"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- For each different Instruction Type create a default Standing Instruction for the Name and PropertyType  
-- combination by choosing the instruction that has the most Cases referencing it.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into NAMEINSTRUCTIONS(NAMENO,INTERNALSEQUENCE,INSTRUCTIONCODE,PROPERTYTYPE, COUNTRYCODE,PERIOD1AMT,PERIOD1TYPE,PERIOD2AMT,PERIOD2TYPE, 
				     PERIOD3AMT,PERIOD3TYPE,ADJUSTMENT,ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,
				     ADJUSTTODATE)
	select	NI.NAMENO, (select max(INTERNALSEQUENCE) from NAMEINSTRUCTIONS NI2 where NI2.NAMENO=NI.NAMENO)+NI.GENERATEDSEQUENCE,
		NI.INSTRUCTIONCODE,NI.PROPERTYTYPE, NULL, NI.PERIOD1AMT,NI.PERIOD1TYPE,NI.PERIOD2AMT,NI.PERIOD2TYPE,NI.PERIOD3AMT,NI.PERIOD3TYPE,
		NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,NI.ADJUSTTODATE
	from #TEMPNAMEINSTRUCTIONS NI
	join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	left join (select N.NAMENO, N.PROPERTYTYPE, I1.INSTRUCTIONTYPE
		   from NAMEINSTRUCTIONS N
		   join INSTRUCTIONS I1 on (I1.INSTRUCTIONCODE=N.INSTRUCTIONCODE)
		   where N.CASEID is NULL
		   and N.RESTRICTEDTONAME is null
		   and N.PROPERTYTYPE is not null
		   and N.COUNTRYCODE  is null) NI1	on (NI1.NAMENO=NI.NAMENO
							and NI1.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
							and NI1.PROPERTYTYPE=NI.PROPERTYTYPE)
	where NI1.NAMENO is null
	and convert(char(5), NI.CASECOUNT)+convert(char(11), NI.GENERATEDSEQUENCE)
		=(	select max(convert(char(5), T.CASECOUNT)+convert(char(11), T.GENERATEDSEQUENCE))
			from #TEMPNAMEINSTRUCTIONS T
			join INSTRUCTIONS I1 on (I1.INSTRUCTIONCODE=T.INSTRUCTIONCODE)
			where I1.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
			and T.PROPERTYTYPE=NI.PROPERTYTYPE)"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Clear out the contents of the #TEMPNAMEINSTRUCTIONS table
If @ErrorCode=0
Begin
	Set @sSQLString="
	delete from #TEMPNAMEINSTRUCTIONS"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-- Separate out the Standing Instructions that are not held against a Case into a temporary table in order to get 
-- performance improvement for this procedure.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPNAMEINSTRUCTIONS(NAMENO, INTERNALSEQUENCE,RESTRICTEDTONAME,INSTRUCTIONCODE,COUNTRYCODE,PROPERTYTYPE,
					  PERIOD1AMT,PERIOD1TYPE,PERIOD2AMT,PERIOD2TYPE,PERIOD3AMT,PERIOD3TYPE,ADJUSTMENT,
					  ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,ADJUSTTODATE)
	select	NAMENO,INTERNALSEQUENCE,RESTRICTEDTONAME,INSTRUCTIONCODE,COUNTRYCODE,PROPERTYTYPE,PERIOD1AMT,PERIOD1TYPE,
		PERIOD2AMT,PERIOD2TYPE,PERIOD3AMT,PERIOD3TYPE,ADJUSTMENT,ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,
		ADJUSTTODATE
	from NAMEINSTRUCTIONS
	where CASEID is null"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- For each Standing Instruction held directly against a Case we need to find what the next best standing
-- instruction available is.  This will allow us to remove the Case specific instruction if the next best
-- one is identical.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, COMPOSITECODE)
	SELECT	C.CASEID, I1.INSTRUCTIONTYPE, 
	
						-- To determine the best InstructionCode a weighting is	
						-- given based on the existence of characteristics	
						-- found in the NAMEINSTRUCTIONS row.  The MAX function 
						-- returns the highest weighting to which the required	
						-- INSTRUCTIONCODE has been concatenated.		
	
		(SELECT substring(max (
			CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
			convert(nchar(11),NI.NAMENO)        +
			convert(nchar(11),NI.INTERNALSEQUENCE)),4,22)
		FROM		INSTRUCTIONS	  I
		join		INSTRUCTIONTYPE  IT  on ( IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		join		CASENAME 	 CN  on ( CN.CASEID=C.CASEID 
						     and  CN.NAMETYPE=IT.NAMETYPE)
		left join 	CASENAME	 CN1 on ( CN1.CASEID=C.CASEID 
						     and  CN1.NAMETYPE=IT.RESTRICTEDBYTYPE
						     and  CN1.SEQUENCE=(select min(SEQUENCE)
									from CASENAME CN2
									where CN2.CASEID  =C.CASEID
									and   CN2.NAMETYPE=CN1.NAMETYPE
									and   CN2.EXPIRYDATE is null))
		join		#TEMPNAMEINSTRUCTIONS NI  
						     on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
						     and  NI.NAMENO=CN.NAMENO
						     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
						     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
						     and (NI.RESTRICTEDTONAME=CN1.NAMENO OR NI.RESTRICTEDTONAME is NULL) )
		where		I.INSTRUCTIONTYPE=I1.INSTRUCTIONTYPE)
	from NAMEINSTRUCTIONS C
	join INSTRUCTIONS I1 on (I1.INSTRUCTIONCODE=C.INSTRUCTIONCODE)
	where C.CASEID is not null"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Update the temporary table with the rest of the information about the next best standing instruction
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPCASEINSTRUCTIONS
	set INSTRUCTIONCODE =NI.INSTRUCTIONCODE,
	    PERIOD1AMT      =NI.PERIOD1AMT,
	    PERIOD1TYPE     =NI.PERIOD1TYPE,
	    PERIOD2AMT      =NI.PERIOD2AMT,
	    PERIOD2TYPE     =NI.PERIOD2TYPE,
	    PERIOD3AMT      =NI.PERIOD3AMT,
	    PERIOD3TYPE     =NI.PERIOD3TYPE,
	    ADJUSTMENT      =NI.ADJUSTMENT,
	    ADJUSTDAY       =NI.ADJUSTDAY,
	    ADJUSTSTARTMONTH=NI.ADJUSTSTARTMONTH,
	    ADJUSTDAYOFWEEK =NI.ADJUSTDAYOFWEEK,
	    ADJUSTTODATE    =NI.ADJUSTTODATE	    
	From #TEMPCASEINSTRUCTIONS T
	join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(T.COMPOSITECODE,1, 11))
				and  NI.INTERNALSEQUENCE=convert(int, substring(T.COMPOSITECODE,12,11)))"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Start a new Transaction
If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
End

-- Now delete any Case specific Standing Instructions that have an identical standing instruction
-- available as the next best choice.
If @ErrorCode=0
Begin
	Set @sSQLString="
	delete NAMEINSTRUCTIONS
	from NAMEINSTRUCTIONS NI
	join #TEMPCASEINSTRUCTIONS CI	on (CI.CASEID=NI.CASEID
					and CI.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	where (CI.PERIOD1AMT =NI.PERIOD1AMT  OR (CI.PERIOD1AMT  is NULL and NI.PERIOD1AMT  is NULL))
	and   (CI.PERIOD1TYPE=NI.PERIOD1TYPE OR (CI.PERIOD1TYPE is NULL and NI.PERIOD1TYPE is NULL))
	and   (CI.PERIOD2AMT =NI.PERIOD2AMT  OR (CI.PERIOD2AMT  is NULL and NI.PERIOD2AMT  is NULL))
	and   (CI.PERIOD2TYPE=NI.PERIOD2TYPE OR (CI.PERIOD2TYPE is NULL and NI.PERIOD2TYPE is NULL))
	and   (CI.PERIOD3AMT =NI.PERIOD3AMT  OR (CI.PERIOD3AMT  is NULL and NI.PERIOD3AMT  is NULL))
	and   (CI.PERIOD3TYPE=NI.PERIOD3TYPE OR (CI.PERIOD3TYPE is NULL and NI.PERIOD3TYPE is NULL))
	and   (CI.ADJUSTMENT      =NI.ADJUSTMENT       OR (CI.ADJUSTMENT       is NULL and NI.ADJUSTMENT       is NULL))
	and   (CI.ADJUSTDAY       =NI.ADJUSTDAY        OR (CI.ADJUSTDAY        is NULL and NI.ADJUSTDAY        is NULL))
	and   (CI.ADJUSTSTARTMONTH=NI.ADJUSTSTARTMONTH OR (CI.ADJUSTSTARTMONTH is NULL and NI.ADJUSTSTARTMONTH is NULL))
	and   (CI.ADJUSTDAYOFWEEK =NI.ADJUSTDAYOFWEEK  OR (CI.ADJUSTDAYOFWEEK  is NULL and NI.ADJUSTDAYOFWEEK  is NULL))
	and   (CI.ADJUSTTODATE    =NI.ADJUSTTODATE     OR (CI.ADJUSTTODATE     is NULL and NI.ADJUSTTODATE     is NULL))"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- PropertyType and CountryCode is not required to be held against a Case specific 
-- standing instruction
If @ErrorCode=0
Begin
	Set @sSQLString="
	update NAMEINSTRUCTIONS
	set COUNTRYCODE=null,
	    PROPERTYTYPE=null
	where CASEID is not null
	and (COUNTRYCODE is not null OR PROPERTYTYPE is not null)"

	exec @ErrorCode=sp_executesql @sSQLString
End

---------------------------------------------------------------------
-- Delete any NameInstructions where Property & CountryCode can be
-- replaced by default CountryCode for the same NameNo
---------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	delete NAMEINSTRUCTIONS
	from NAMEINSTRUCTIONS NI
	join (	select  I.NAMENO, I.INSTRUCTIONCODE,I.PROPERTYTYPE, I.COUNTRYCODE,I.PERIOD1AMT,I.PERIOD1TYPE,I.PERIOD2AMT,I.PERIOD2TYPE,I.PERIOD3AMT,
			I.PERIOD3TYPE,I.ADJUSTMENT,I.ADJUSTDAY,I.ADJUSTSTARTMONTH,I.ADJUSTDAYOFWEEK,I.ADJUSTTODATE
		from NAMEINSTRUCTIONS I
		where I.CASEID         is null
		and I.PROPERTYTYPE     is not null
		and I.COUNTRYCODE      is null
		and I.RESTRICTEDTONAME is null) H on (H.NAMENO=NI.NAMENO
						  and H.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	where NI.CASEID         is null
	and NI.PROPERTYTYPE	is not null
	and NI.COUNTRYCODE	is not null
	and NI.RESTRICTEDTONAME is null
	and checksum(NI.PROPERTYTYPE,NI.PERIOD1AMT,NI.PERIOD1TYPE,NI.PERIOD2AMT,NI.PERIOD2TYPE,NI.PERIOD3AMT,NI.PERIOD3TYPE,NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,NI.ADJUSTTODATE)
	  = checksum( H.PROPERTYTYPE, H.PERIOD1AMT, H.PERIOD1TYPE, H.PERIOD2AMT, H.PERIOD2TYPE, H.PERIOD3AMT, H.PERIOD3TYPE, H.ADJUSTMENT, H.ADJUSTDAY, H.ADJUSTSTARTMONTH, H.ADJUSTDAYOFWEEK, H.ADJUSTTODATE)"

	exec @ErrorCode=sp_executesql @sSQLString
End

---------------------------------------------------------------------
-- Delete any NameInstructions where PropertyType can be
-- replaced by default PropertyType & Country for the same NameNo
---------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	delete NAMEINSTRUCTIONS
	from NAMEINSTRUCTIONS NI
	join (	select  I.NAMENO, I.INSTRUCTIONCODE,I.PROPERTYTYPE, I.COUNTRYCODE,I.PERIOD1AMT,I.PERIOD1TYPE,I.PERIOD2AMT,I.PERIOD2TYPE,I.PERIOD3AMT,
			I.PERIOD3TYPE,I.ADJUSTMENT,I.ADJUSTDAY,I.ADJUSTSTARTMONTH,I.ADJUSTDAYOFWEEK,I.ADJUSTTODATE
		from NAMEINSTRUCTIONS I
		where I.CASEID         is null
		and I.PROPERTYTYPE     is null
		and I.COUNTRYCODE      is null
		and I.RESTRICTEDTONAME is null) H on (H.NAMENO=NI.NAMENO
						  and H.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	where NI.CASEID         is null
	and NI.PROPERTYTYPE	is not null
	and NI.COUNTRYCODE	is null
	and NI.RESTRICTEDTONAME is null
	and checksum(NI.PERIOD1AMT,NI.PERIOD1TYPE,NI.PERIOD2AMT,NI.PERIOD2TYPE,NI.PERIOD3AMT,NI.PERIOD3TYPE,NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,NI.ADJUSTTODATE)
	  = checksum( H.PERIOD1AMT, H.PERIOD1TYPE, H.PERIOD2AMT, H.PERIOD2TYPE, H.PERIOD3AMT, H.PERIOD3TYPE, H.ADJUSTMENT, H.ADJUSTDAY, H.ADJUSTSTARTMONTH, H.ADJUSTDAYOFWEEK, H.ADJUSTTODATE)"

	exec @ErrorCode=sp_executesql @sSQLString
End

---------------------------------------------------------------------
-- Delete any NameInstructions where CountryCode can be
-- replaced by default PropertyType & Country for the same NameNo
---------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	delete NAMEINSTRUCTIONS
	from NAMEINSTRUCTIONS NI
	join (	select  I.NAMENO, I.INSTRUCTIONCODE,I.PROPERTYTYPE, I.COUNTRYCODE,I.PERIOD1AMT,I.PERIOD1TYPE,I.PERIOD2AMT,I.PERIOD2TYPE,I.PERIOD3AMT,
			I.PERIOD3TYPE,I.ADJUSTMENT,I.ADJUSTDAY,I.ADJUSTSTARTMONTH,I.ADJUSTDAYOFWEEK,I.ADJUSTTODATE
		from NAMEINSTRUCTIONS I
		where I.CASEID         is null
		and I.PROPERTYTYPE     is null
		and I.COUNTRYCODE      is null
		and I.RESTRICTEDTONAME is null) H on (H.NAMENO=NI.NAMENO
						  and H.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	where NI.CASEID         is null
	and NI.PROPERTYTYPE	is null
	and NI.COUNTRYCODE	is not null
	and NI.RESTRICTEDTONAME is null
	and checksum(NI.PERIOD1AMT,NI.PERIOD1TYPE,NI.PERIOD2AMT,NI.PERIOD2TYPE,NI.PERIOD3AMT,NI.PERIOD3TYPE,NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,NI.ADJUSTTODATE)
	  = checksum( H.PERIOD1AMT, H.PERIOD1TYPE, H.PERIOD2AMT, H.PERIOD2TYPE, H.PERIOD3AMT, H.PERIOD3TYPE, H.ADJUSTMENT, H.ADJUSTDAY, H.ADJUSTSTARTMONTH, H.ADJUSTDAYOFWEEK, H.ADJUSTTODATE)"

	exec @ErrorCode=sp_executesql @sSQLString
End

---------------------------------------------------------------------
-- Delete any NameInstructions
-- that are identical to the default set held against the Home NameNo
---------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	delete NAMEINSTRUCTIONS
	from NAMEINSTRUCTIONS NI
	join (	select  I.NAMENO, I.INSTRUCTIONCODE,I.PROPERTYTYPE, I.COUNTRYCODE,I.PERIOD1AMT,I.PERIOD1TYPE,I.PERIOD2AMT,I.PERIOD2TYPE,I.PERIOD3AMT,
			I.PERIOD3TYPE,I.ADJUSTMENT,I.ADJUSTDAY,I.ADJUSTSTARTMONTH,I.ADJUSTDAYOFWEEK,I.ADJUSTTODATE
		from SITECONTROL S
		join NAMEINSTRUCTIONS I on (I.NAMENO=S.COLINTEGER)
		where S.CONTROLID='HOMENAMENO'
		and I.CASEID           is null
		and I.RESTRICTEDTONAME is null) H on (H.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	where NI.CASEID         is null
	and NI.RESTRICTEDTONAME is null
	and checksum(NI.PROPERTYTYPE,NI.COUNTRYCODE,NI.PERIOD1AMT,NI.PERIOD1TYPE,NI.PERIOD2AMT,NI.PERIOD2TYPE,NI.PERIOD3AMT,NI.PERIOD3TYPE,NI.ADJUSTMENT,NI.ADJUSTDAY,NI.ADJUSTSTARTMONTH,NI.ADJUSTDAYOFWEEK,NI.ADJUSTTODATE)
	  = checksum( H.PROPERTYTYPE, H.COUNTRYCODE,H.PERIOD1AMT, H.PERIOD1TYPE, H.PERIOD2AMT, H.PERIOD2TYPE, H.PERIOD3AMT, H.PERIOD3TYPE, H.ADJUSTMENT, H.ADJUSTDAY, H.ADJUSTSTARTMONTH, H.ADJUSTDAYOFWEEK, H.ADJUSTTODATE)
	and NI.NAMENO <> H.NAMENO"	-- Do not delete the default held against the Home NameNo

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-- As a final transaction reset the INTERNALSEQ on the NAMEINSTRUCTIONS table

-- Start a new Transaction
If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update NAMEINSTRUCTIONS
	Set @nSequenceNo=CASE WHEN(@nNameNo=NAMENO)
				THEN @nSequenceNo+1
				ELSE 0
			 END,
	    INTERNALSEQUENCE=@nSequenceNo,
	    @nNameNo=NAMENO
	From NAMEINSTRUCTIONS"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nSequenceNo		int	OUTPUT,
				  @nNameNo		int	OUTPUT',
				  @nSequenceNo=@nSequenceNo	OUTPUT,
				  @nNameNo=@nNameNo		OUTPUT
End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

Return @ErrorCode
go

grant execute on dbo.na_ConsolidateNameInstructions to public
go
