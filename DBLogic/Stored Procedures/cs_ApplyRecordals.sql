-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ApplyRecordals
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ApplyRecordals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.cs_ApplyRecordals.'
	Drop procedure [dbo].[cs_ApplyRecordals]
end
Print '**** Creating Stored Procedure dbo.cs_ApplyRecordals...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO
Set ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.cs_ApplyRecordals
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLRecordals		ntext,		-- XML string containing change details to apply to cases
	@pnRecordalCaseId	int,		-- The Recordal Case Id
	@pdtRecordalDate	datetime,	-- The recordal date
	@psRecordalStatus	nvarchar(20),	-- Recordal completion status.  ie. 'Recorded'
	@pbPolicingImmediate bit

)
as
-- PROCEDURE:	cs_ApplyRecordals
-- VERSION:	23
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	- Apply the recordals (stored on the recordal case) to the live cases.
--		- Update the status of recordal step against cases to 'Recorded'.
--		- Create CASEEVENT rows for the events linked to the recordal steps and cases.
--		- Create POLICING rows for those cases with an event.
--
-- MODIFICATIONS :
-- Date		Who	Change	 	Version	Description
-- -----------	----- 	-------- 	-------	----------------------------------------------- 
-- 21 Dec 2005	JB    	SQA10666 	1	Procedure created.
-- 29 Dec 2005  DL    	SQA10666 	2	Handling address change and policing.
-- 09 Jan 2006	AB	SQA11574	3	Add collate database_default to temp tables.
-- 20 Jan 2006  DL	SQA10666	4	Bugs fix.
-- 02 Jun 2006	MF	SQA12315,	5	These 3 SQAs are being addressed by changing the stored procedure
--			SQA12317,		so that it calls cs_GlobalNameChange to apply the recordal changes.
--			SQA12327		This is a better way of addressing these changes as it centralises
--						the code and also takes care of monitoring for changes to Standing 
--						Instructions.
-- 14 Jul 2006	DL	SQA12315	6	Fixed syntax errors.	
-- 31 Oct 2006	Dev	SQA12900	7	Set the ONHOLD flag in the POLICING table to 0		
-- 22 Nov 2006 DL	SQA13355	8	Fixed a syntax error where ISNULL() function is missing a second parameter
-- 27-Nov-2006	MF	13919		3	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--						by ignoring the value or ErrorCode
-- 05-Jan-2007	DL	SQA12900	10	Added param @pbPolicingImmediate and call ipu_Policing() if @pbPolicingImmediate = 1
-- 01-Feb-2007	DL	SQA12901	11	Force action associated with the recordal type to be opened against the affected case.
-- 28 Feb 2007	PY	SQA14425	12	Reserved word [sequence]
-- 06 Mar 2007	DL	SQA12901	13	reopen closed action.
-- 06 Nov 2007	DL	SQA15532	14	Old owner entries assigned incorrect sequence number.
-- 04 Feb 2008	DL	SQA15179	15	If @pbPolicingImmediate is off and workflow's event is flagged for immediate processing
--						then process the workflow request immediately.     
-- 13 Dec 2007 DL	SQA15490	15	Fix a bug when getting policing batch number
-- 19 May 2008 DL	SQA15490	16	Only replace specific old owners instead of all old owners.
-- 11 Dec 2008	MF	17136		17	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Jul 2009	AC	17246		18	Recordal step is being applied even though it is unselected
-- 22 Nov 2010	vql	18349		19	When re-assigning a case back to a previous owner, the owner name appears to disappear.
-- 19 Jul 2017	MF	71968		20	When determining the default Case program, first consider the Profile of the User.
-- 22 Aug 2017	MF	72214		21	Ensure POLICING rows are written with the IdentityId and start Policing with the same IdentityId.
-- 13 Sep 2017	KR	72393		22	Removed setting expiry date for old owner - name type 'K'
-- 14 May 2019	DL	DR-46512	23	Incorrect final Owner when more than 1 recordal step applied at the same time

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

-- A temporary table to load all of the possible global name changes that will be required
CREATE TABLE #TEMPGLOBALNAMECHANGES(
		NEWNAMENO	int		NOT NULL,
		NEWREFERENCE	nvarchar(80)	collate database_default NULL,
		NEWATTENTION	int		NULL,
		NEWADDRESSCODE	int		NULL,
		COMMENCEDATE	datetime	NULL,
		SEQUENCENO	int		identity(1,1)
 )

-- A temporary table to store the Cases that are to have the global name change applied
CREATE TABLE #TEMPCASESFORNAMECHANGE(
		CASEID		int		NOT NULL
 )

-- Raw data as extracted from input XML.  It contains untokenized nameno list.
Create Table #TEMPRECORDALSRAW (
		CASEID		int,
		STEPNO 		int,
	  	ELEMENTCODE 	nvarchar(50)	collate database_default,
		NAMETYPE 	nvarchar(3) 	collate database_default,
		NAMENOLIST	nvarchar(254)	collate database_default,
		ADDRESSCODE 	int,
		RECORDALDATE 	datetime,
		SEQUENCENO 	int,
		EVENTNO		int,
		RECACTION 	nvarchar(2) 	collate database_default,
		EDITATTRIBUTE	nvarchar(3) 	collate database_default,
		CHANGEOWNERFLAG	int,
		RECORDALTYPENO	int,
		ROWPOSITION 	int IDENTITY(1,1) )

