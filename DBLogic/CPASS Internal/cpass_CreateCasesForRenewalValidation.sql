-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpass_CreateCasesForRenewalValidation
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpass_CreateCasesForRenewalValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpass_CreateCasesForRenewalValidation.'
	drop procedure dbo.cpass_CreateCasesForRenewalValidation
end
print '**** Creating procedure dbo.cpass_CreateCasesForRenewalValidation...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cpass_CreateCasesForRenewalValidation
(
		@psCountryCode		varchar(20)	= null,
		@psPropertyType		varchar(20)	= null,
		@pdtFilingDate		datetime	= null,
		@pdtRegistrationDate	datetime	= null,
		@pdtPriorityDate	datetime	= null,
		@pdtAcceptAdvDate	datetime	= null,
		@pnCPABatchNo		int		= null,
		@pbResetDatabase	bit		= 0,
		@pbRunPolicing		bit		= 1
)
AS
-- PROCEDURE :	cpass_CreateCasesForRenewalValidation
-- DESCRIPTION:	Generates test Cases and runs policing of Overview action (AS) in order to calculate
--		the renewal dates.  These Case details will then be compared against a second database
--		either with a different set of law calculations or with a different version of Policing.
-- NOTES:	
-- VERSION:	9
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 2003		CS		1	Procedure created
-- 11 Jan 2005	MF		2	Standardised into CPASS format and extended to cater for
--					VALIDCATEGORY and VALIDACTDATES
-- 09 Mar 2005	MF		3	Some Cases should be claiming convention.
-- 31 May 2005	MF	11431	4	Ensure that the test cases designed to test the latest laws
--					have a filing date of the system date - 2 days and a grant date
--					of the system date.
-- 16 Jun 2005	MF	11514	5	Ensure that the parent date pointed to by a child case does not have
--					a filing date that is after the filing date of the child.
-- 07 Jul 2005	MF	11011	6	Increase CaseCategory column size to NVARCHAR(2)
-- 29 May 2006	MF	12752	7	Changes to focus on the standard rules database.
-- 23 Aug 2006	MF	13298	8	Cases not being updated for Patents where the date of law was greater
--					than 20 years old.
-- 08 Nov 2018  AV  75198/DR-45358	9   Date conversion errors when creating cases and opening names in Chinese DB

Set nocount on
Set concat_null_yields_null off

CREATE TABLE #TempCases (
		CASEID			smallint identity(-2150,-1),
		IRN 			nvarchar (30)	collate database_default NOT NULL,
		STATUSCODE 		smallint	NULL,
		CASETYPE 		nchar (1)	collate database_default NOT NULL,
		PROPERTYTYPE 		nchar (1)	collate database_default NOT NULL,
		COUNTRYCODE 		nvarchar (3)	collate database_default NOT NULL,
		CASECATEGORY 		nvarchar (2)	collate database_default NULL,
		SUBTYPE 		nvarchar (2)	collate database_default NULL,
		TITLE 			nvarchar (254)	collate database_default NOT NULL,
		LOCALCLIENTFLAG 	decimal(1, 0)	NULL,
		ENTITYSIZE 		int		NULL,
		REPORTTOTHIRDPARTY 	decimal(1, 0)	NULL,
		OFFICEID		int		NULL,
		VALIDACTDATE		datetime	NULL
		)

CREATE table #TempCategory (
		PROPERTYTYPE		nchar(1)	collate database_default NOT NULL,
		COUNTRYCODE		nvarchar(3)	collate database_default NOT NULL,
		CASECATEGORY		nvarchar(2)	collate database_default NOT NULL,
		RELATIONSHIP		nvarchar(3)	collate database_default NULL,
		RELATIONSHIPNO		int		identity
		)

CREATE table #TempPolicing (
		POLICINGSEQNO		int		identity,
		CASEID			int		NOT NULL
 		)


declare @ErrorCode	int,
	@nRowCount	int,
	@TranCountStart int,
	@sSQLString	nvarchar(4000),
	@sSQLWhere	nvarchar(4000),
	@nBatchNo	smallint,
	@nSequenceNo	int,
	@sCountryCode 	nvarchar(3),
	@sPropertyType 	nchar(1)

Set @ErrorCode=0

set @sSQLString = NULL

-- Start the Transction

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
End

