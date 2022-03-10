-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ImportJournalNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ImportJournalNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ImportJournalNames.'
	Drop procedure [dbo].[ip_ImportJournalNames]
End
Print '**** Creating Stored Procedure dbo.ip_ImportJournalNames...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.ip_ImportJournalNames
			@pnBatchNo		int
AS

-- PROCEDURE :	ip_ImportJournalNames
-- VERSION :	14
-- DESCRIPTION:	Either creates or identifies existing Names that are to be linked to Cases
--
-- MODIFICATIONS :
-- Date		Who	SQA	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 18 May 2004	MF	9034	1	Procedure created
-- 19 Aug 2004	AB	8035	2	Add collate database_default syntax to temp tables.
-- 06 Jan 2005	MF	RFC2184	3	Performance problems with table variables on extremely large import batch.
--					Change to temporary table.
-- 14 Jan 2005	MF	10869	4	Allow the creation of Names against previously existing Cases
-- 04 Apr 2005	MF	11234	5	Ensure Names added to Cases maintain the same order that they appear
--					in the Import Journal.
-- 18 Jul 2005	MF	11642	6	Choose the first matching Name already existing on the database even if there
--					are multiple duplicate names available.
-- 21 Jul 2005	MF	11642	7	Revisit due to coding error.
-- 11 Nov 2005	MF	12051	8	Attempt to determine whether the Name is an Individual or Organisation by
--					examining the NameType associating the Name to the Case.  The NameType provides
--					a Picklist column which indicates if the Names are restricted to Individuals or
--					Organisations.
-- 1 Mar 2007	PY	SQA14425 9	Reserved word [alias]
-- 15 Jan 2008  DW	SQA9782	10	Tax No moved from Organisation to Names table
-- 06 May 2008	MF	SQA16357 11	Revisit SQA9782 to correct column name causing SQL Error.
-- 11 Dec 2008	MF	17136	12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 05 Jul 2013	vql	R13629	13	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	14   Date conversion errors when creating cases and opening names in Chinese DB

--
-- The transactions that have been catered for within this procedure are as follows :
--	NAME
--	NAME ALIAS
--	NAME COUNTRY
--	NAME STATE
--	NAME VAT NO


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

create table #TEMPCASENAMES  (	CASEID		int		not null,
				NAMETYPE	nvarchar(3)	collate database_default not null,
				NAMENO		int		null,
				NAME		nvarchar(254)	collate database_default not null,
				BATCHNO		int		not null,
				TRANSNO		int		not null,
				NEXTTRANSNO	int		null,
				ALIAS		nvarchar(254)	collate database_default null,
				ALIASTYPE	nvarchar(2)	collate database_default null,
				COUNTRYCODE	nvarchar(3)	collate database_default null,
				STATE		nvarchar(254)	collate database_default null,
				VATNO		nvarchar(254)	collate database_default null)

create table #TEMPNEWNAMES  (	NAMESEQUENCE	int		identity(0,1),
				NAME		nvarchar(254)	collate database_default not null,
				ALIAS		nvarchar(254)	collate database_default null,
				ALIASTYPE	nvarchar(2)	collate database_default null,
				COUNTRYCODE	nvarchar(3)	collate database_default null,
				STATE		nvarchar(254)	collate database_default null,
				VATNO		nvarchar(254)	collate database_default null,
				USEDASFLAG	tinyint		null  )

declare @nErrorCode 		int
declare	@nRowCount		int
declare	@nTranCountStart 	int
declare @nNewNames		int
declare @nNameNo		int
declare @nNewAddresses		int
declare	@nAddressCode		int

declare	@sSQLString 		nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement
Set @nErrorCode=0

-- Create a table of all of the Case and Name combinations required.  Also return the transaction
-- number of the next highest NAME transaction so we can get all of the other Name components
-- that are between the two transactions.