-- Base temp recordal table containing rows extracted from the input XML with rows containing multiple owners splitted into individual row
Create Table #TEMPRECORDALS (
		CASEID		int,
		STEPNO 		int,
	  	ELEMENTCODE 	nvarchar(50)	collate database_default,
		NAMETYPE 	nvarchar(3) 	collate database_default,
		NAMENO 		int,
		ADDRESSCODE 	int,
		RECORDALDATE 	datetime,
		SEQUENCENO 	int,
		EVENTNO		int,
		RECACTION 	nvarchar(2) 	collate database_default,
		EDITATTRIBUTE	nvarchar(3) 	collate database_default,
		CHANGEOWNERFLAG	int,
		RECORDALTYPENO	int,
		ROWPOSITION 	int IDENTITY(1,1) ) 

-- DR-46512 Handle one step processing at a time
Create Table #TEMPRECORDALS1 (
		CASEID		int,
		STEPNO 		int,
	  	ELEMENTCODE 	nvarchar(50)	collate database_default,
		NAMETYPE 	nvarchar(3) 	collate database_default,
		NAMENO 		int,
		ADDRESSCODE 	int,
		RECORDALDATE 	datetime,
		SEQUENCENO 	int,
		EVENTNO		int,
		RECACTION 	nvarchar(2) 	collate database_default,
		EDITATTRIBUTE	nvarchar(3) 	collate database_default,
		CHANGEOWNERFLAG	int,
		RECORDALTYPENO	int,
		ROWPOSITION 	int IDENTITY(1,1) ) 

-- temp working table 
Create Table #TEMPRECORDALS2 (
 		CASEID		int,
		STEPNO 		int,
          	ELEMENTCODE 	nvarchar(50)	collate database_default,
		NAMETYPE 	nvarchar(3)	collate database_default,
		NAMENO 		int,
		ADDRESSCODE 	int,
		RECORDALDATE 	datetime,
		EVENTNO		int,
		RECACTION 	nvarchar(2)	collate database_default,
		ROWPOSITION 	int IDENTITY(1,1) )

-- temp working table to enable the creation of events and policing for all affected cases
Create Table #TEMPRECORDALS3 (
 		CASEID		int,
		RECORDALDATE 	datetime,
		EVENTNO		int,
		RECACTION 	nvarchar(2)	collate database_default,
		ROWPOSITION 	int IDENTITY(1,1) )

Declare @nDocHandle 		int
Declare @nErrorCode		int
Declare @TranCountStart		int
Declare @nRowCount		int
Declare @nGlobalChanges		int
Declare @nCaseCount		int
Declare @nCurrentRow		int
Declare	@sSQLString		nvarchar(4000)
Declare @sLastNameType		nvarchar(3)
Declare @sLastCaseId		int
Declare @nCaseId		int
Declare @nStepNo		int
Declare @nLastStepNo		int
Declare @sElementCode		nvarchar(50)
Declare @sNameType		nvarchar(3)
Declare @nNameNo		int
Declare @nAddressCode		int
Declare @dtRecordalDate		datetime
Declare @nSequenceNo		int
Declare @nEventNo		int
Declare @nSequence		int
Declare @nCycle			int
Declare @nPolicingSeqNo 	int
Declare @nCriteriaNo		int
Declare @sRecAction		nvarchar(2)

Declare @nNamesUpdatedCount	int
Declare @nNamesInsertedCount	int
Declare @nNamesDeletedCount	int
Declare @sProgramId		nvarchar(8)
Declare @nNewNameNo		int
Declare @nNewAttention		int
Declare @nNewAddressCode	int
Declare @nKeepReferenceNo	tinyint
Declare @sNewReference		nvarchar(80)
Declare @dtCommenceDate		datetime
Declare @bOnHoldFlag		bit
Declare @nPolicingBatchNo	int
Declare @bActionOpened		bit
Declare @bEventPolicingImmediateFlag bit
Declare @sNameNoList		nvarchar(254)
Declare @nMaxStepNo			int				-- DR-46512

Set @nErrorCode=0

If @nErrorCode=0
Begin
	-- Get a handle for the XML (required for OPENXML)
	exec sp_xml_preparedocument @nDocHandle OUTPUT, @ptXMLRecordals

	-- Move the data into a table variable (which has an identity column)
	Set @sSQLString="
	Insert into #TEMPRECORDALSRAW 
	Select    *
	from OPENXML (@nDocHandle, '/RecordalCase/Cases/Case',1)
        	with (	CaseId	int,
			StepNo 	int,
                  	ElementCode nvarchar(50),
			NameType nvarchar(3),
			NameNo nvarchar(254),
			AddressCode int,
			RecordalDate datetime,
			SequenceNo int,
			EventNo int,
			RecAction nvarchar(2),
			EditAttribute nvarchar(3),
			ChangeOwnerFlag int,
			RecordalTypeNo int )"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@nDocHandle	int',
					  @nDocHandle=@nDocHandle 

	Set @nRowCount = @@ROWCOUNT

	exec sp_xml_removedocument @nDocHandle
End