-- Ensure there is a unique SequenceNo for each VALIDACTDATE of the same
-- CountryCode and Propertytype
If @ErrorCode=0
Begin
	Set @nSequenceNo = 0
	Set @sCountryCode='ZZZ'
	Set @sPropertyType='Z'

	select * into #TEMPVALIDACTDATES
	from VALIDACTDATES
	order by COUNTRYCODE, PROPERTYTYPE

	Set @ErrorCode=0
	
	If @ErrorCode=0
	Begin
		Update #TEMPVALIDACTDATES
		Set 	@nSequenceNo = 
			Case When (@sCountryCode<>COUNTRYCODE OR @sPropertyType<>PROPERTYTYPE)
				Then 0
				Else @nSequenceNo + 1 
			End,
			SEQUENCENO = @nSequenceNo,
			@sCountryCode=COUNTRYCODE,
			@sPropertyType=PROPERTYTYPE
	
		Set  @ErrorCode=@@Error
	End

	if @ErrorCode=0
	Begin
		delete from VALIDACTDATES

		insert into VALIDACTDATES
		select * from #TEMPVALIDACTDATES		
	End
End

If  @pbResetDatabase=1
Begin
	If @ErrorCode=0
	Begin
		Delete from POLICINGLOG
		Set @ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		Delete from POLICING where SYSGENERATEDFLAG=1
		Set @ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		Delete from RELATEDCASE
		Set @ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		Delete from CASES
		Set @ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		delete from CPASEND
		Set @ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		delete from CPAUPDATE
		Set @ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		delete from CPARECEIVE
		Set @ErrorCode=@@Error
	End
End

-- Load the CaseCategory values that are used in the Renewal Sequencing Criteria so
-- that specific Cases are created for those Categories

If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TempCategory(PROPERTYTYPE, COUNTRYCODE,CASECATEGORY, RELATIONSHIP)
	select distinct C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, EC.FROMRELATIONSHIP
	from CRITERIA C
	left join EVENTCONTROL EC on (EC.CRITERIANO=C.CRITERIANO
				  and EC.FROMRELATIONSHIP is not null)
	where C.PURPOSECODE='E'
	and (C.ACTION in ('RS','AS') or C.ACTION like '~%')
	and C.CASECATEGORY is not null
	and C.PROPERTYTYPE is not null
	and C.COUNTRYCODE is not null"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Initialise the system to enable CPA to be sent cases
If @pnCPABatchNo is not null
Begin
	If @ErrorCode=0
	Begin
		-- Delete the Default Standing Renewal Instruction if it is
		-- not set to CPA Responsible (38)
	
		Delete NAMEINSTRUCTIONS
		From NAMEINSTRUCTIONS NI
		join SITECONTROL SC	on (SC.CONTROLID='HOMENAMENO'
					and SC.COLINTEGER=NI.NAMENO)
		join INSTRUCTIONS I	on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE
					and I.INSTRUCTIONTYPE='R')
		where NI.INSTRUCTIONCODE<>38
	
		Set  @ErrorCode=@@Error
	End
	
	If @ErrorCode=0
	Begin	
		-- Now insert the default Standing Renewal Instruction
		insert into NAMEINSTRUCTIONS(NAMENO, INTERNALSEQUENCE, INSTRUCTIONCODE)
		select	COLINTEGER,
			isnull((select max(INTERNALSEQUENCE)+1 from NAMEINSTRUCTIONS NI where NI.NAMENO=SC.COLINTEGER), 0),
			38
		from SITECONTROL SC
		left join NAMEINSTRUCTIONS I	on (I.NAMENO=SC.COLINTEGER
						and I.INSTRUCTIONCODE=38)
		where SC.CONTROLID = 'HOMENAMENO'
		and I.NAMENO is null
	
		Set  @ErrorCode=@@Error
	end
	
	If @ErrorCode=0
	Begin
		-- A CPA User Code of 'ZZZ' has been set up with CPA for test purposes
	
		update	SITECONTROL
		set	COLCHARACTER = 'ZZZ'
		where	CONTROLID = 'CPA User Code'
		and	(COLCHARACTER <> 'ZZZ' or COLCHARACTER is null)
	
		Set  @ErrorCode=@@Error
	end


	If  @ErrorCode=0
	Begin
		-- Reset the CPA Batch Number so that the requested one is used in the batch generation
	
		update	LASTINTERNALCODE
		set	INTERNALSEQUENCE = @pnCPABatchNo-1
		where	TABLENAME = 'CPASEND'
	
		Set  @ErrorCode=@@Error
	end