If @nErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPCASENAMES(CASEID,NAMETYPE,NAMENO,NAME, BATCHNO, TRANSNO, NEXTTRANSNO)
	Select I1.CASEID, I1.CHARACTERKEY, NULL, I1.CHARACTERDATA, I1.IMPORTBATCHNO, I1.TRANSACTIONNO,
		(select min(I2.TRANSACTIONNO)
		 from IMPORTJOURNAL I2
		 where I2.IMPORTBATCHNO=I1.IMPORTBATCHNO
		 and I2.TRANSACTIONTYPE='NAME'
		 and I2.CASEID=I1.CASEID
		 and I2.TRANSACTIONNO>I1.TRANSACTIONNO)
	from IMPORTJOURNAL I1
	join CASES C	on (C.CASEID=I1.CASEID)
	Where I1.IMPORTBATCHNO=@pnBatchNo
	and I1.TRANSACTIONTYPE='NAME'
	and I1.VALIDATEONLYFLAG in (0,2)
	-- to avoid duplicate name creation
	and I1.TRANSACTIONNO=(	select min(I3.TRANSACTIONNO)
				from IMPORTJOURNAL I3
				where I3.IMPORTBATCHNO=I1.IMPORTBATCHNO
				and I3.CASEID         =I1.CASEID
				and I3.TRANSACTIONTYPE=I1.TRANSACTIONTYPE
				and I3.CHARACTERKEY   =I1.CHARACTERKEY
				and I3.CHARACTERDATA  =I1.CHARACTERDATA)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
End

-- Now update the table with the other components of the Name that have been provided as transactions

If @nErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPCASENAMES
	Set	ALIAS      =I1.CHARACTERDATA, 
		ALIASTYPE  =I1.CHARACTERKEY, 
		COUNTRYCODE=I2.CHARACTERKEY, 
		STATE      =I3.CHARACTERDATA,
		VATNO      =I4.CHARACTERDATA
	from #TEMPCASENAMES CN
	-- We need to get the associated NAME ALIAS transaction
	left join IMPORTJOURNAL I1
				on (I1.IMPORTBATCHNO=CN.BATCHNO
				and I1.TRANSACTIONNO=(	select min(I.TRANSACTIONNO)
							from IMPORTJOURNAL I
							where I.IMPORTBATCHNO=CN.BATCHNO
							and I.CASEID=CN.CASEID
							and I.TRANSACTIONNO > CN.TRANSNO 
							and(I.TRANSACTIONNO < CN.NEXTTRANSNO OR CN.NEXTTRANSNO is NULL)
							and I.TRANSACTIONTYPE='NAME ALIAS'))
	-- We need to get the associated NAME COUNTRY transaction
	left join IMPORTJOURNAL I2	
				on (I2.IMPORTBATCHNO=CN.BATCHNO
				and I2.TRANSACTIONNO=(	select min(I.TRANSACTIONNO)
							from IMPORTJOURNAL I
							where I.IMPORTBATCHNO=CN.BATCHNO
							and I.CASEID=CN.CASEID
							and I.TRANSACTIONNO > CN.TRANSNO 
							and(I.TRANSACTIONNO < CN.NEXTTRANSNO OR CN.NEXTTRANSNO is NULL)
							and I.TRANSACTIONTYPE='NAME COUNTRY'))
	-- We need to get the associated NAME STATE transaction
	left join IMPORTJOURNAL I3	
				on (I3.IMPORTBATCHNO=CN.BATCHNO
				and I3.TRANSACTIONNO=(	select min(I.TRANSACTIONNO)
							from IMPORTJOURNAL I
							where I.IMPORTBATCHNO=CN.BATCHNO
							and I.CASEID=CN.CASEID
							and I.TRANSACTIONNO > CN.TRANSNO 
							and(I.TRANSACTIONNO < CN.NEXTTRANSNO OR CN.NEXTTRANSNO is NULL)
							and I.TRANSACTIONTYPE='NAME STATE'))
	-- We need to get the next NAME VAT NO transaction to determine the Name to be checked
	left join IMPORTJOURNAL I4
				on (I4.IMPORTBATCHNO=CN.BATCHNO
				and I4.TRANSACTIONNO=(	select min(I.TRANSACTIONNO)
							from IMPORTJOURNAL I
							where I.IMPORTBATCHNO=CN.BATCHNO
							and I.CASEID=CN.CASEID
							and I.TRANSACTIONNO > CN.TRANSNO 
							and(I.TRANSACTIONNO < CN.NEXTTRANSNO OR CN.NEXTTRANSNO is NULL)
							and I.TRANSACTIONTYPE='NAME VAT NO'))"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Now that we have a table of required Names, attempt to find a matching Name that