----------- Split rows with multiple names into separate rows  -----------------------------
If @nErrorCode = 0
Begin
	-- first copy rows with single nameno in the NAMENOLIST column
	Set @sSQLString="
		Insert into #TEMPRECORDALS (CASEID, STEPNO, ELEMENTCODE, NAMETYPE, NAMENO, ADDRESSCODE, RECORDALDATE, SEQUENCENO, EVENTNO, RECACTION, EDITATTRIBUTE, CHANGEOWNERFLAG, RECORDALTYPENO)
		Select CASEID, STEPNO, ELEMENTCODE, NAMETYPE, NAMENOLIST, ADDRESSCODE, RECORDALDATE, SEQUENCENO, EVENTNO, RECACTION, EDITATTRIBUTE, CHANGEOWNERFLAG, RECORDALTYPENO
		from #TEMPRECORDALSRAW
		where CHARINDEX( ',', isnull(NAMENOLIST,'') ) = 0"
	exec @nErrorCode=sp_executesql @sSQLString

	-- split rows with multiple nameno into separate rows for each nameno
	set @nCurrentRow = 0
	While 1=1 and @nErrorCode = 0
	Begin
		Set @sSQLString="
			Select top 1 @nCurrentRow=ROWPOSITION, @sNameNoList=NAMENOLIST 
			from #TEMPRECORDALSRAW
			where CHARINDEX( ',', isnull(NAMENOLIST,'') ) > 0 and ROWPOSITION > @nCurrentRow "
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCurrentRow	int		OUTPUT,
					  @sNameNoList  nvarchar(254)	OUTPUT',
					  @nCurrentRow = @nCurrentRow	OUTPUT,
					  @sNameNoList = @sNameNoList	OUTPUT

		If  @@ROWCOUNT = 0
			Break

		Set @sSQLString="
			Insert into #TEMPRECORDALS (CASEID, STEPNO, ELEMENTCODE, NAMETYPE, NAMENO, ADDRESSCODE, RECORDALDATE, SEQUENCENO, EVENTNO, RECACTION, EDITATTRIBUTE, CHANGEOWNERFLAG, RECORDALTYPENO)
			Select CASEID, STEPNO, ELEMENTCODE, NAMETYPE, Parameter, ADDRESSCODE, RECORDALDATE, SEQUENCENO, EVENTNO, RECACTION, EDITATTRIBUTE, CHANGEOWNERFLAG, RECORDALTYPENO
			from #TEMPRECORDALSRAW
			cross join fn_Tokenise( @sNameNoList, ',')
			where ROWPOSITION = @nCurrentRow"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sNameNoList  nvarchar(254),
					  @nCurrentRow	int',
					  @sNameNoList = @sNameNoList,
					  @nCurrentRow = @nCurrentRow	
	End
End

------------- Process Change of Owners-----------------
-- DR-46512 handle one step processing at a time.
Select @nMaxStepNo = MAX(STEPNO) FROM #TEMPRECORDALS
Set @nStepNo=1
Select @TranCountStart = @@TranCount
BEGIN TRANSACTION

