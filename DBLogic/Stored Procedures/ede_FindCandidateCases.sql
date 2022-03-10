-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_FindCandidateCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ede_FindCandidateCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure ede_FindCandidateCases.'
	Drop procedure [dbo].[ede_FindCandidateCases]
End
Print '**** Creating Stored Procedure ede_FindCandidateCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE [dbo].[ede_FindCandidateCases]
			@pnRowCount		int=0	OUTPUT,
			@pnBatchNo		int,			-- mandatory
			@psTransactionId	nvarchar(254)	=null,	-- find Cases for a specific Transaction
			@pnDraftCaseId		int		=null,	-- find Cases for a specific draft Case
			@psRequestorNameType	nvarchar(3)	=null,	-- the Requestor Name Type if already known
			@pnSenderNameNo		int		=null,	-- the Sender Name No if already known
			@pbDraftCaseSearch	bit		=0,	-- Search for draft Cases instead of live
			@psRequestType		nvarchar(50)	=null,	-- The request type of the sender
			@pnFamilyNo		int		=null	-- Family of SenderNameNo
			
AS
-- PROCEDURE :	ede_FindCandidateCases
-- VERSION :	29
-- SCOPE:	CPA Inprotech
-- DESCRIPTION:	Returns a list of candidate Cases for a given transaction.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 06 Sep 2006	MF	12413	1	Procedure created
-- 21 Sep 2006	MF	12413	2	Official number does not have to be mandatory for the match
-- 22 Sep 2006	MF	12413	3	Provide an option to force the search for draft CasesTypes
-- 25 Sep 2006	MF	12413	4	Return an additional flag to indicate that a future Name
--					exists against the Case for either Instructor or RequestorNameType.
-- 09 Oct 2006	MF	12413	5	Allow NAMESEQUENCENUMBER to be null in match
-- 24 Oct 2006	MF	13706	6	Improve matching performance
-- 14 Nov 2006	MF		7	Further performance improvements
-- 02 Jan 2007	AT	13473	8	Renamed Transaction Producer to Alternative Sender.
-- 15 Feb 2007	MF	13967	9	Ensure duplicate candidate Case rows are not returned by adding
--					a DISTINCT to the final SELECT.
-- 19 Feb 2007	MF	13967	10	If a candidate Case row appears multiple times because it is attached
--					against different requestors, then only return the best match.
-- 12 Dec 2007	DL	15686	11	Add isnull to aggregate functions to eliminate warning error.
-- 20 Mar 2008	MF	16120	12	Match on IRN if no RECEIVERCASEREFERENCE is supplied but there is a
--					match on CASEID.
-- 25 Mar 2008	MF	16140	13	Matching on Official Numbers is to not consider if the number is
--					current or not.
-- 31 Mar 2008	MF	16159	14	When matching is allowed on draft Cases, exclude any draft Case created in the
--					same batch being processed.
-- 21 Apr 2008	MF	16260	15	The Matching Criteria algorithm for matching case imported with a live case 
--					should be changed so that it matches on any official number regardless of the 
--					number type.
-- 21 Oct 2008	MF	17020	16	No candidate cases were being returned even though there was a match on the 
--					data instructor's reference.
-- 24 Oct 2008	MF	17020	17	Revisit to handle when CASEID supplied but no IRN supplied by user and also if
--					Instructor for Case not supplied then treat as a match.
-- 19 Dec 2008	MF	17231	18	Rename #TEMPCASES to #TEMPMATCH. Discovered that a calling procedure was already
--					using #TEMPCASES and after renaming also found loading the new temp table resolved
--					a performance problem. 
-- 04 Mar 2009	MF	17462	19	Case matching should only consider numbers received by EDE where the number type
--					of the official number is flagged as being issued by IP office
-- 11 Mar 2009	MF	17146	20	If Instructor is not supplied in import then it will default to the sender of the
--					batch and the instructor reference defaults to the sender case reference. This
--					same defaulting rule is to be applied when matching on Instructor and Instructor
--					reference.
-- 25 Mar 2009	MF	17462	21	Revisit. Change caused problem with dynamic SQL when search on draft case required.
--					Expand all @sSQLString variables to nvarchar(2000)
-- 26 Mar 2009	MF	17537	20	EDE loading has slowed down since restricting Case matching to only consider IP Office 
--					official numbers. Reduce the complexity of the SQL by embedding a list of the specific
--					number types to be considered rather than join twice to the NUMBERTYPES table.
-- 31 Mar 2009	MF	17146	21	Revisit. This substitution should only occur when SENDERREQUESTTYPE = 'Data Input'.
-- 06 Apr 2009	MF	17146	22	Failed testing.