-- already exists in the database and that closely matches the characteristics of 
-- the Name from the Import Journal
If @nErrorCode=0
Begin

	Set @sSQLString="
	Update #TEMPCASENAMES
	Set NAMENO=N1.NAMENO
	from #TEMPCASENAMES CN
	join (	Select 	min(N.NAMENO) 	as NAMENO,
			UPPER(NULLIF(N.FIRSTNAME+' ',' ')+N.NAME)
					as NAME,
			NA.ALIASTYPE	as ALIASTYPE,
			NA.ALIAS	as [ALIAS],
			A.COUNTRYCODE	as COUNTRYCODE,
			A.STATE		as STATE,
			N.TAXNO		as VATNO
		from NAME N
		left join NAMEALIAS NA	 on (NA.NAMENO=N.NAMENO)
		left join ADDRESS A	 on (A.ADDRESSCODE=isnull(N.STREETADDRESS,N.POSTALADDRESS))
		where N.DATECEASED is null
		group by UPPER(NULLIF(N.FIRSTNAME+' ',' ')+N.NAME), NA.ALIASTYPE, NA.ALIAS, A.COUNTRYCODE, A.STATE, N.TAXNO) N1
				on (N1.NAME=UPPER(CN.NAME)
				and(N1.ALIASTYPE  =CN.ALIASTYPE   or CN.ALIASTYPE   is null)
				and(N1.ALIAS      =CN.ALIAS       or CN.ALIAS       is null)
				and(N1.COUNTRYCODE=CN.COUNTRYCODE or CN.COUNTRYCODE is null)
				and(N1.STATE      =CN.STATE       or CN.STATE       is null)
				and(N1.VATNO      =CN.VATNO       or CN.VATNO       is null))"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Now that we have linked already existing Names to some of the Names in the Import Journal
-- we will need to create new Names in the database for the distinct set of remaining names.

-- Commence by loading a separate table variable with the distinct set of new names.
If @nErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPNEWNAMES(NAME,ALIAS,ALIASTYPE,COUNTRYCODE,STATE,VATNO,USEDASFLAG)
	select distinct T.NAME,T.ALIAS,T.ALIASTYPE,T.COUNTRYCODE,T.STATE,T.VATNO,
			-- Attempt to determine how the Name is to be used
			-- depending upon the Name picklist associated with the
			-- NameType that links the Name to a Case.
			CASE(NT.PICKLISTFLAGS)
			  WHEN(1) THEN 1 -- Individual
			  WHEN(2) THEN 3 -- Staff
			  WHEN(3) THEN 1 -- Individual or staff
			  WHEN(4) THEN 4 -- Client (assume Organisation)
			  WHEN(5) THEN 5 -- Client individual
			  WHEN(6) THEN 0 -- Organisation
			  WHEN(7) THEN 0 -- Organisation
			  WHEN(8) THEN 0 -- Organisation
			  WHEN(9) THEN 0 -- Organisation
			  WHEN(10)THEN 0 -- Organisation
			  WHEN(11)THEN 0 -- Organisation
				  ELSE 4 -- Client Organisation
			END
	from #TEMPCASENAMES T
	join NAMETYPE NT on (NT.NAMETYPE=T.NAMETYPE)
	where T.NAMENO is null"

	exec @nErrorCode=sp_executesql @sSQLString

	Set @nNewNames=@@Rowcount