While @nStepNo<=@nMaxStepNo
	and @nErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPRECORDALS1 (CASEID, STEPNO, ELEMENTCODE, NAMETYPE, NAMENO, ADDRESSCODE, RECORDALDATE, SEQUENCENO, EVENTNO, RECACTION, EDITATTRIBUTE, CHANGEOWNERFLAG, RECORDALTYPENO)
	select CASEID, STEPNO, ELEMENTCODE, NAMETYPE, NAMENO, ADDRESSCODE, RECORDALDATE, SEQUENCENO, EVENTNO, RECACTION, EDITATTRIBUTE, CHANGEOWNERFLAG, RECORDALTYPENO
	from #TEMPRECORDALS 
	where STEPNO = @nStepNo
	"
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nStepNo		int',
					@nStepNo		=@nStepNo

	If @nErrorCode = 0
	Begin
   		-- Change SPECIFIED Current owners to Old Owners (NameType='K') this is deliberately being done as a Copy rather
		-- than just updating the NAMETYPE as we need the original owners to remain so that
		-- global name change functionality can be used to replace the current Owners with the
		-- new owners.

		Set @sSQLString="
		insert into CASENAME(	CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPONDNAME, ADDRESSCODE, REFERENCENO, 
					ASSIGNMENTDATE, COMMENCEDATE, BILLPERCENTAGE, INHERITED, INHERITEDNAMENO, 
					INHERITEDRELATIONS, INHERITEDSEQUENCE, NAMEVARIANTNO,DERIVEDCORRNAME)
		select	distinct
			CN.CASEID,'K',CN.NAMENO,isnull(CN2.SEQUENCE,-1)+CN.SEQUENCE+1,CN.CORRESPONDNAME,CN.ADDRESSCODE,CN.REFERENCENO,
			CN.ASSIGNMENTDATE,CN.COMMENCEDATE,CN.BILLPERCENTAGE,CN.INHERITED,CN.INHERITEDNAMENO,
			CN.INHERITEDRELATIONS,CN.INHERITEDSEQUENCE,CN.NAMEVARIANTNO,CN.DERIVEDCORRNAME
		from CASENAME CN
		join #TEMPRECORDALS1 T on (T.CASEID=CN.CASEID
				   and T.NAMETYPE=CN.NAMETYPE
				   and T.NAMENO = CN.NAMENO
						   and T.ELEMENTCODE='CURRENTNAME'
				   and T.EDITATTRIBUTE = 'DIS'
				   and T.CHANGEOWNERFLAG = 1)
		left join CASENAME CN1	on (CN1.CASEID  =CN.CASEID
					and CN1.NAMETYPE='ON'
					and CN1.NAMENO  =CN.NAMENO
					and CN1.EXPIRYDATE is null)
		left join (select CASEID, NAMETYPE, isnull(max(SEQUENCE),-1) as [SEQUENCE]
			   from CASENAME
				where NAMETYPE='K'
			   group by CASEID, NAMETYPE) CN2
					on (CN2.CASEID  =T.CASEID)
		Where CN.NAMETYPE='O'
		-- Copy not required if the New Owner (nametype='ON') already exists as the Current Owner (nametype='O')
		and CN1.CASEID is null"

		Exec @nErrorCode = sp_executesql @sSQLString

		-- To ensure that inheritance and standing instruction changes are considered with the change 
		-- of owner, the Case global name change functionality will be used to apply the changes.
	
		If @nErrorCode=0
		Begin
			-- Get a unique set of Name changes that will form the basis of the Case global
			-- name change
			-- 17246
			Set @sSQLString="
			insert into #TEMPGLOBALNAMECHANGES(NEWNAMENO, NEWREFERENCE, NEWATTENTION, NEWADDRESSCODE, COMMENCEDATE)
			select distinct CN.NAMENO, CN.REFERENCENO, CN.CORRESPONDNAME, CN.ADDRESSCODE, T.RECORDALDATE
			from CASENAME CN
			join #TEMPRECORDALS1 T 	on (T.CASEID       =CN.CASEID
						and T.NAMETYPE     ='O'
						and T.ELEMENTCODE  ='NEWNAME'
						and T.EDITATTRIBUTE='MAN'
						and	T.NAMENO	   = CN.NAMENO)
			where CN.NAMETYPE = 'ON'"

			Exec @nErrorCode = sp_executesql @sSQLString

			Set @nGlobalChanges=@@RowCount
		End

		If  @nErrorCode=0
		and @nGlobalChanges>0
		Begin
			-- Need to get a default Case program which is required 
			-- by Global Name Change to determine what inherited 
			-- Name types are allowed

			Set @sSQLString="
			Select @sProgramId=left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8)
			from SITECONTROL S
				 join USERIDENTITY U        on (U.IDENTITYID=@pnUserIdentityId)
			left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
							and PA.ATTRIBUTEID=2)	-- Default Cases Program
			where S.CONTROLID='Case Screen Default Program'"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@sProgramId		nvarchar(8)	OUTPUT,
						  @pnUserIdentityId	int',
						  @sProgramId      =@sProgramId		OUTPUT,
						  @pnUserIdentityId=@pnUserIdentityId
		End

		-- Now loop through each Global Name Change to be performed 
		Set @nSequenceNo=0
	
		While @nSequenceNo<@nGlobalChanges
		  and @nErrorCode=0
		Begin
			-- Increment the sequence to get each Global Name Change to be performed
			Set @nSequenceNo=@nSequenceNo+1
	
			-- Extract the details for the specific global name change
			Set @sSQLString="
			Select	@nNewNameNo  	 =NEWNAMENO,
				@nNewAttention	 =NEWATTENTION,
				@nNewAddressCode =NEWADDRESSCODE,
				@sNewReference	 =NEWREFERENCE,
				@dtCommenceDate	 =COMMENCEDATE
			from #TEMPGLOBALNAMECHANGES
			where SEQUENCENO=@nSequenceNo"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		int,
						  @nNewNameNo		int			OUTPUT,
						  @nNewAttention	int			OUTPUT,
						  @nNewAddressCode	int			OUTPUT,
						  @sNewReference	nvarchar(80)		OUTPUT,
						  @dtCommenceDate	datetime		OUTPUT',
						  @nSequenceNo		=@nSequenceNo,
						  @nNewNameNo		=@nNewNameNo		OUTPUT,
						  @nNewAttention	=@nNewAttention		OUTPUT,
						  @nNewAddressCode	=@nNewAddressCode	OUTPUT,
						  @sNewReference	=@sNewReference		OUTPUT,
						  @dtCommenceDate	=@dtCommenceDate	OUTPUT

			-- Now we need to load a temporary table with the Cases that
			-- are to be updated by the global name change
			If @nErrorCode=0
			Begin
				Set @sSQLString="
				insert into #TEMPCASESFORNAMECHANGE(CASEID)
				select distinct T.CASEID
				from CASENAME CN
				join #TEMPRECORDALS1 T 	on (T.CASEID       =CN.CASEID
							and T.NAMETYPE     ='O'
							and T.ELEMENTCODE  ='NEWNAME'
							and T.EDITATTRIBUTE='MAN')
				where CN.NAMETYPE = 'ON'
				and CN.NAMENO         = @nNewNameNo
				and(CN.CORRESPONDNAME = @nNewAttention   or(CN.CORRESPONDNAME is null and @nNewAttention   is null))
				and(CN.ADDRESSCODE    = @nNewAddressCode or(CN.ADDRESSCODE    is null and @nNewAddressCode is null))
				and(CN.REFERENCENO    = @sNewReference   or(CN.REFERENCENO    is null and @sNewReference   is null))
				-- Ignore entries where the change has already been applied
				and not exists
				(select 1 from CASENAME CN1
				 where CN1.CASEID=CN.CASEID
				 and CN1.NAMETYPE='O'
				 and CN1.NAMENO=CN.NAMENO
				 and CN1.EXPIRYDATE is null)"
		
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@nNewNameNo		int,
						  @nNewAttention	int,
						  @nNewAddressCode	int,
						  @sNewReference	nvarchar(80)',
						  @nNewNameNo	  =@nNewNameNo,
						  @nNewAttention  =@nNewAttention,
						  @nNewAddressCode=@nNewAddressCode,
						  @sNewReference  =@sNewReference

				Set @nCaseCount=@@Rowcount
			End

			-- Now execute the global name change if there are
			-- Cases to change
			If  @nErrorCode=0
			and @nCaseCount>0
			Begin
				If @sNewReference is null
					set @nKeepReferenceNo=2
				else
					set @nKeepReferenceNo=3

				exec @nErrorCode=dbo.cs_GlobalNameChange
							@pnNamesUpdatedCount	=@nNamesUpdatedCount	OUTPUT,
							@pnNamesInsertedCount	=@nNamesInsertedCount	OUTPUT,
							@pnNamesDeletedCount	=@nNamesDeletedCount	OUTPUT,
							-- Filter Parameters
							@psGlobalTempTable	='#TEMPCASESFORNAMECHANGE',
							@psProgramId		= @sProgramId,
							@psNameType		= 'O',		-- Changing Owners
							-- Change Details
							@pnNewNameNo		= @nNewNameNo,	 -- the replacement Name.  If null then deletion is required.
							@pnNewCorrespondName	= @nNewAttention,-- the replacement Correspondence Name.
							-- Options
							@pbUpdateName		= 0,		-- indicates that existing Names are to be changed
							@pbInsertName		= 1,		-- indicates that the Name is to be inserted if it does not already exist
							@pnKeepReferenceNo	= @nKeepReferenceNo,
							@pbApplyInheritance	= 1,		-- indicates that changed NAMETYPE is to have a cascading inheritance
							@psReferenceNo		= @sNewReference,-- the new reference number for the new name.
							@pbSuppressOutput	= 1,
							@pdtCommenceDate	= @dtCommenceDate,
							@pnAddressCode		= @nNewAddressCode
	
				-- Clear out the Cases from the last global name change
				-- in preparation to reload with the next set of Cases to update
				If  @nErrorCode=0
				and @nSequenceNo<@nGlobalChanges
				Begin
					Set @sSQLString="delete from #TEMPCASESFORNAMECHANGE"
	
					exec @nErrorCode=sp_executesql @sSQLString
				End
			End
		End	-- end of loop through Global Name Changes

		---------------------------------------------------------
		-- Delete the NEWOWNER details
		---------------------------------------------------------

		-- If the CaseName changes have successfully been made
		-- then delete the CASENAME rows from the database
		-- We are not going to use the Global Name Change for this
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			delete CASENAME
			from CASENAME CN
			join #TEMPRECORDALS1 T 	on (T.CASEID       =CN.CASEID
						and T.NAMETYPE     ='O'
						and T.ELEMENTCODE  ='NEWNAME'
						and T.EDITATTRIBUTE='MAN')
			where CN.NAMETYPE = 'ON'
			and exists
			(select 1 from CASENAME CN1
			 where CN1.CASEID=CN.CASEID
			 and CN1.NAMETYPE='O'
			 and CN1.NAMENO=CN.NAMENO
			 and CN1.EXPIRYDATE is null)"

			Exec @nErrorCode=sp_executesql @sSQLString
		End

		---------------------------------------------------------
		-- Delete the SELECTED CURRENT OWNER details
		---------------------------------------------------------

		-- If the CaseName changes have successfully been made
		-- then delete the CASENAME rows from the database
		-- We are not going to use the Global Name Change for this
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			delete CASENAME
			from CASENAME CN
			join #TEMPRECORDALS1 T 	on (T.CASEID       =CN.CASEID
						and T.NAMETYPE     ='O'
						and T.ELEMENTCODE  ='CURRENTNAME'
						and T.EDITATTRIBUTE='DIS'
						and T.CHANGEOWNERFLAG = 1
						and T.NAMENO = CN.NAMENO)
			where CN.NAMETYPE = 'O'
			and exists
			(select 1 from CASENAME CN1
			 where CN1.CASEID=CN.CASEID
			 and CN1.NAMETYPE='K'
			 and CN1.NAMENO=CN.NAMENO)"

			Exec @nErrorCode=sp_executesql @sSQLString
		End
	End

	-- DR-46512 Reset temp tables to process next recordal step
	set @nStepNo = @nStepNo + 1
	truncate table #TEMPRECORDALS1
	truncate table #TEMPGLOBALNAMECHANGES
	delete from #TEMPCASESFORNAMECHANGE