-- 14 May 2009	MF	17633	23	Further performance improvement by using a HINT on joins to the CASES table to force
--					a specific index to be used. This made a significant performance improvement.
-- 29 May 2009	MF	17748	24	Reduce locking level to ensure other activities are not blocked.
-- 02 Jul 2009	MF	17505	25	Matching on Requestor's Reference is to allow the Data Instructor to be a different
--					name that belongs to the same family as the Sender Name.
-- 16 Jul 2009	DL		26	Fixed syntax error possibly caused by merge process.
-- 24 Jul 2012	MF	16184	27	Where RequestType='Extract Cases Response' the matching should only use Official No, Number Type and Country.
-- 05 Jul 2013	MF	21426	28	When data instructor is being changed on a Case if the data instructors belong to the same
--					family then treat the Requestor as a match.
-- 22 Aug 2017	MF	72191	29	If the @psRequestType='Agent Input' then if the SENDERCASEREFERENCE has a value but there is no value saved
--					in the REFERENCENO of the sender against the Case, then it will be considered to be a match.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

create table #TEMPMATCH(TRANSACTIONIDENTIFIER		nvarchar(50)	collate database_default NOT NULL,
			CASEID				int	not null,
			CASEIDMATCH			tinyint	default 0,
			IRNMATCH			tinyint	default 0,
			OFFICIALNOMATCH			tinyint	default 0,
			NUMBERTYPEMATCH			tinyint default 1,
			REQUESTORREFMATCH		tinyint default 0,
			INSTRUCTORREFMATCH		tinyint default 0
			)
Create table #TEMPCANDIDATES(	TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				CASEID			int		NOT NULL, 
				CASEIDMATCH		char(1)		collate database_default NOT NULL, 
				IRNMATCH		char(1)		collate database_default NOT NULL,
				REQUESTORMATCH		char(1)		collate database_default NOT NULL,
				REQUESTORREFMATCH	char(1)		collate database_default NOT NULL,
				INSTRUCTORMATCH		char(1)		collate database_default NOT NULL,
				INSTRUCTORREFMATCH	char(1)		collate database_default NOT NULL,
				NUMBERTYPEMATCH		int		NULL,
				OFFICIALNOMATCH		int		NULL,
				NOFUTURENAMEFOUND	bit		NOT NULL
				)
-- Declare working variables
Declare	@sSQLString 	nvarchar(max)
Declare	@sSQLString1 	nvarchar(max)
Declare	@sSQLString2 	nvarchar(max)
Declare	@sSQLString3 	nvarchar(max)
Declare	@sSQLString4 	nvarchar(max)
Declare @sNumberTypes	nvarchar(max)
Declare @nErrorCode 	int

-- SQA17748 Reduce the locking level to avoid blocking other processes
set transaction isolation level read uncommitted

-- Initialise the errorcode and then set it after each SQL Statement
Set @nErrorCode=0

-------------------------------------------------------------------------------------
-- Get the Requestor Name Type and Sender Name No of the batch if either are not
-- passed as parameters.
-------------------------------------------------------------------------------------

If  @nErrorCode=0
and(@psRequestorNameType is null
 or @pnSenderNameNo      is null
 or @psRequestType	 is null)
Begin
	Set @sSQLString="
	select	@psRequestorNameType=R.REQUESTORNAMETYPE,
		@pnSenderNameNo	   =S.SENDERNAMENO,
		@psRequestType     =S.SENDERREQUESTTYPE,
		@pnFamilyNo	   =N.FAMILYNO
	from EDESENDERDETAILS S
	join EDEREQUESTTYPE R	on (R.REQUESTTYPECODE=S.SENDERREQUESTTYPE)
	join NAME N		on (N.NAMENO=S.SENDERNAMENO)
	where S.BATCHNO=@pnBatchNo"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@psRequestorNameType	nvarchar(3)		OUTPUT,
				  @psRequestType	nvarchar(50)		OUTPUT,
				  @pnSenderNameNo	int			OUTPUT,
				  @pnFamilyNo		int			OUTPUT,
				  @pnBatchNo		int',
				  @psRequestorNameType=@psRequestorNameType	OUTPUT,
				  @psRequestType      =@psRequestType		OUTPUT,
				  @pnSenderNameNo     =@pnSenderNameNo		OUTPUT,
				  @pnFamilyNo         =@pnFamilyNo		OUTPUT,
				  @pnBatchNo          =@pnBatchNo