End

-- If there are new Names to create then Begin a transaction to create these Names

If  @nErrorCode=0
and @nNewNames>0
Begin
	-- Now start a new transaction
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Now reserve a NAMENO for each of the about to be created Names by incrementing 
	-- the LASTINTERNALCODE table
	set @sSQLString="
		UPDATE LASTINTERNALCODE 
		SET INTERNALSEQUENCE = INTERNALSEQUENCE + @nNewRows,
		    @nLastRow        = INTERNALSEQUENCE + @nNewRows
		WHERE  TABLENAME = @sTableName"

	Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nLastRow	int	OUTPUT,
					  @nNewRows	int,
					  @sTableName	varchar(30)',
					  @nLastRow=@nNameNo	OUTPUT,
					  @nNewRows=@nNewNames,
					  @sTableName='NAME'

	-- Now reserve a ADDRESSCODE for each of the about to be created Addresses by incrementing 
	-- the LASTINTERNALCODE table.  Of course there may not be an address created for each
	-- Name however for ease and speed of processing just assume that there will be.
	If @nErrorCode=0
	Begin
		-- Note that @sSQLString is the same as previously set
		Exec @nErrorCode=sp_executesql @sSQLString, 
						N'@nLastRow	int		OUTPUT,
						  @nNewRows	int,
						  @sTableName	varchar(30)',
						  @nLastRow=@nAddressCode	OUTPUT,
						  @nNewRows=@nNewNames,
						  @sTableName='ADDRESS'
	End

	-- Create an ADDRESS row for each Name that has specified the Country.
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into ADDRESS(ADDRESSCODE, STATE, COUNTRYCODE)
		select  @nAddressCode-N.NAMESEQUENCE, N.STATE, N.COUNTRYCODE
		from #TEMPNEWNAMES N
		join COUNTRY C	  on (C.COUNTRYCODE=N.COUNTRYCODE)
		left join STATE S on (S.COUNTRYCODE=N.COUNTRYCODE
				  and S.STATE      =N.STATE)
		where (S.STATE is not null OR N.STATE is null)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nAddressCode	int',
						  @nAddressCode=@nAddressCode

		Set @nNewAddresses=@@Rowcount
	End

	-- Now insert a row into the NAME table for each new Name
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into NAME(NAMENO, STREETADDRESS, NAME, SEARCHKEY1, SOUNDEX, DATECHANGED, DATEENTERED, USEDASFLAG, TAXNO)
		select  @nNameNo-N.NAMESEQUENCE, 
			CASE WHEN(N.COUNTRYCODE is not null) THEN @nAddressCode-N.NAMESEQUENCE ELSE NULL END,
			N.NAME, upper(ltrim(left(N.NAME,20))),NULL, getdate(), getdate(),N.USEDASFLAG, N.VATNO
		from #TEMPNEWNAMES N"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameNo	int,
						  @nAddressCode	int',
						  @nNameNo=@nNameNo,
						  @nAddressCode=@nAddressCode

		Set @nErrorCode=@@Error
	End

	-- Now insert a row into the ORGANISATION table for each new Name
	-- with UsedAsFlag of 0 or 4
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into ORGANISATION(NAMENO)
		select  @nNameNo-N.NAMESEQUENCE
		from #TEMPNEWNAMES N
		where N.USEDASFLAG in (0,4)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameNo	int',
						  @nNameNo=@nNameNo
	End

	-- Now insert a row into the INDIVIDUAL table for each new Name
	-- with UsedAsFlag of 1, 3 or 5
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into INDIVIDUAL(NAMENO)
		select  @nNameNo-N.NAMESEQUENCE
		from #TEMPNEWNAMES N
		where N.USEDASFLAG in (1,3,5)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameNo	int',
						  @nNameNo=@nNameNo
	End

	-- Now insert a row into the IPNAME table for each new Name
	-- with UsedAsFlag of 4 or 5
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into IPNAME(NAMENO, LOCALCLIENTFLAG)
		select  NM.NAMENO, 
			CASE WHEN(A.COUNTRYCODE=S.COLCHARACTER) THEN 1 ELSE 0 END
		from #TEMPNEWNAMES N
		join NAME NM		on (NM.NAMENO=@nNameNo-N.NAMESEQUENCE)
		left join ADDRESS A	on (A.ADDRESSCODE=NM.STREETADDRESS)
		left join SITECONTROL S	on (S.CONTROLID='HOMECOUNTRY')
		where N.USEDASFLAG in (4,5)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameNo	int',
						  @nNameNo=@nNameNo
	End

	-- Now insert a row into the EMPLOYEE table for each new Name
	-- with UsedAsFlag of 3
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into EMPLOYEE(EMPLOYEENO, STARTDATE)
		select  @nNameNo-N.NAMESEQUENCE, convert(nvarchar, getdate(), 112)
		from #TEMPNEWNAMES N
		where N.USEDASFLAG = 3"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameNo	int',
						  @nNameNo=@nNameNo
	End

	-- Now link each Name to the Address created
	If  @nErrorCode=0
	and @nNewAddresses>0
	Begin
		Set @sSQLString="
		Insert into NAMEADDRESS(NAMENO, ADDRESSTYPE, ADDRESSCODE, OWNEDBY)
		select	@nNameNo-N.NAMESEQUENCE, 302, @nAddressCode-N.NAMESEQUENCE, 1
		from #TEMPNEWNAMES N
		join NAME NM	on (NM.NAMENO    =@nNameNo     -N.NAMESEQUENCE)
		join ADDRESS A	on (A.ADDRESSCODE=@nAddressCode-N.NAMESEQUENCE)"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameNo	int,
						  @nAddressCode	int',
						  @nNameNo=@nNameNo,
						  @nAddressCode=@nAddressCode
	End

	-- Commit transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-- Finally link each Case to the Name in the database by inserting a CASENAME