End -- loop change of owner for each step

------------- Process other type of changes ie. NAME, STREET ADDRESS, POSTAL ADDRESS-------------

If @nErrorCode = 0
Begin
	Set @sSQLString="
	Insert into #TEMPRECORDALS2 (CASEID, STEPNO, ELEMENTCODE, NAMETYPE, NAMENO, ADDRESSCODE, RECORDALDATE, EVENTNO, RECACTION )
	select CASEID, STEPNO, ELEMENTCODE, NAMETYPE, NAMENO, ADDRESSCODE, RECORDALDATE, EVENTNO, RECACTION
	from #TEMPRECORDALS
	where  (ELEMENTCODE != 'NEWNAME' OR NAMETYPE != 'O') 
		and CASEID != 0
		and EDITATTRIBUTE = 'MAN' 
	order by CASEID, STEPNO"

	Exec @nErrorCode=sp_executesql @sSQLString
   
	Set @nRowCount = @@ROWCOUNT
End

Set @nCurrentRow = 1
Set @nLastStepNo = NULL
Set @sLastCaseId = NULL

While @nErrorCode = 0 
and   @nCurrentRow <= @nRowCount
Begin
	Set @sSQLString="
	Select	@nCaseId 	= CASEID,
		@nStepNo 	= STEPNO,
		@sElementCode 	= ELEMENTCODE, 
		@sNameType 	= NAMETYPE,
		@nNameNo	= NAMENO,
		@nAddressCode	= ADDRESSCODE,
		@dtRecordalDate = RECORDALDATE
	from #TEMPRECORDALS2
	where ROWPOSITION = @nCurrentRow"

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nCaseId		int		OUTPUT,
				  @nStepNo		int		OUTPUT,
				  @sElementCode		nvarchar(50)	OUTPUT,
				  @sNameType		nvarchar(3)	OUTPUT,
				  @nNameNo		int		OUTPUT,
				  @nAddressCode		int		OUTPUT,
				  @dtRecordalDate	datetime	OUTPUT,
				  @nCurrentRow		int',
				  @nCaseId		=@nCaseId	OUTPUT,
				  @nStepNo		=@nStepNo	OUTPUT,
				  @sElementCode		=@sElementCode	OUTPUT,
				  @sNameType		=@sNameType	OUTPUT,
				  @nNameNo		=@nNameNo	OUTPUT,
				  @nAddressCode		=@nAddressCode	OUTPUT,
				  @dtRecordalDate	=@dtRecordalDate OUTPUT,
				  @nCurrentRow		=@nCurrentRow

	
	If  @sElementCode = 'NEWNAME' 
	and @nErrorCode = 0 
	Begin
		-- Remove all of the old CaseName row for this CHANGE
		If (@sLastCaseId != @nCaseId ) 
		OR (@nLastStepNo != @nStepNo) 
		OR (@sLastCaseId IS NULL)
		Begin
			Set @sSQLString="
			Delete from CASENAME 
			where CASEID = @nCaseId 
			AND NAMETYPE = @sNameType"

			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCaseId	int,
						  @sNameType	nvarchar(3)',
						  @nCaseId =@nCaseId,
						  @sNameType=@sNameType

			-- Save the last values
		    	Set @nLastStepNo = @nStepNo
			Set @sLastCaseId = @nCaseId
		End
	
		-- Insert new name.
		
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			Insert into CASENAME (CASEID,   NAMENO,   NAMETYPE,   [SEQUENCE])
			Select C.CASEID, @nNameNo, @sNameType, isnull(CN.SEQUENCE,-1)+1
			From CASES C
			left join (select CASEID, NAMETYPE, isnull(MAX([SEQUENCE]),-1) as [SEQUENCE]
				   from CASENAME
				   group by CASEID, NAMETYPE) CN
					on (CN.CASEID=C.CASEID
					and CN.NAMETYPE=@sNameType)
			Where C.CASEID=@nCaseId"
		
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCaseId	int,
						  @nNameNo	int,
						  @sNameType	nvarchar(3)',
						  @nCaseId  =@nCaseId,
						  @nNameNo  =@nNameNo,
						  @sNameType=@sNameType
		End
	
	End /* if Change NAME */
	
	Else if (@sElementCode = 'NEWPOSTALADDRESS' OR @sElementCode = 'NEWSTREETADDRESS') 
	     and @nErrorCode = 0 
	Begin 
		Set @sSQLString="
		Update CASENAME
		Set ADDRESSCODE = @nAddressCode
		Where CASEID = @nCaseId 
		and NAMETYPE = @sNameType
		and NAMENO = @nNameNo"

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCaseId	int,
					  @nNameNo	int,
					  @sNameType	nvarchar(3),
					  @nAddressCode	int',
					  @nCaseId     =@nCaseId,
					  @nNameNo     =@nNameNo,
					  @sNameType   =@sNameType,
					  @nAddressCode=@nAddressCode
	end
	
	-- next row index
	Set @nCurrentRow = @nCurrentRow + 1