End

If @ErrorCode=0
Begin
	-- Increase the Policing Loop Count

	update	SITECONTROL
	set	COLINTEGER=100
	where	CONTROLID = 'Policing Loop Count'
	and	isnull(COLINTEGER,0)<>100

	Set  @ErrorCode=@@Error
end

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-- Begin the next Transaction

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
End

-- Insert all valid property combinations that have been set up.  A different CASEID is also
-- required for each CaseCategory and ValidActDate

If @ErrorCode=0
Begin
	Set @sSQLString=" 
	insert into #TempCases(IRN, STATUSCODE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID, VALIDACTDATE)
	select	distinct 
		C.COUNTRYCODE+VP.PROPERTYTYPE+'/'+convert(varchar,isnull(VD.SEQUENCENO,0)), 
		-210, 'A', VP.PROPERTYTYPE, C.COUNTRYCODE, NULL, NULL, 
		C.COUNTRYCODE+' '+VP.PROPERTYNAME+' Renewal rules validation',
		NULL, NULL, 1, NULL, 
			-- If the current date of law is the latest date held in the system
			-- then set the date of law to yesterdays date so that we are sure to 
			-- test against the latest laws.
		CASE WHEN(VD.DATEOFACT=VD1.CURRENTLAWDATE OR VD.DATEOFACT is null ) 
			THEN convert(varchar, dateadd(day,-2,getdate()),112) 
			-- If the current date of law is the earliest date and it is greater than 10
			-- years before the next law date then set the law to being 10 years before 
			-- the next law date
		     WHEN(VD.DATEOFACT=VD1.EARLIESTLAWDATE and datediff(yy,VD.DATEOFACT,VD2.DATEOFACT)>10)
			THEN convert(varchar, dateadd(year,-10,VD2.DATEOFACT),112)
			ELSE VD.DATEOFACT 
		END
	From	COUNTRY C
	join	VALIDPROPERTY VP	on (VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
							   from VALIDPROPERTY VP1
							   where VP1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	left join VALIDACTDATES VD	on (VD.COUNTRYCODE=C.COUNTRYCODE
					and VD.PROPERTYTYPE=VP.PROPERTYTYPE
					and VD.SEQUENCENO=( select min(VD1.SEQUENCENO)
							    from VALIDACTDATES VD1
							    where VD1.COUNTRYCODE=VP.COUNTRYCODE
							    and VD1.PROPERTYTYPE=VP.PROPERTYTYPE
							    and VD1.DATEOFACT=VD.DATEOFACT))
	left join (select COUNTRYCODE, PROPERTYTYPE, max(DATEOFACT) as CURRENTLAWDATE, min(DATEOFACT) as EARLIESTLAWDATE
		   from VALIDACTDATES
		   group by COUNTRYCODE, PROPERTYTYPE) VD1
					on (VD1.COUNTRYCODE=C.COUNTRYCODE
					and VD1.PROPERTYTYPE=VP.PROPERTYTYPE)

	left join VALIDACTDATES VD2	on (VD2.COUNTRYCODE=C.COUNTRYCODE
					and VD2.PROPERTYTYPE=VD.PROPERTYTYPE
					and VD2.DATEOFACT=(select min(DATEOFACT)
							   from VALIDACTDATES VD3
							   where VD3.COUNTRYCODE=VD2.COUNTRYCODE
							   and VD3.PROPERTYTYPE=VD2.PROPERTYTYPE
							   and VD3.DATEOFACT>VD1.EARLIESTLAWDATE))"
	
	Set @sSQLWhere = "
	where C.RECORDTYPE<3
	and C.DATECEASED is null
	and C.DATECOMMENCED<getdate()
	and C.COUNTRYCODE not in ('ZZZ','ZZY')
	and (VD.PROPERTYTYPE='T' OR VD2.DATEOFACT>dateadd(year,-20,getdate()) OR VD2.DATEOFACT is null)"

	If @psCountryCode is not null
	Begin
		Set @sSQLString=@sSQLString+"
		join dbo.fn_Tokenise(@psCountryCode, ',') CT on (CT.Parameter=C.COUNTRYCODE)"
	End

	If @psPropertyType is not null
	Begin
		Set @sSQLString=@sSQLString+"
		join dbo.fn_Tokenise(@psPropertyType, ',') P on (P.Parameter=VP.PROPERTYTYPE)"
	End
	Else Begin
		Set @sSQLWhere=@sSQLWhere+char(10)+"	and VP.PROPERTYTYPE in ('P','D','T')"
	End
	
	set @sSQLString = @sSQLString+char(10)+@sSQLWhere

	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@psCountryCode		varchar(20),
			  @psPropertyType		varchar(20)',
			  @psCountryCode,
			  @psPropertyType
End

-- Create a Category specific Case where required
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TempCases(IRN, STATUSCODE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID, VALIDACTDATE)
	select	replace(T.IRN,'/','/'+VC.CASECATEGORY+'/'), 
		T.STATUSCODE, T.CASETYPE, T.PROPERTYTYPE, T.COUNTRYCODE, VC.CASECATEGORY, T.SUBTYPE,
		T.TITLE+' '+VC.CASECATEGORYDESC, 
		T.LOCALCLIENTFLAG, T.ENTITYSIZE, T.REPORTTOTHIRDPARTY, T.OFFICEID, T.VALIDACTDATE
	From #TempCases T
	join VALIDCATEGORY VC	on (VC.CASETYPE='A'
				and VC.PROPERTYTYPE=T.PROPERTYTYPE
				and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)
						    from VALIDCATEGORY VC1
						    where VC1.CASETYPE='A'
						    and VC1.PROPERTYTYPE=T.PROPERTYTYPE
						    and VC1.COUNTRYCODE in ('ZZZ',T.COUNTRYCODE)))
	join (	select distinct PROPERTYTYPE, COUNTRYCODE, CASECATEGORY
		from #TempCategory) CC	
				on (CC.CASECATEGORY=VC.CASECATEGORY
				and CC.COUNTRYCODE=T.COUNTRYCODE
				and CC.PROPERTYTYPE=T.PROPERTYTYPE)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Now load the generated Cases into the live Case table.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASES(CASEID, IRN, STATUSCODE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID)
	select	CASEID, IRN, STATUSCODE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- The first set of Cases will be Registered so require a Registration Date and Registration No.
-- Insert Registration date
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASEEVENT(CASEID, EVENTNO, CYCLE, OCCURREDFLAG, EVENTDATE)
	select	CASEID, -8, 1, 1,
		coalesce(	@pdtRegistrationDate, 
				CASE WHEN(dateadd(month,17,VALIDACTDATE)<getdate())
					THEN dateadd(month,17,VALIDACTDATE)
					ELSE convert(varchar(11), getdate(),112)
				END
			)
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtRegistrationDate	datetime',
				  @pdtRegistrationDate=@pdtRegistrationDate
End

-- Insert Registration Number
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)
	select	CASEID, 'REG-'+IRN, 'R', 1
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Now for every Registered Case generated create another Case that is not yet Registered for non Trademarks.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TempCases(IRN, STATUSCODE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID, VALIDACTDATE)
	select IRN+'/APPLN', -202, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID, VALIDACTDATE
	From #TempCases
	Where PROPERTYTYPE <>'T'"

	Exec @ErrorCode=sp_executesql @sSQLString
