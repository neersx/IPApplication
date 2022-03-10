-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ImportJournalRelatedCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ImportJournalRelatedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ImportJournalRelatedCases.'
	Drop procedure [dbo].[ip_ImportJournalRelatedCases]
End
Print '**** Creating Stored Procedure dbo.ip_ImportJournalRelatedCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.ip_ImportJournalRelatedCases
			@pnBatchNo		int
AS
-- PROCEDURE :	ip_ImportJournalRelatedCases
-- VERSION :	5
-- DESCRIPTION:	Creates relationship either to an existing Case on the database or
--		records details of the Number, Country and Date.
--
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 21 May 2004	MF	9034	1	Procedure created
-- 28 Aug 2004	AB	8035	2	Add collate database_default syntax to temp tables.
-- 16 Nov 2004	MF	RFC2184	3	Performance problems with table variables on extremely large import batch.
--					Change to temporary table.  Also there was a duplicate key error where more
--					than one relationship for a Case was being inserted.
-- 14 Jan 2005	MF	10869	4	Allow the creation of Related Cases against previously existing Cases
-- 24 Jul 2009	MF	16548	5	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
--
-- The transactions that have been catered for within this procedure are as follows :
--	RELATED NUMBER
--	RELATED COUNTRY
--	RELATED DATE

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

create table #TEMPRELATEDCASES (CASEID		int		not null,
				RELATIONSHIPNO	smallint	null,
				RELATIONSHIP	nvarchar(3)	collate database_default not null,
				RELATEDCASEID	int		null,
				OFFICIALNUMBER	nvarchar(36)	collate database_default not null,
				BATCHNO		int		not null,
				TRANSNO		int		not null,
				NEXTTRANSNO	int		null,
				RELATEDDATE	datetime	null,
				COUNTRYCODE	nvarchar(3)	collate database_default null  )

declare @nErrorCode 		int
declare	@nRowCount		int
declare	@nTranCountStart 	int
declare @nCaseId		int
declare @nRelationshipNo	int

declare	@sSQLString 		nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement
Set @nErrorCode=0

-- Create a table of all of the Related Case details to be created.
-- Get the number of the next highest RELATED NUMBER transaction so we can get all of the other 
-- Related Case components that are between the two transactions.

If @nErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPRELATEDCASES(CASEID,RELATIONSHIP, OFFICIALNUMBER, BATCHNO, TRANSNO, NEXTTRANSNO)
	Select I1.CASEID, I1.CHARACTERKEY, I1.CHARACTERDATA, I1.IMPORTBATCHNO, I1.TRANSACTIONNO,
		(select min(I2.TRANSACTIONNO)
		 from IMPORTJOURNAL I2
		 where I2.IMPORTBATCHNO=I1.IMPORTBATCHNO
		 and I2.TRANSACTIONTYPE='RELATED NUMBER'
		 and I2.CASEID=I1.CASEID
		 and I2.TRANSACTIONNO>I1.TRANSACTIONNO)
	from IMPORTJOURNAL I1
	join CASES C	on (C.CASEID=I1.CASEID)
	Where I1.IMPORTBATCHNO=@pnBatchNo
	and I1.TRANSACTIONTYPE='RELATED NUMBER'
	and I1.VALIDATEONLYFLAG in (0,2)
	-- to avoid duplicate relationship creation
	and I1.TRANSACTIONNO=(	select min(I3.TRANSACTIONNO)
				from IMPORTJOURNAL I3
				where I3.IMPORTBATCHNO=I1.IMPORTBATCHNO
				and I3.CASEID         =I1.CASEID
				and I3.TRANSACTIONTYPE=I1.TRANSACTIONTYPE
				and I3.CHARACTERKEY   =I1.CHARACTERKEY
				and I3.CHARACTERDATA  =I1.CHARACTERDATA)
	order by 1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
End

-- Now update the table with the other components of the Related Case that have been provided as transactions