End
Else 
If  @nErrorCode=0
and @pnFamilyNo is null
Begin
	Set @sSQLString="
	select	@pnFamilyNo=N.FAMILYNO
	from NAME N		
	where N.NAMENO=@pnSenderNameNo"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnFamilyNo		int		OUTPUT,
				  @pnSenderNameNo	int',
				  @pnFamilyNo    =@pnFamilyNo		OUTPUT,
				  @pnSenderNameNo=@pnSenderNameNo
End

-------------------------------------------------------------------------------------
-- FIND CANDIDATE CASES
-------------------------------------------------------------------------------------
-- List the potential Cases along with details of what matched.
-------------------------------------------------------------------------------------
If @nErrorCode=0
Begin

	If @psRequestType not in ('Extract Cases Response')
	Begin
	-----------------------------------------
	-- Load candidate Cases matched on CASEID
	-----------------------------------------
	Set @sSQLString1="
	insert into #TEMPMATCH (TRANSACTIONIDENTIFIER, CASEID, CASEIDMATCH, IRNMATCH)
	select	D.TRANSACTIONIDENTIFIER, CS.CASEID, 1,
		CASE WHEN(CD.RECEIVERCASEREFERENCE is null) THEN 1		-- If user does not supply IRN then treat as match
		     WHEN(CS.CASEID=CS1.CASEID)             THEN 1 ELSE 0
		END"

	Set @sSQLString2=
	"	from EDETRANSACTIONCONTENTDETAILS D
	join "+
	CASE WHEN(@psTransactionId is not null OR @pnDraftCaseId is not null) 
		THEN "EDECASEMATCH M	on ( M.BATCHNO=D.BATCHNO 
					and  M.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER)" 
		ELSE "#TEMPCASEMATCH M	on ( M.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER)" 
	END+"
	join EDECASEDETAILS CD		on (CD.BATCHNO=D.BATCHNO
					and CD.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER)"

	If @pbDraftCaseSearch=1
	Begin
		Set @sSQLString3="
		left join CASETYPE CT	on (CT.ACTUALCASETYPE=CD.CASETYPECODE_T)
		join CASES CS with (index(XPKCASES))
				on (CS.CASEID=CD.RECEIVERCASEIDENTIFIER
				and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
				and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
				and CS.CASETYPE    =CT.CASETYPE)
		left join CASES CS1 with (index(XIE6CASES))
					on (CS1.IRN=CD.RECEIVERCASEREFERENCE
					and CS1.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS1.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS1.CASETYPE    =CD.CASETYPECODE_T)
		join EDECASEMATCH E
				on (E.DRAFTCASEID=CS.CASEID
				and E.BATCHNO<>"+convert(varchar,@pnBatchNo)+")"
	End
	Else Begin
		Set @sSQLString3="
		join CASES CS with (index(XPKCASES))
				on (CS.CASEID=CD.RECEIVERCASEIDENTIFIER
				and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
				and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
				and CS.CASETYPE    =CD.CASETYPECODE_T)
		left join CASES CS1 with (index(XIE6CASES))
					on (CS1.IRN=CD.RECEIVERCASEREFERENCE
					and CS1.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS1.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS1.CASETYPE    =CD.CASETYPECODE_T)"
	End

	Set @sSQLString3=@sSQLString3+"
	where D.BATCHNO="+convert(varchar,@pnBatchNo)

	If @psTransactionId is not null
	Begin
		set @sSQLString4="and D.TRANSACTIONIDENTIFIER="+convert(varchar,@psTransactionId)
	End
	Else If @pnDraftCaseId is not null
	Begin
		set @sSQLString4="and M.DRAFTCASEID="+convert(varchar,@pnDraftCaseId)
	End
	Else Begin
		set @sSQLString4=''
	End

	Set @sSQLString=@sSQLString1+char(10)+@sSQLString2+char(10)+@sSQLString3+char(10)+@sSQLString4

	Exec (@sSQLString)
	
	Set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	and @psRequestType not in ('Extract Cases Response')
	Begin
		--------------------------------------
		-- Load candidate Cases matched on IRN
		--------------------------------------
		Set @sSQLString1="
		insert into #TEMPMATCH (TRANSACTIONIDENTIFIER, CASEID, IRNMATCH)
		select	D.TRANSACTIONIDENTIFIER, isnull(CS.CASEID,CS1.CASEID), 
			CASE WHEN(CD.RECEIVERCASEREFERENCE is null) THEN 1
			     WHEN(CS.CASEID is not null)            THEN 1
								    ELSE 0
			END"

		If @pbDraftCaseSearch=1
		Begin
			Set @sSQLString3="
			left join CASETYPE CT	on (CT.ACTUALCASETYPE=CD.CASETYPECODE_T)
			left join CASES CS with (index(XIE6CASES))
						on (CS.IRN=CD.RECEIVERCASEREFERENCE
						and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
						and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
						and CS.CASETYPE    =CT.CASETYPE)
			left join EDECASEMATCH E
						on (E.DRAFTCASEID=CS.CASEID
						and E.BATCHNO<>"+convert(varchar,@pnBatchNo)+")
			left join CASES CS1 with (index(XPKCASES))
						on (CS1.CASEID=CD.RECEIVERCASEIDENTIFIER
						and CS1.COUNTRYCODE =CD.CASECOUNTRYCODE_T
						and CS1.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
						and CS1.CASETYPE    =CT.CASETYPE)
			left join EDECASEMATCH E1
						on (E1.DRAFTCASEID=CS1.CASEID
						and E1.BATCHNO<>"+convert(varchar,@pnBatchNo)+")
			where D.BATCHNO="+convert(varchar,@pnBatchNo)+"
			and(( CS.CASEID is not null and  E.DRAFTCASEID is not null)
			 OR (CS1.CASEID is not null and E1.DRAFTCASEID is not null))"
		End
		Else Begin
			Set @sSQLString3="
			left join CASES CS with (index(XIE6CASES))
						on (CS.IRN=CD.RECEIVERCASEREFERENCE
						and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
						and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
						and CS.CASETYPE    =CD.CASETYPECODE_T)
			left join CASES CS1 with (index(XPKCASES))	
						on (CS1.CASEID=CD.RECEIVERCASEIDENTIFIER
						and CS1.COUNTRYCODE =CD.CASECOUNTRYCODE_T
						and CS1.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
						and CS1.CASETYPE    =CD.CASETYPECODE_T)
			where D.BATCHNO="+convert(varchar,@pnBatchNo)+"
			and isnull(CS.CASEID,CS1.CASEID) is not null"
		End
	
		Set @sSQLString=@sSQLString1+char(10)+@sSQLString2+char(10)+@sSQLString3+char(10)+@sSQLString4

		Exec (@sSQLString)
		
		Set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		--------------------------------------------------
		-- Load candidate Cases matched on Official Number
		--------------------------------------------------
		
		-- First get a list of Number Types that are issued by
		-- IP Offices as we will restrict to these.
		-- NOTE : This approach is being used as a performance
		--        improvement rather than join to the NUMBERTYPES
		--        table as this was having a negative performance
		--        impact.

		Select @sNumberTypes = @sNumberTypes + nullif(',', ',' + @sNumberTypes) + dbo.fn_WrapQuotes(NUMBERTYPE,0,0)
		From NUMBERTYPES
		where ISSUEDBYIPOFFICE=1
				
				
		Set @sSQLString1="
		insert into #TEMPMATCH (TRANSACTIONIDENTIFIER, CASEID, OFFICIALNOMATCH, NUMBERTYPEMATCH)
		select	D.TRANSACTIONIDENTIFIER, CS.CASEID, 1,
			CASE WHEN(N.NUMBERTYPE=I.IDENTIFIERNUMBERCODE_T) THEN 1 ELSE 0 END"
	
		Set @sSQLString2=
		"	from EDETRANSACTIONCONTENTDETAILS D
		join "+
		CASE WHEN(@psTransactionId is not null OR @pnDraftCaseId is not null) 
			THEN "EDECASEMATCH M	on ( M.BATCHNO=D.BATCHNO 
						and  M.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER)" 
			ELSE "#TEMPCASEMATCH M	on ( M.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER)" 
		END+"
		join EDECASEDETAILS CD		on (CD.BATCHNO=D.BATCHNO
						and CD.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER)"
	
		Set @sSQLString3="
		-- Get the Official Numbers
		join EDEIDENTIFIERNUMBERDETAILS I	on (I.BATCHNO=CD.BATCHNO
							and I.TRANSACTIONIDENTIFIER=CD.TRANSACTIONIDENTIFIER
							and I.ASSOCIATEDCASERELATIONSHIPCODE is null
							and I.IDENTIFIERNUMBERCODE_T in ("+@sNumberTypes+"))
		join CASEINDEXES CI	on (CI.GENERICINDEX=left(I.IDENTIFIERSTRIPPEDTEXT,36)
					and CI.SOURCE=5)
		join OFFICIALNUMBERS N	on (N.CASEID=CI.CASEID
					and dbo.fn_StripNonAlphaNumerics(N.OFFICIALNUMBER)=left(I.IDENTIFIERSTRIPPEDTEXT,36)
					and N.NUMBERTYPE in ("+@sNumberTypes+"))"

		If @pbDraftCaseSearch=1
		Begin
			Set @sSQLString3=@sSQLString3+"
			left join CASETYPE CT on (CT.ACTUALCASETYPE=CD.CASETYPECODE_T)
			join CASES CS with (index(XPKCASES))
					on (CS.CASEID=N.CASEID
					and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS.CASETYPE    =CT.CASETYPE)
			join EDECASEMATCH E
					on (E.DRAFTCASEID=CS.CASEID
					and E.BATCHNO<>"+convert(varchar,@pnBatchNo)+")"
		End
		Else Begin
			Set @sSQLString3=@sSQLString3+"
			join CASES CS with (index(XPKCASES))
					on (CS.CASEID=N.CASEID
					and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS.CASETYPE    =CD.CASETYPECODE_T)"
		End

		Set @sSQLString3=@sSQLString3+"
		where D.BATCHNO="+convert(varchar,@pnBatchNo)
	
		Set @sSQLString=@sSQLString1+char(10)+@sSQLString2+char(10)+@sSQLString3+char(10)+@sSQLString4

		Exec (@sSQLString)
		
		Set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	and @psRequestType not in ('Extract Cases Response')
	Begin
		------------------------------------------------------------
		-- Load candidate Cases matched on Data Instructor Reference
		------------------------------------------------------------
		Set @sSQLString1="
		insert into #TEMPMATCH (TRANSACTIONIDENTIFIER, CASEID, REQUESTORREFMATCH,NUMBERTYPEMATCH)
		select	D.TRANSACTIONIDENTIFIER, CS.CASEID, 1,0"
	
		Set @sSQLString3="
		join CASENAME CN	on (CN.NAMETYPE="+CASE WHEN(@psRequestorNameType is null) THEN 'NULL' ELSE "'"+ @psRequestorNameType+"'" END+"
					and(CN.EXPIRYDATE  > getdate() or CN.EXPIRYDATE   is null)
					and(CN.COMMENCEDATE<=getdate() or CN.COMMENCEDATE is null)
					and CN.SEQUENCE=0)
		join NAME N		on (N.NAMENO=CN.NAMENO)"

		If @pbDraftCaseSearch=1
		Begin
			Set @sSQLString3=@sSQLString3+"
			left join CASETYPE CT on (CT.ACTUALCASETYPE=CD.CASETYPECODE_T)
			join CASES CS with (index(XPKCASES))
					on (CS.CASEID=CN.CASEID
					and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS.CASETYPE    =CT.CASETYPE)
			join EDECASEMATCH E
					on (E.DRAFTCASEID=CS.CASEID
					and E.BATCHNO<>"+convert(varchar,@pnBatchNo)+")"
		End
		Else Begin
			Set @sSQLString3=@sSQLString3+"
			join CASES CS with (index(XPKCASES))
					on (CS.CASEID=CN.CASEID
					and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS.CASETYPE    =CD.CASETYPECODE_T)"
		End
		
		Set @sSQLString3=@sSQLString3+"
		where CN.REFERENCENO=CD.SENDERCASEREFERENCE
		and (CN.NAMENO=D.ALTSENDERNAMENO"+CASE WHEN(@pnSenderNameNo is null) THEN ')' ELSE " OR (D.ALTSENDERNAMENO is null AND CN.NAMENO="+convert(varchar,@pnSenderNameNo)+")"+CASE WHEN(@pnFamilyNo is null) THEN ")" ELSE " OR N.FAMILYNO="+convert(varchar,@pnFamilyNo)+")" END END +"
		and D.BATCHNO="+convert(varchar,@pnBatchNo)
	
		Set @sSQLString=@sSQLString1+char(10)+@sSQLString2+char(10)+@sSQLString3+char(10)+@sSQLString4
	
		Exec (@sSQLString)
		
		Set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	and @psRequestType not in ('Extract Cases Response')
	Begin
		-------------------------------------------------------
		-- Load candidate Cases matched on Instructor Reference
		-------------------------------------------------------
		Set @sSQLString1="
		insert into #TEMPMATCH (TRANSACTIONIDENTIFIER, CASEID, INSTRUCTORREFMATCH,NUMBERTYPEMATCH)
		select	D.TRANSACTIONIDENTIFIER, CS.CASEID, 1,0"
	
		Set @sSQLString3="
		left join EDECASENAMEDETAILS CND on(CND.BATCHNO=D.BATCHNO
						and CND.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER
						and CND.NAMETYPECODE_T='I')
		left join EDEADDRESSBOOK AB	on (AB.BATCHNO=D.BATCHNO
					and AB.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER
					and AB.NAMETYPECODE=CND.NAMETYPECODE
					and isnull(AB.NAMESEQUENCENUMBER,'')=isnull(CND.NAMESEQUENCENUMBER,''))
		join CASENAME CN	on (CN.NAMENO=isnull(AB.NAMENO,"+CASE WHEN(@pnSenderNameNo is not null and @psRequestType='Data Input') THEN convert(varchar,@pnSenderNameNo) ELSE 'NULL' END +")	-- SQA17146
					and CN.NAMETYPE='I'
					and(CN.EXPIRYDATE  > getdate() or CN.EXPIRYDATE   is null)
					and(CN.COMMENCEDATE<=getdate() or CN.COMMENCEDATE is null)
					and CN.SEQUENCE=0)"

		If @pbDraftCaseSearch=1
		Begin
			Set @sSQLString3=@sSQLString3+"
			left join CASETYPE CT on (CT.ACTUALCASETYPE=CD.CASETYPECODE_T)
			join CASES CS with (index(XPKCASES))
					on (CS.CASEID=CN.CASEID
					and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS.CASETYPE    =CT.CASETYPE)
			join EDECASEMATCH E
					on (E.DRAFTCASEID=CS.CASEID
					and E.BATCHNO<>"+convert(varchar,@pnBatchNo)+")"
		End
		Else Begin
			Set @sSQLString3=@sSQLString3+"
			join CASES CS with (index(XPKCASES))
					on (CS.CASEID=CN.CASEID
					and CS.COUNTRYCODE =CD.CASECOUNTRYCODE_T
					and CS.PROPERTYTYPE=CD.CASEPROPERTYTYPECODE_T
					and CS.CASETYPE    =CD.CASETYPECODE_T)"
		End
		
		If @psRequestType='Data Input'
			Set @sSQLString3=@sSQLString3+"
			where CN.REFERENCENO=CASE WHEN(AB.NAMENO is not null) THEN CND.NAMEREFERENCE ELSE CD.SENDERCASEREFERENCE END 	-- SQA17146
			and D.BATCHNO="+convert(varchar,@pnBatchNo)
		Else
		Set @sSQLString3=@sSQLString3+"
		where CN.REFERENCENO=CND.NAMEREFERENCE
		and D.BATCHNO="+convert(varchar,@pnBatchNo)
	
		Set @sSQLString=@sSQLString1+char(10)+@sSQLString2+char(10)+@sSQLString3+char(10)+@sSQLString4
	
		Exec (@sSQLString)
		
		Set @nErrorCode=@@Error
	End
	--------------------------------------------------------------------
	-- Now we have a list of candidate cases we need to check what other
	-- characteristics match and load these into a temporary table so 
	-- that when a candidate case is being proposed more than once we
	-- can elect to display the best candidate.
	--------------------------------------------------------------------

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPCANDIDATES(TRANSACTIONIDENTIFIER, CASEID,CASEIDMATCH,IRNMATCH,REQUESTORMATCH,
					    REQUESTORREFMATCH,INSTRUCTORMATCH,INSTRUCTORREFMATCH,
					    NUMBERTYPEMATCH,OFFICIALNOMATCH,NOFUTURENAMEFOUND)
		select distinct
		CS.TRANSACTIONIDENTIFIER,
		CS.CASEID, 
		CS.CASEIDMATCH,
		CS.IRNMATCH,
		CASE WHEN(NR.NAMENO=CN1.NAMENO)                   
			THEN 1
				-- If the Requestor and Instructor are members of the same family
				-- then the Instructor may be used as the Requestor
			ELSE	CASE WHEN(NR.FAMILYNO=NI.FAMILYNO and NI.NAMENO=CN2.NAMENO)
					THEN 1
						-- SQA21426
						-- If the Requestor and the Data Instructor are members of the same family
						-- then treat the requestor as a match
					ELSE	CASE WHEN(NR.FAMILYNO=N1.FAMILYNO and NI.NAMENO=CN2.NAMENO)
							THEN 1
							ELSE 0
						END
				END
		END 								    as REQUESTORMATCH,
		CASE WHEN(CD.SENDERCASEREFERENCE is null)	  THEN 1
			ELSE CASE WHEN(CD.SENDERCASEREFERENCE=CN1.REFERENCENO)
								  THEN 1
			          WHEN(CN1.REFERENCENO is null AND @psRequestType='Agent Input') 
								  THEN 1 ELSE 0 END 
		END								    as REQUESTORREFMATCH,
			-- No instructor treated as Match
		CASE WHEN(CND.NAMETYPECODE is null)		  THEN 1	
			ELSE CASE WHEN(NI.NAMENO=CN2.NAMENO)      THEN 1 ELSE 0 END 
		END								    as INSTRUCTORMATCH,
		CASE WHEN(CND.NAMEREFERENCE is null)		  THEN 1
			ELSE CASE WHEN(CND.NAMEREFERENCE=CN2.REFERENCENO) 
								  THEN 1 
			          WHEN(CN2.REFERENCENO is null AND @psRequestType='Agent Input') 
								  THEN 1 ELSE 0 END 
		END								    as INSTRUCTORREFMATCH,
		CS.NUMBERTYPEMATCH,
		CS.OFFICIALNOMATCHES,
		CASE WHEN(CN3.CASEID=CS.CASEID) THEN 0 ELSE 1 END		    as NOFUTURENAMEFOUND
		from (	select	TRANSACTIONIDENTIFIER,
				CASEID,
				cast(sum(isnull(CASEIDMATCH, 0)) as bit)  as CASEIDMATCH,
				cast(sum(isnull(IRNMATCH, 0)) 	as bit)	  as IRNMATCH,
				cast(sum(isnull(NUMBERTYPEMATCH, 0)) as bit) as NUMBERTYPEMATCH,
				cast(sum(isnull(OFFICIALNOMATCH, 0)) as bit) as OFFICIALNOMATCHES,
				cast(sum(isnull(REQUESTORREFMATCH, 0)) as bit) as REQUESTORREFMATCH,
				cast(sum(isnull(INSTRUCTORREFMATCH, 0)) as bit) as INSTRUCTORREFMATCH
			from #TEMPMATCH
			group by TRANSACTIONIDENTIFIER, CASEID) CS
	
		join EDETRANSACTIONCONTENTDETAILS D	on (D.TRANSACTIONIDENTIFIER=CS.TRANSACTIONIDENTIFIER)
		join EDECASEDETAILS CD			on (CD.BATCHNO=D.BATCHNO
							and CD.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER)
		-- Get the Name to be used as the Requestor Name
		left join NAME NR			on (NR.NAMENO=isnull(D.ALTSENDERNAMENO,@pnSenderNameNo))
	
		-- Get the Instructor passed in the EDE
		left join EDECASENAMEDETAILS CND	on (CND.BATCHNO=D.BATCHNO
							and CND.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER
							and CND.NAMETYPECODE_T='I')
		left join EDEADDRESSBOOK AB		on (AB.BATCHNO=D.BATCHNO
							and AB.TRANSACTIONIDENTIFIER=D.TRANSACTIONIDENTIFIER
							and AB.NAMETYPECODE=CND.NAMETYPECODE
							and (AB.NAMESEQUENCENUMBER=CND.NAMESEQUENCENUMBER or (AB.NAMESEQUENCENUMBER is null AND CND.NAMESEQUENCENUMBER is null)))
		left join NAME NI			on (NI.NAMENO=AB.NAMENO)
		-- Get the Requestor Name against the Case
		left join CASENAME CN1	on (CN1.CASEID=CS.CASEID
					and CN1.NAMETYPE=@psRequestorNameType
					and(CN1.EXPIRYDATE  > getdate() or CN1.EXPIRYDATE   is null)
					and(CN1.COMMENCEDATE<=getdate() or CN1.COMMENCEDATE is null)
					and CN1.SEQUENCE=0)
	
		left join NAME N1	on (N1.NAMENO=CN1.NAMENO)
	
		-- Get the current Instructor.
		left join CASENAME CN2	on (CN2.CASEID=CS.CASEID
					and CN2.NAMETYPE='I'
					and(CN2.EXPIRYDATE  > getdate() or CN2.EXPIRYDATE   is null)
					and(CN2.COMMENCEDATE<=getdate() or CN2.COMMENCEDATE is null))
	
		-- Check for future names for Instructor or Requestor Name 
		left join (	select distinct CASEID
				from CASENAME
				where (EXPIRYDATE>getdate() or EXPIRYDATE is null)
				and COMMENCEDATE >getdate()
				and NAMETYPE in ('I',@psRequestorNameType)) CN3
							on (CN3.CASEID=CS.CASEID)
		where D.BATCHNO=@pnBatchNo"
		
		Exec @nErrorCode=sp_executesql @sSQLString,
					N'@psRequestType	nvarchar(50),
					  @psRequestorNameType	nvarchar(3),
					  @pnBatchNo		int,
					  @pnSenderNameNo	int',
					  @psRequestType	=@psRequestType,
					  @psRequestorNameType	=@psRequestorNameType,
					  @pnBatchNo		=@pnBatchNo,
					  @pnSenderNameNo	=@pnSenderNameNo
	End

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Select	C.TRANSACTIONIDENTIFIER, C.CASEID,C.CASEIDMATCH,C.IRNMATCH,C.REQUESTORMATCH,
			C.REQUESTORREFMATCH,C.INSTRUCTORMATCH,C.INSTRUCTORREFMATCH,
			C.NUMBERTYPEMATCH, C.OFFICIALNOMATCH, C.NOFUTURENAMEFOUND
		from #TEMPCANDIDATES C
		-- If a Case appears multiple times as a candidate then we must return the details
		-- associated with the best candidate.
		left join #TEMPCANDIDATES C1	on (C1.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER
						and C1.CASEID=C.CASEID
						and C1.CASEIDMATCH
						   +C1.IRNMATCH
						   +C1.REQUESTORMATCH
						   +C1.REQUESTORREFMATCH
						   +C1.INSTRUCTORMATCH
						   +C1.INSTRUCTORREFMATCH
									>   C.CASEIDMATCH
									   +C.IRNMATCH
									   +C.REQUESTORMATCH
									   +C.REQUESTORREFMATCH
									   +C.INSTRUCTORMATCH
									   +C.INSTRUCTORREFMATCH)
		Where  C1.CASEID is null
		order by 1,2,3 desc,4 desc, 5 desc, 6 desc, 7 desc, 8 desc, 9 desc, 10 desc"
		
		Exec @nErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End
	Else Begin
		-- If the @nErrorCode is not zero then we need to force
		-- an error to occur in the calling routine where the
		-- results of this procedure are being loaded into a 
		-- temporary table.		
		select @nErrorCode, null,null,null,null,null,null,null,null,null,null
	End
End

RETURN @nErrorCode
go

grant execute on dbo.ede_FindCandidateCases to public
go