End


-- Now load the new unregistered generated Cases into the live Case table
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASES(CASEID, IRN, STATUSCODE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID)
	select	CASEID, IRN, STATUSCODE, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
		TITLE, LOCALCLIENTFLAG, ENTITYSIZE, REPORTTOTHIRDPARTY, OFFICEID
	from	#TempCases
	where IRN like '%/APPLN'"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Load a Property row for each Case.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into PROPERTY(CASEID, BASIS)
	select	CASEID, 'N'
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Insert Application Number
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)
	select	CASEID, 'APP-'+IRN, 'A', 1
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Open the action sequencing
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into OPENACTION(CASEID, ACTION, CYCLE, POLICEEVENTS, DATEENTERED, DATEUPDATED)
	select	CASEID, 'AS', 1, 1, getdate(), getdate()
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Insert priority date
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASEEVENT(CASEID, EVENTNO, CYCLE, OCCURREDFLAG, EVENTDATE)
	select	CASEID, -1, 1, 1,
		coalesce(
				@pdtPriorityDate, 
				VALIDACTDATE, 
				convert(datetime, convert(char(4),year(getdate()))+'0101')
			)
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtPriorityDate	datetime',
				  @pdtPriorityDate=@pdtPriorityDate
End


-- Insert Filing date
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASEEVENT(CASEID, EVENTNO, CYCLE, OCCURREDFLAG, EVENTDATE)
	select	CASEID, -4, 1, 1,
		coalesce(@pdtFilingDate, T.VALIDACTDATE)
	from	#TempCases T"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtFilingDate	datetime',
				  @pdtFilingDate=@pdtFilingDate