If  @nErrorCode=0
Begin
	-- Now start a new transaction
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Insert into CASENAME(CASEID, NAMETYPE, NAMENO, ADDRESSCODE, SEQUENCE)
		select	CN.CASEID, CN.NAMETYPE, NM.NAMENO, NM.STREETADDRESS,
			(select count(*)
			 from #TEMPCASENAMES CN1
			 where CN1.CASEID=CN.CASEID
			 and CN1.NAMETYPE=CN.NAMETYPE
			 and CN1.TRANSNO <CN.TRANSNO)	--SQA11234
		from #TEMPCASENAMES CN
		left join #TEMPNEWNAMES N	on ( N.NAME=CN.NAME
					and (N.ALIAS      =CN.ALIAS       OR (N.ALIAS       is null and CN.ALIAS       is null))
					and (N.ALIASTYPE  =CN.ALIASTYPE   OR (N.ALIASTYPE   is null and CN.ALIASTYPE   is null))
					and (N.COUNTRYCODE=CN.COUNTRYCODE OR (N.COUNTRYCODE is null and CN.COUNTRYCODE is null))
					and (N.STATE      =CN.STATE       OR (N.STATE       is null and CN.STATE       is null))
					and (N.VATNO      =CN.VATNO       OR (N.VATNO       is null and CN.VATNO       is null)))
		join NAME NM		on (NM.NAMENO=isnull(CN.NAMENO, @nNameNo-N.NAMESEQUENCE))
		left join CASENAME CN1	on (CN1.CASEID=CN.CASEID
					and CN1.NAMETYPE=CN.NAMETYPE
					and CN1.NAMENO=NM.NAMENO)
		where CN1.CASEID is null -- to only insert rows that do not already exist"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNameNo	int',
						  @nNameNo=@nNameNo
	End

	-- Commit transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

RETURN @nErrorCode
go
grant execute on dbo.ip_ImportJournalNames to public
go