If @nErrorCode=0
Begin
	Set @nRelationshipNo=1
	Set @nCaseId=-999999999

	Set @sSQLString="
	Update #TEMPRELATEDCASES
	Set	RELATEDDATE=I1.DATEDATA, 
		COUNTRYCODE=I2.CHARACTERDATA,
		RELATIONSHIPNO=@nRelationshipNo,
		-- Increment the RelationshipNo if the CASEID is the same as the
		-- previous CASEID otherwise reset it to 1
		@nRelationshipNo=Case When(RC.CASEID=@nCaseId) Then @nRelationshipNo+1 Else 1 End,
		-- Save the CASEID for use in the data comparison.
		@nCaseId=RC.CASEID
	from #TEMPRELATEDCASES RC
	left join IMPORTJOURNAL I1
				on (I1.IMPORTBATCHNO=RC.BATCHNO
				and I1.TRANSACTIONNO=(	select min(I.TRANSACTIONNO)
							from IMPORTJOURNAL I
							where I.IMPORTBATCHNO=RC.BATCHNO
							and I.CASEID=RC.CASEID
							and I.TRANSACTIONNO > RC.TRANSNO 
							and(I.TRANSACTIONNO < RC.NEXTTRANSNO OR RC.NEXTTRANSNO is null)
							and I.TRANSACTIONTYPE='RELATED DATE'))
	left join IMPORTJOURNAL I2	
				on (I2.IMPORTBATCHNO=RC.BATCHNO
				and I2.TRANSACTIONNO=(	select min(I.TRANSACTIONNO)
							from IMPORTJOURNAL I
							where I.IMPORTBATCHNO=RC.BATCHNO
							and I.CASEID=RC.CASEID
							and I.TRANSACTIONNO > RC.TRANSNO 
							and(I.TRANSACTIONNO < RC.NEXTTRANSNO OR RC.NEXTTRANSNO is null)
							and I.TRANSACTIONTYPE='RELATED COUNTRY'))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nRelationshipNo	int	output,
					  @nCaseId		int	output',
					  @nRelationshipNo=@nRelationshipNo	output,	
					  @nCaseId=@nCaseId			output
End

-- Now that we have a table of Related Cases, attempt to find a matching CaseId
-- to cater for Cases that already exist on the database.

If @nErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPRELATEDCASES
	Set RELATEDCASEID=C.CASEID
	from #TEMPRELATEDCASES RC
	join CASERELATION CR	on (CR.RELATIONSHIP=RC.RELATIONSHIP)
	join CASES C		on (C.CURRENTOFFICIALNO=RC.OFFICIALNUMBER
				and C.COUNTRYCODE=RC.COUNTRYCODE)
	left join CASEEVENT CE	on (CE.CASEID=C.CASEID
				and CE.EVENTNO=CR.FROMEVENTNO
				and CE.CYCLE=1)
	Where (CE.EVENTDATE=RC.RELATEDDATE OR RC.RELATEDDATE is NULL)"

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Now load the Related Cases.

If  @nErrorCode=0
Begin
	-- Now start a new transaction
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Finally link each Case to the Name in the database by inserting a CASENAME
	Set @sSQLString="
	Insert into RELATEDCASE(CASEID, RELATIONSHIP, RELATEDCASEID, OFFICIALNUMBER, COUNTRYCODE, PRIORITYDATE,RELATIONSHIPNO)
	select	RC.CASEID, RC.RELATIONSHIP, RC.RELATEDCASEID, 
		CASE WHEN(RC.RELATEDCASEID is NULL) THEN RC.OFFICIALNUMBER END,
		CASE WHEN(RC.RELATEDCASEID is NULL) THEN RC.COUNTRYCODE    END,
		CASE WHEN(RC.RELATEDCASEID is NULL) THEN RC.RELATEDDATE    END,
		RC.RELATIONSHIPNO+ isnull((select max(RC2.RELATIONSHIPNO)
		 			   from RELATEDCASE RC2
					   where RC2.CASEID=RC.CASEID),0)
	from #TEMPRELATEDCASES RC
	left join RELATEDCASE RC1	on (RC1.CASEID=RC.CASEID
					and RC1.RELATIONSHIP=RC.RELATIONSHIP
					and (RC1.RELATEDCASEID=RC.RELATEDCASEID or (RC1.RELATEDCASEID is null and RC.RELATEDCASEID is null))
					and (RC1.OFFICIALNUMBER=RC.OFFICIALNUMBER or (RC1.OFFICIALNUMBER is null and RC.OFFICIALNUMBER is null))
					and (RC1.COUNTRYCODE=RC.COUNTRYCODE or (RC1.COUNTRYCODE is null and RC.COUNTRYCODE is null)))
	where RC1.CASEID is null -- ensure the row being inserted does not already exist"

	exec @nErrorCode=sp_executesql @sSQLString

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
grant execute on dbo.ip_ImportJournalRelatedCases to public
go