End

-- Insert Publication of Application date
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASEEVENT(CASEID, EVENTNO, CYCLE, OCCURREDFLAG, EVENTDATE)
	select	CE.CASEID, -36, 1, 1,dateadd(day,1,CE.EVENTDATE)
	from #TempCases T
	join CASEEVENT CE	on (CE.CASEID=T.CASEID
				and CE.EVENTNO=-4)"

	Exec @ErrorCode=sp_executesql @sSQLString
End


-- Insert Acceptance Advertised date
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASEEVENT(CASEID, EVENTNO, CYCLE, OCCURREDFLAG, EVENTDATE)
	select	CASEID, -7, 1, 1,
		coalesce(	@pdtAcceptAdvDate, 
				CASE WHEN(dateadd(month,13,VALIDACTDATE)<getdate())
					THEN dateadd(month,13,VALIDACTDATE)
					ELSE convert(varchar(11),getdate(),112)
				END
			)
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtAcceptAdvDate	datetime',
				  @pdtAcceptAdvDate=@pdtAcceptAdvDate
End

-- Load a RelatedCase row for each Case that has a CaseCategory that requires a Relationship
-- Ensure the related Case is registered so that we can be sure that details will flow from the
-- parent case into the child case and also ensure that the Parent Case does NOT have a filing
-- date after the Child Case.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
	select T.CASEID, TC.RELATIONSHIPNO, TC.RELATIONSHIP, T1.CASEID
	from #TempCases T
	join #TempCategory TC	on (TC.CASECATEGORY=T.CASECATEGORY
				and TC.COUNTRYCODE=T.COUNTRYCODE
				and TC.PROPERTYTYPE=T.PROPERTYTYPE
				and TC.RELATIONSHIP is not null)
	join #TempCases T1	on (T1.CASEID=(	select min(T2.CASEID)
						from #TempCases T2
						where T2.COUNTRYCODE=T.COUNTRYCODE
						and T2.PROPERTYTYPE=T.PROPERTYTYPE
						and T2.CASECATEGORY is null
						and T2.STATUSCODE=-210))
	join CASEEVENT CE	on (CE.CASEID=T.CASEID
				and CE.EVENTNO=-4)
	join CASEEVENT CE1	on (CE1.CASEID=T1.CASEID
				and CE1.EVENTNO=-4
				and CE1.EVENTDATE<=CE.EVENTDATE)
	join CASES C1		on (C1.CASEID=T.CASEID)
	join CASES C2		on (C2.CASEID=T1.CASEID)
	left join RELATEDCASE R on (R.CASEID=T.CASEID
				and R.RELATIONSHIPNO=TC.RELATIONSHIPNO
				and R.RELATIONSHIP=TC.RELATIONSHIP)
	where R.CASEID is null"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Load a RelatedCase row for Cases that are claiming Priority
-- Point to a dummy Official number.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into RELATEDCASE(CASEID, RELATIONSHIPNO, RELATIONSHIP, OFFICIALNUMBER, COUNTRYCODE, PRIORITYDATE)
	select T.CASEID, isnull(RC.RELATIONSHIPNO,0)+1, 
		S.COLCHARACTER, 'P-'+IRN, T.COUNTRYCODE, 
		coalesce(	@pdtPriorityDate, 
				VALIDACTDATE, 
				convert(datetime, convert(char(4),year(getdate()))+'0101')
			)
	from #TempCases T
	join SITECONTROL S on (S.CONTROLID='EARLIEST PRIORITY')
	left join (	select CASEID, max(RELATIONSHIPNO) as RELATIONSHIPNO
			from RELATEDCASE
			group by CASEID) RC	on (RC.CASEID=T.CASEID)
	where S.COLCHARACTER is not null"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtPriorityDate	datetime',
					  @pdtPriorityDate=@pdtPriorityDate
End