End /* LOOP Change other */

--------------- Update the status of the Recordal Steps/Cases to Recorded -----------------------
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Update RECORDALAFFECTEDCASE
	set 	STATUS     = @psRecordalStatus,
		RECORDDATE = @pdtRecordalDate
	where CASEID = @pnRecordalCaseId 
	and SEQUENCENO in (select distinct SEQUENCENO from #TEMPRECORDALS)"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@psRecordalStatus	nvarchar(20),
				  @pdtRecordalDate	datetime,
				  @pnRecordalCaseId	int',
				  @psRecordalStatus=@psRecordalStatus,
				  @pdtRecordalDate =@pdtRecordalDate,
				  @pnRecordalCaseId=@pnRecordalCaseId
End

------------------- Update/Insert CASEEVENT and POLICING -----------------------------
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Insert into #TEMPRECORDALS3 (CASEID, RECORDALDATE, EVENTNO, RECACTION )
	select distinct CASEID, RECORDALDATE, EVENTNO, RECACTION
	from #TEMPRECORDALS
	where  CASEID != 0 
	AND EVENTNO != 0"

	Exec @nErrorCode=sp_executesql @sSQLString
	
	Set @nRowCount = @@ROWCOUNT
End


-- Determine if the events to be policed has POLICEIMMEDIATE flag enabled.
-- If so then get a batchno so that these events will be police immediately even if the @pbPolicingImmediate = 0
set @bEventPolicingImmediateFlag = 0
If @nErrorCode = 0 and @pbPolicingImmediate = 0
Begin
	Set @sSQLString="
		Select @bEventPolicingImmediateFlag = case when count(*) > 0 then 1 else 0 end
		from #TEMPRECORDALS3 T
		join EVENTS E on E.EVENTNO = T.EVENTNO
		WHERE E.POLICINGIMMEDIATE = 1"
	Exec @nErrorCode=sp_executesql @sSQLString, 
			N'@bEventPolicingImmediateFlag bit OUTPUT',
			  @bEventPolicingImmediateFlag = @bEventPolicingImmediateFlag OUTPUT
End



-- Get policing batch number if policing immediately
Set @nPolicingBatchNo = null
If @nErrorCode = 0 and ( @pbPolicingImmediate = 1 or @bEventPolicingImmediateFlag = 1)
Begin
	Set @sSQLString="
		Update LASTINTERNALCODE 
		set INTERNALSEQUENCE = INTERNALSEQUENCE+1,
			 @nPolicingBatchNo = INTERNALSEQUENCE+1
		where TABLENAME = 'POLICINGBATCH'"
	Exec @nErrorCode=sp_executesql @sSQLString, 
			N'@nPolicingBatchNo int OUTPUT',
			  @nPolicingBatchNo = @nPolicingBatchNo OUTPUT
End


Set @nCurrentRow = 1
Set @nPolicingSeqNo = 0
While @nErrorCode = 0 and   @nCurrentRow <= @nRowCount
Begin
	Set @sSQLString="
	Select	@nCaseId       = T.CASEID,
  		@dtRecordalDate= T.RECORDALDATE,
  		@nEventNo      = T.EVENTNO,
  		@sRecAction    = T.RECACTION,
		@bEventPolicingImmediateFlag = E.POLICINGIMMEDIATE
	from #TEMPRECORDALS3 T
	join EVENTS E on E.EVENTNO = T.EVENTNO
	where ROWPOSITION = @nCurrentRow"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nCaseId		int		OUTPUT,
				  @dtRecordalDate	datetime	OUTPUT,
				  @nEventNo		int		OUTPUT,
				  @sRecAction		nvarchar(2)	OUTPUT,
				  @bEventPolicingImmediateFlag bit	OUTPUT,  
				  @nCurrentRow		int',
				  @nCaseId	 =@nCaseId		OUTPUT,
				  @dtRecordalDate=@dtRecordalDate	OUTPUT,
				  @nEventNo      =@nEventNo		OUTPUT,
				  @sRecAction    =@sRecAction		OUTPUT,
				  @bEventPolicingImmediateFlag = @bEventPolicingImmediateFlag OUTPUT,
				  @nCurrentRow   =@nCurrentRow
	
	If @nErrorCode=0
	Begin
		Set @nCycle = NULL
		
		Set @sSQLString="
		Select @nCycle = CYCLE 
		from CASEEVENT 
		where CASEID= @nCaseId 
		and EVENTNO = @nEventNo 
		and CYCLE=(select MAX(CYCLE) 
		 	   from CASEEVENT 
			   where CASEID = @nCaseId 
			   and EVENTNO = @nEventNo )"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCycle	smallint	OUTPUT,
					  @nCaseId	int,
					  @nEventNo	int',
					  @nCycle	=@nCycle	OUTPUT,
					  @nCaseId	=@nCaseId,
					  @nEventNo	=@nEventNo
	End

	If @nErrorCode=0
	Begin
		If @nCycle is not null
		Begin
			Set @sSQLString="
			Update CASEEVENT 
			Set EVENTDATE   = @dtRecordalDate,
			    OCCURREDFLAG=1
			where CASEID= @nCaseId 
			and EVENTNO = @nEventNo 
			and CYCLE   = @nCycle"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCycle		smallint,
					  @nCaseId		int,
					  @nEventNo		int,
					  @dtRecordalDate	datetime',
					  @nCycle	 =@nCycle,
					  @nCaseId	 =@nCaseId,
					  @nEventNo	 =@nEventNo,
					  @dtRecordalDate=@dtRecordalDate
		End
		Else Begin
			Set @sSQLString="
			Insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
			values (@nCaseId, @nEventNo, 1, @dtRecordalDate, 1)"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int,
						  @nEventNo		int,
						  @dtRecordalDate	datetime',
						  @nCaseId	 =@nCaseId,
						  @nEventNo	 =@nEventNo,
						  @dtRecordalDate=@dtRecordalDate
			
			Set @nCycle = 1
		End
	End


	-- Open the action if it is not opened for this case
	If @nErrorCode = 0 
	Begin
		Set @bActionOpened = 0

		-- is action opened?
		Set @sSQLString="
		Select @bActionOpened = 1 from OPENACTION 
		where CASEID = @nCaseId
		and 	ACTION = @sRecAction
		and	CYCLE = @nCycle
		and POLICEEVENTS = 1"

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@bActionOpened 	bit output,
					  @nCaseId			int,
					  @sRecAction		nvarchar(2),
					  @nCycle			smallint',
					  @bActionOpened 	= @bActionOpened output, 
					  @nCaseId			= @nCaseId,
					  @sRecAction		= @sRecAction,
					  @nCycle			= @nCycle


		-- open the action
		If @nErrorCode = 0  and @bActionOpened = 0
		Begin
			If @pbPolicingImmediate = 1
				Set @bOnHoldFlag = 1
			Else
				Set @bOnHoldFlag = 0
	
			Set @sSQLString="
			Insert into POLICING(BATCHNO, DATEENTERED, POLICINGSEQNO, POLICINGNAME, 
				ACTION, SYSGENERATEDFLAG, ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
			values ( @nPolicingBatchNo, getdate(), @nPolicingSeqNo, convert(varchar, getdate(), 121)+' '+convert(varchar,@nPolicingSeqNo), 
				@sRecAction, 1, @bOnHoldFlag, @nEventNo, @nCaseId, @nCycle, 1, SYSTEM_USER, NULL )"
	
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nPolicingBatchNo int,
						  @nPolicingSeqNo	int,
						  @sRecAction		nvarchar(2),
						  @bOnHoldFlag	bit,	
						  @nEventNo		int,
						  @nCaseId		int,
						  @nCycle		smallint',
						  @nPolicingBatchNo = @nPolicingBatchNo, 
						  @nPolicingSeqNo	=@nPolicingSeqNo,
						  @sRecAction		=@sRecAction,
						  @bOnHoldFlag	=@bOnHoldFlag,
						  @nEventNo		=@nEventNo,
						  @nCaseId		=@nCaseId,
						  @nCycle		=@nCycle
	
			Set @nPolicingSeqNo = @nPolicingSeqNo + 1
		End
	End	



	-- Add policing row for the case	
	If @nErrorCode = 0
	Begin
		If @pbPolicingImmediate = 1 OR @bEventPolicingImmediateFlag = 1
			Set @bOnHoldFlag = 1
		Else
			Set @bOnHoldFlag = 0

		Set @sSQLString="
		Insert into POLICING(BATCHNO, DATEENTERED, POLICINGSEQNO, POLICINGNAME, 
			ACTION, SYSGENERATEDFLAG, ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		values ( @nPolicingBatchNo, getdate(), @nPolicingSeqNo, convert(varchar, getdate(), 121)+' '+convert(varchar,@nPolicingSeqNo), 
			@sRecAction, 1, @bOnHoldFlag, @nEventNo, @nCaseId, @nCycle, 3, SYSTEM_USER, @pnUserIdentityId )"

		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPolicingBatchNo int,
					  @nPolicingSeqNo	int,
					  @sRecAction		nvarchar(2),
					  @bOnHoldFlag	bit,	
					  @nEventNo		int,
					  @nCaseId		int,
					  @nCycle		smallint,
					  @pnUserIdentityId	int',
					  @nPolicingBatchNo = @nPolicingBatchNo, 
					  @nPolicingSeqNo	=@nPolicingSeqNo,
					  @sRecAction		=@sRecAction,
					  @bOnHoldFlag	=@bOnHoldFlag,
					  @nEventNo		=@nEventNo,
					  @nCaseId		=@nCaseId,
					  @nCycle		=@nCycle,
					  @pnUserIdentityId	=@pnUserIdentityId

		Set @nPolicingSeqNo = @nPolicingSeqNo + 1
	End
	
	-- next row index
	Set @nCurrentRow = @nCurrentRow + 1
   
End  /* WHILE LOOP UPDATE CASEEVENT */


-- run policing if @pbPolicingImmediate = 1
If ((@pbPolicingImmediate = 1 OR @bEventPolicingImmediateFlag = 1) and @nErrorCode = 0 and @nRowCount > 0)
Begin
	exec @nErrorCode=dbo.ipu_Policing
			@pdtPolicingDateEntered 	= null,
			@pnPolicingSeqNo 		= null,
			@pnDebugFlag			= 0,
			@pnBatchNo			= @nPolicingBatchNo,
			@psDelayLength			= null,
			@pnUserIdentityId		= @pnUserIdentityId,
			@psPolicingMessageTable		= null
End


-- Commit the transaction if it has successfully completed
If @@TranCount > @TranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End


RETURN @nErrorCode
go

Grant execute on dbo.cs_ApplyRecordals to public
GO