-- Cases that have a RelatedCase are to have their Event Dates 
-- advanced by 1 days.  This is to simulate a Parent to Child
-- relationship of dates.  Only 1 day is being used because for
-- testing we have used the system date to try and get the latest
-- date possible into the system.
If @ErrorCode=0
Begin
	Set @sSQLString="
	update CASEEVENT
	set EVENTDATE=dateadd(day,1,EVENTDATE)
	from CASEEVENT CE
	where exists
	(select * from RELATEDCASE RC
	 where RC.CASEID=CE.CASEID
	 and RC.RELATEDCASEID is not null)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Insert Date of Entry
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASEEVENT(CASEID, EVENTNO, CYCLE, OCCURREDFLAG, EVENTDATE)
	select	T.CASEID, -13, 1, 1, 
		CASE WHEN(CE.EVENTDATE > dateadd(year, -1, getdate()))
			THEN dateadd(day,-4, CE.EVENTDATE)
			ELSE convert(varchar, getdate(),112)
		END
	from	#TempCases T
	join CASEEVENT CE	on (CE.CASEID=T.CASEID
				and CE.EVENTNO=-4)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Insert Instructor
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, ADDRESSCODE,BILLPERCENTAGE, INHERITED)
	select	CASEID, 'I', 502,0,NULL,NULL,0
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End


-- Insert Owner
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, ADDRESSCODE,BILLPERCENTAGE, INHERITED)
	select	CASEID, 'O', 502,0,502,NULL,0
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Insert debtor
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, ADDRESSCODE,BILLPERCENTAGE, INHERITED)
	select	CASEID, 'D', 502,0,NULL,100.00,1
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Insert RENEWAL INSTRUCTOR
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, ADDRESSCODE,BILLPERCENTAGE, INHERITED)
	select	CASEID, 'R', 502,0,NULL,NULL,1
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End


-- Insert RENEWAL DEBTOR
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, ADDRESSCODE,BILLPERCENTAGE, INHERITED)
	select	CASEID, 'Z', 502,0,NULL,100.00,1
	from	#TempCases"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

If  @pbRunPolicing=1
and @ErrorCode=0
Begin
	-- Begin the next Transaction
	
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	--
	-- Now place all Cases into the policing table, grab a batch number and police the batch of them.
	--
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TempPolicing(CASEID)
		select	CASEID
		from	#TempCases"
	
		Exec @ErrorCode=sp_executesql @sSQLString
		Set @nRowCount=@@Rowcount
	End
	
	if	@ErrorCode = 0
	and	@nRowCount > 0
	begin
		Set @sSQLString="
		Update LASTINTERNALCODE
		set INTERNALSEQUENCE=INTERNALSEQUENCE+1,
		    @nBatchNo      =INTERNALSEQUENCE+1
		where TABLENAME='POLICINGBATCH'"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nBatchNo	int	OUTPUT',
					  @nBatchNo=@nBatchNo	OUTPUT
	
		Set @nRowCount=@@Rowcount
	
		If @ErrorCode=0
		and @nRowCount=0
		Begin
			Set @sSQLString="
			Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE)
			values ('POLICINGBATCH', 01)"
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nBatchNo	int',
							  @nBatchNo=@nBatchNo
			
			set @nBatchNo=1
		End
	  end
	
	 If  @ErrorCode=0
	 and @nRowCount >0
	 Begin
		Set @sSQLString="
	 	insert into POLICING(	DATEENTERED, POLICINGSEQNO, POLICINGNAME,  
	 				SYSGENERATEDFLAG, ONHOLDFLAG, ACTION ,CYCLE, TYPEOFREQUEST,
	 				SQLUSER, CASEID, BATCHNO)
	 	select	getdate(), POLICINGSEQNO, convert(varchar,getdate(),126)+convert(varchar,POLICINGSEQNO), 
	 		1, 1, 'AS', 1, 1, SYSTEM_USER, CASEID, @nBatchNo
		from #TempPolicing"
		
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBatchNo	int',
						  @nBatchNo=@nBatchNo
	
		Set  @nRowCount =@@Rowcount
	End
	
	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
	
	-- Finally call Policing to process the batch just generated.
	If  @ErrorCode=0
	and @nRowCount >0
	and @nBatchNo is not null
	Begin
		exec @ErrorCode=dbo.ipu_Policing
					@pnBatchNo=@nBatchNo
	End
End

Return @ErrorCode
go

grant execute on dbo.cpass_CreateCasesForRenewalValidation to public
go

