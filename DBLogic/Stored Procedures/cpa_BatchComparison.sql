-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_BatchComparison
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_BatchComparison]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_BatchComparison.'
	drop procedure dbo.cpa_BatchComparison
end
print '**** Creating procedure dbo.cpa_BatchComparison...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_BatchComparison 
		@pnBatchNo 		int,			-- mandatory
		@pnCaseId		int		=null,	-- Restrict to a single case
		@pbAcceptDifferences	bit		=null,	-- 1=accept; 0=reject; null=display result
		@pbPoliceCase		bit		=1,	-- 1=Police results
		@pbModificationRequired	bit		=0,	-- 1=InProma to be modified; 0=No modification required
		@psPropertyType		varchar(2)	=null,
		@pbNotProperty		bit		=0,
		@psNarrative		nvarchar(50)	=null,
		@psOfficeCPACode	nvarchar(3)	=null,	-- filter on Office
		@psCPANarrative		nvarchar(50)	=null,	-- filter on received rows with this Narrative
		@pbUnprocessedOnly	bit		=1,	-- only return unprocessed rows in the result
		@pnUserIdentityId	int		=null
as
-- PROCEDURE :	cpa_BatchComparison
-- VERSION :	33
-- DESCRIPTION:	Performs a data comparison of the CPARECEIVE table against the CPASEND table.
--		If a Case fails the comparison it will take the action determined by the 
--		@pbAcceptDifferences parameter.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02/08/2002	MF			Procedure Created
-- 23/09/2002	MF			Update Events and Police them if the Narrative on the EPL has been explicitly
--					linked to a particular Event.
-- 01/12/2002	MF	8275		Record the CPA Account number in the InProma database so that it can be reported 
--					to CPA when the Client or Invoicee is reported on a Case.
-- 11/12/2002	MF	8302		When performing data comparison on data received from CPA, operator should be able 
--					to identify that the InPro data requires modification.  This will cause an Event to 
--					be inserted or update on InProma.
-- 17/12/2002	MF	8232		Allow PropertyType and Not Property to be passed as parameters to filter the 
--					comparison
-- 04/03/2004	MF	8485		When loading the CPA client number only save the number if it does not already exist.
-- 27/03/2003	MF	8582		If the CPARECEIVE table does not have an IPRURN then the Case is to be rejected because
--					this indicates that the Case has not been loaded onto the CPA Portfolio.
-- 24/06/2003	MF	8721		Instead of using the CPA Received or Rejected dates to determine if a Case within a 
--					batch has already been processed, use the ACKNOWLEDGED flag.
-- 25 Jun 2003	MF	8874		Allow a user to update the Narrative when they reject an EPL record.  This can
--					then be used to report the reason for the reject to CPA.  The Narrative will be
--					stored against the CPASEND row and cleared out when the Case is accepted.
-- 08 Jul 2003	MF	8955		CPA Narratives marked for exclusion during the data comparison should only effect 
--					Cases on the live CPA Portfolio
-- 01 Aug 2003	MF	8955	5	Revisit
-- 20 Aug 2003	MF	8874	6	Revisit 
-- 02 Dec 2003	MF	9510	7	Increase the size of POLICINGSEQNO to int to cater for large number of 
--					Policing requests on an initial CPA Interface extract.
-- 05 Aug 2004	AB	8035	8	Add collate database_default to temp table definitions
-- 09 May 2005	MF	10731	9	Allow cases in the Comparison to be filtered by Office User Code.
-- 15 Jun 2005	MF	10731	10	Revisit.  Use the Office CPACode instead of the User Code.
-- 16 Jun 2005	MF	11516	11	Display all CPARECEIVE rows in a batch when Narrative is passed as a 
--					parameter.
-- 13 Jul 2005	MF	10077	12	A new parameter to explicitly determine if only unprocessed data should be
--					returned.  Also add a new column to indicate if a row has already been processed.
-- 13 Jul 2005	MF	10077	13	A case that is explicitly Rejected also requires the Acknowledged flag set on.
-- 16 Nov 2005	vql	9704	14	When updating POLICING table insert @pnUserIdentityId.
--					Create @pnUserIdentityId also.
-- 21 Feb 2006	MF	12350	15	Problem when @psCPANarrative contains embedded quote.
-- 23 Feb 2006	MF	12350	16	Revisit 12350.  The CPANarrative was not correctly being applied as a filter
--					when the CPASEND table was having its ACKNOWLEDGED flag set on.
-- 26 Feb 2006	MF	12350	17	Revisit 12350. CPANarrative was not correctly being applied as a filter on 
--					the CPASEND table when the Accept All option was being used.
-- 14 Jun 2006	MF	12810	18	This is part of a partial correction for this SQA to help address the situation
--					where the IRN of Case has been changed after the batch has been sent to CPA. The
--					change will set the CASEID on CPARECEIVE to match CPASEND and then modifies the
--					CASECODE on CPARECEIVE to a message to indicate that there is a problem.
--					A more complete solution is required at the point of loading the CPARECEIVE.
-- 19 Jun 2006	MF	12855	19	Problem occurring where Narratives are mapped to Events and the Narrative
--					string appears within another Narrative. 
-- 18 Jul 2006	MF	13075	20	CPASEND is being updated for the same case across multiple batches
--					when the Reject Narrative is supplied.  Should just be updating the
--					specific batch being processed.
-- 24 Aug 2006	MF	13268	21	Update or insert a Case Event for the Eventno associated with a Narrative on 
--					the EPL even if the user elects to Reject the CPA data or mark the Case for
--					later modifiction.  This will ensure any workflows associated with the Event
--					will still be considered.
-- 18 Apr 2007	MF	14694	22	The loading of the CPA Account Number into the NAMEALIAS is to be controlled
--					by a Site Control so that this functionality is optional.
-- 06 Aug 2007	MF	15121	23	SQL Error on when filtering by office.
-- 28 Aug 2007	MF	15229	24	Problem on case sensitive database.  "CAsEID" changed to "CASEID"
-- 14 May 2008	MF	16416	25	Reversal of 14694 which completely removes the ability to save the Account Number
--					supplied by CPA against the Inprotech Name.
-- 05 Jun 2008	MF	16508	26	When differences are being accepted then previously sent Narrative must be
--					cleared.
-- 11 Dec 2008	MF	17136	27	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 30 Jan 2009	DL	16932	29	Trim leading and trailing spaces of CPA Formatted Number to ensure only new numbers are imported. 
-- 17 Jan 2014	MF	20008	30	Only save a CPA version of the Official Number if it is substantially the same as the number held
--					within Inprotech with the special characters removed.
-- 22 Dec 2014	AvdA	14800	31	SDR-14800 Modify above change to use CPASENDCOMPARE. This allows comparison data to be cleansed
--					(separate script) so that official number sent history is not lost but does not interfere with results.
--					Consider mismatched if no value held in Inprotech (to avoid returning an unconfirmed number in next batch).
--					Ignore leading zeroes in comparison (ie consider 'matched').
--					Also, remove any previously mismatched numbers that now appear to be matched (to avoid unnecessary investigation).
--					Only add matched or mismatched numbers if data 'accepted' (simplifies code and is recommended practice anyway).
-- 14 Nov 2018  AV  75198/DR-45358	32   Date conversion errors when creating cases and opening names in Chinese DB
-- 19 May 2020	DL	DR-58943 33	Ability to enter up to 3 characters for Number type code via client server	

set nocount on
set concat_null_yields_null off


-- Temporary table of the extracted data

Create table #TEMPREJECTEDCASES(
			CASEID		int	not null,
			REJECTFLAG	bit	null
 )

-- Need a temporary POLICING table to allocate a unique sequence number.

CREATE TABLE #TEMPPOLICING (
			POLICINGSEQNO		int	identity(0,1),
			CASEID			int,
			EVENTNO			int
 )

declare	@ErrorCode		int
declare @RowCount		int
declare	@TranCountStart		int
declare @bUpdateRejectList	tinyint
declare	@sSQLString		nvarchar(4000)
declare @sWhere			nvarchar(1000)
declare @sFilter		nvarchar(500)
declare @sOfficeJoin		nvarchar(100)

-- The EventNos to be extrated
declare	@nCPARejectedEvent	int
declare @nCPAReceivedEvent	int
declare @nCPAModifyEvent	int

-- Number Type for saving mismatched
-- official numbers returned by CPA
declare @sMismatchNumberType	nvarchar(3)

-- The NumberTypes to be extracted
declare @sApplicationNumberType	 nvarchar(20)
declare @sPublicationNumberType	 nvarchar(20)
declare	@sAcceptanceNumberType	 nvarchar(20)
declare @sRegistrationNumberType nvarchar(20)

-- Options
declare @bLoadCPAAccount	bit

Set	@ErrorCode	=0
Set	@TranCountStart	=0

-- SQS12810
-- If there are any rows that have not had their CASEID set because
-- the IRN on the Case has been changed or the Case has been deleted
-- then set it to the CASEID of the CPASEND row and modify the CASECODE
-- to ensure a discrepancy
-- This is really a temporary solution to the problem as described in SQA12810

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	CPARECEIVE
	Set	CASEID=S.CASEID,
		CASECODE=CASE WHEN(C.IRN =S.CASECODE) THEN C.IRN
			      WHEN(C.IRN<>S.CASECODE) THEN '* '+left(S.CASECODE,13)
			      WHEN(C.CASEID is null)  THEN '~ '+left(S.CASECODE,13)
			 END
	From CPARECEIVE R
	join CPASEND S		on (S.BATCHNO=R.BATCHNO
				and S.CASECODE=R.CASECODE)
	left join CASES C	on (C.CASEID=S.CASEID)
	where R.BATCHNO=@pnBatchNo
	and R.CASEID is null
	and R.CASECODE is not null"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo=@pnBatchNo
End

-- Get the client specific mappings and options from SITECONTROL

If @ErrorCode=0
Begin
	set @sSQLString="
	Select	@nCPAReceivedEventOUT=S1.COLINTEGER,
		@nCPARejectedEventOUT=S2.COLINTEGER,
		@nCPAModifyEventOUT  =S3.COLINTEGER
	from	  SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID ='CPA Rejected Event')
	left join SITECONTROL S3 on (S3.CONTROLID ='CPA Modify Case')
	where	S1.CONTROLID='CPA Received Event'"

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@nCPAReceivedEventOUT		int 		OUTPUT,
					  @nCPARejectedEventOUT		int 		OUTPUT,
					  @nCPAModifyEventOUT		int		OUTPUT',
					  @nCPAReceivedEventOUT=@nCPAReceivedEvent	OUTPUT,
					  @nCPARejectedEventOUT=@nCPARejectedEvent	OUTPUT,
					  @nCPAModifyEventOUT  =@nCPAModifyEvent	OUTPUT
End

If @ErrorCode=0
Begin
	select @sSQLString=
	"Select	@sApplicationNumberType =dbo.fn_WrapQuotes(S24.COLCHARACTER,1,0),"+char(10)+
	"	@sAcceptanceNumberType  =dbo.fn_WrapQuotes(S25.COLCHARACTER,1,0),"+char(10)+
	"	@sPublicationNumberType =dbo.fn_WrapQuotes(S26.COLCHARACTER,1,0),"+char(10)+
	"	@sRegistrationNumberType=dbo.fn_WrapQuotes(S27.COLCHARACTER,1,0)"+char(10)+
	"from	  SITECONTROL S27"+char(10)+
	"left join SITECONTROL S24 on (upper(S24.CONTROLID)='CPA NUMBER-APPLICATION')"+char(10)+
	"left join SITECONTROL S25 on (upper(S25.CONTROLID)='CPA NUMBER-ACCEPTANCE')"+char(10)+
	"left join SITECONTROL S26 on (upper(S26.CONTROLID)='CPA NUMBER-PUBLICATION')"+char(10)+
	"where	(upper(S27.CONTROLID)='CPA NUMBER-REGISTRATION')"

	Exec @ErrorCode=sp_executesql @sSQLString, 
			N'@sApplicationNumberType	nvarchar(20) 		OUTPUT,
			  @sAcceptanceNumberType	nvarchar(20) 		OUTPUT,
			  @sPublicationNumberType	nvarchar(20) 		OUTPUT,
			  @sRegistrationNumberType	nvarchar(20) 		OUTPUT',
			  @sApplicationNumberType =@sApplicationNumberType	OUTPUT,
			  @sAcceptanceNumberType  =@sAcceptanceNumberType	OUTPUT,
			  @sPublicationNumberType =@sPublicationNumberType	OUTPUT,
			  @sRegistrationNumberType=@sRegistrationNumberType	OUTPUT
End


-- Now perform the comparison. Any rejected rows will be returned in the
-- #TEMPREJECTEDCASES table.  Do not bother with the comparison if all records
-- are to be accepted by default.

If  @ErrorCode=0
and isnull(@pbAcceptDifferences,0)=0
Begin
	If @pnCaseId is not null
	Begin
		If @pbAcceptDifferences=0
			Set @sSQLString="Insert into #TEMPREJECTEDCASES(CASEID, REJECTFLAG) values(@pnCaseId,1)"
		Else
			Set @sSQLString="Insert into #TEMPREJECTEDCASES(CASEID) values(@pnCaseId)"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnCaseId	int',
						  @pnCaseId=@pnCaseId
	End
	-- if a specific Case and Narrative has not been indicated then call a procedure to load
	-- all of the Cases in the batch that fail the data comparison.
	Else Begin
		Set @bUpdateRejectList=1	
	
		Exec @ErrorCode=cpa_ReportComparison
					@pnBatchNo=@pnBatchNo,
					@pbUpdateRejectList=@bUpdateRejectList,
					@psPropertyType=@psPropertyType,
					@pbNotProperty=@pbNotProperty,
					@psOfficeCPACode=@psOfficeCPACode,
					@psCPANarrative=@psCPANarrative
	
		If isnull(@pbUnprocessedOnly,0)=0
		Begin
			-- When all cases (processed and unprocessed) are required then return
			-- all of the CPARECEIVE rows that have not already been rejected.
			Set @sSQLString="
				insert into #TEMPREJECTEDCASES (CASEID, REJECTFLAG)
				select R.CASEID,0
				from CPARECEIVE R
				join CASES C		on (C.CASEID=R.CASEID)
				left join OFFICE O	on (O.OFFICEID=C.OFFICEID)
				left join #TEMPREJECTEDCASES T on (T.CASEID=R.CASEID)
				where R.BATCHNO = @pnBatchNo
				and  (R.NARRATIVE=@psCPANarrative or @psCPANarrative is null)
				and   T.CASEID is null
				and  (O.CPACODE=@psOfficeCPACode OR @psOfficeCPACode is null)
				and ((C.PROPERTYTYPE<>@psPropertyType and @pbNotProperty=1) 
				  or (C.PROPERTYTYPE= @psPropertyType and isnull(@pbNotProperty,0)=0) 
				  or  @psPropertyType is NULL) "
	
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psPropertyType	nvarchar(2),
						  @pbNotProperty	bit,
						  @psCPANarrative	nvarchar(50),
						  @psOfficeCPACode	nvarchar(3)',
						  @pnBatchNo=@pnBatchNo,
						  @psPropertyType=@psPropertyType,
						  @pbNotProperty=@pbNotProperty,
						  @psCPANarrative=@psCPANarrative,
						  @psOfficeCPACode=@psOfficeCPACode
		End
	End
End

If  @ErrorCode =0
Begin
	If @pnCaseId is not null
	Begin
		Set @sWhere="and CPA.CASEID="+convert(varchar, @pnCaseId)
	End
	Else Begin
		-- Filter by Property Type
		If @psPropertyType is not null
		Begin
			If @pbNotProperty=1
				Set @sFilter=char(10)+"and C.PROPERTYTYPE<>'"+@psPropertyType+"'"
			Else
				Set @sFilter=char(10)+"and C.PROPERTYTYPE= '"+@psPropertyType+"'"
		End

		-- Filter by Office
		If @psOfficeCPACode is not null
		Begin
			Set @sFilter=@sFilter+char(10)+"and O.CPACODE='"+@psOfficeCPACode+"'"

			Set @sOfficeJoin="join OFFICE O on (O.OFFICEID=C.OFFICEID)"+char(10)
		End

		-- Filter by the CPA Narrative
		If @psCPANarrative is not null
		Begin
			--Set @sFilter=@sFilter+char(10)+"and CPA.NARRATIVE='"+@psCPANarrative+"'"
			Set @sFilter=@sFilter+char(10)+"and CPA.NARRATIVE=@psCPANarrative"
		End
	End
End

-- Record a temporary table row for each Case that is to be policed. This will
-- allocate a unique sequence number for insertion into the POLICING table. 
-- Do this outside of the main transaction to keep the transaction as short
-- as possible.

If  @pbPoliceCase=1
and @ErrorCode   =0
Begin	
	-- Record details of Cases that will have their CPA Receive Event updated
	-- Cases that have not been rejected by the Comparison will update the Receive Event
	
	If @nCPAReceivedEvent is not null
	and (@pbAcceptDifferences=1 OR @pnCaseId is null)
	Begin
		-- Insert a row to be policed for each row that has not been rejected
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO)"+char(10)+
		"Select CPA.CASEID, @nCPAReceivedEvent"+char(10)+
		"from CPARECEIVE CPA"+char(10)+
		"join CASES C on (C.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+					-- 10731 Filter by Office
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+  -- 8721 
		"and   CPA.CASEID is not null"+char(10)+
		"and   CPA.IPRURN is not null"+char(10)+	-- Only accept if the Case is on the CPA Portfolio
		"and not exists"+char(10)+
		"(select * from #TEMPREJECTEDCASES R"+char(10)+
		" where R.CASEID=CPA.CASEID"+char(10)+
		" and R.REJECTFLAG=1)"

		Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCPAReceivedEvent	int,
						  @pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @nCPAReceivedEvent,
						  @pnBatchNo,
						  @psCPANarrative
	End

	-- Record details of Cases that will have their CPA Rejected Event updated
	-- Only do this when the AcceptDifferences flag is explicitly set to 0
	If  @nCPARejectedEvent is not null
	and @pbAcceptDifferences=0
	Begin
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO)"+char(10)+
		"Select CPA.CASEID, @nCPARejectedEvent"+char(10)+
		"from #TEMPREJECTEDCASES CPA"+char(10)+
		"join CASES C on (C.CASEID=CPA.CASEID)"+char(10)+
		"where CPA.REJECTFLAG=1"

		Set @sSQLString=@sSQLString+char(10)+@sWhere

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCPARejectedEvent	int',
						  @nCPARejectedEvent	
	end

	-- If an Event has been identified to indicate the Case is to be modified
	-- then insert a Policing row if the Case has been marked for modification
	-- or if the Case has not been marked for modification but the Event already exists
	-- then also insert a Policing row to indicate that the Event is being cleared out.

	If  @nCPAModifyEvent is not null
	and @pnCaseId        is not null
	Begin
		if @pbModificationRequired=1
		Begin
			Set @sSQLString=
			"Insert into #TEMPPOLICING(CASEID, EVENTNO) values(@pnCaseId, @nCPAModifyEvent)"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPAModifyEvent	int,
							  @pnCaseId		int',
							  @nCPAModifyEvent,
							  @pnCaseId
		End
		Else Begin
			Set @sSQLString=
			"Insert into #TEMPPOLICING(CASEID, EVENTNO)"+char(10)+
			"Select CASEID, EVENTNO"+char(10)+
			"from CASEEVENT"+char(10)+
			"where CASEID=@pnCaseId"+char(10)+
			"and  EVENTNO=@nCPAModifyEvent"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPAModifyEvent	int,
							  @pnCaseId		int',
							  @nCPAModifyEvent,
							  @pnCaseId
		End
	end

	-- Record details of Cases that will have an Event inserted or Updated based on the
	-- EPL Narrative
	
	If @ErrorCode=0
	and @pnCaseId is null  /** SQA13268 ***/
	Begin

		-- Insert a row to be policed for each row that has not been rejected
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO)"+char(10)+
		"Select distinct CPA.CASEID, N.CASEEVENTNO"+char(10)+
		"from CPARECEIVE CPA"+char(10)+
		"join CPANARRATIVE N on ( CPA.NARRATIVE = N.CPANARRATIVE"+char(10)+
		"                     or (CPA.NARRATIVE like N.CPANARRATIVE AND N.CPANARRATIVE like '%\%%' ESCAPE'\'))"+char(10)+
		"join CASES C on (C.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+					-- 10731 Filter by Office
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+	-- 8721
		"and   CPA.CASEID    is not null"+char(10)+
		"and   N.CASEEVENTNO is not null"
/******* SQA13268
		"and not exists"+char(10)+
		"(select * from #TEMPREJECTEDCASES R"+char(10)+
		" where R.CASEID=CPA.CASEID"+char(10)+
		" and R.REJECTFLAG=1)"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=N.CASEEVENTNO"+char(10)+
		" and   CE.OCCURREDFLAG=1)"
******** SQA13268 ******/

		Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @pnBatchNo,
						  @psCPANarrative
	End
End


If  @ErrorCode=0
begin

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- If an Event has been identified to indicate the Case is to be modified
	-- then insert or update a CASEEVENT row if the Case has been marked for modification
	-- or if the Case has not been marked for modification then clear out the any existing
	-- CASEEVENT row for the event

	If  @nCPAModifyEvent is not null
	and @pnCaseId        is not null
	Begin
		if @pbModificationRequired=1
		Begin
			Set @sSQLString=
			"update CASEEVENT"+char(10)+
			"set EVENTDATE=convert(varchar,getdate(),112),"+char(10)+
			"OCCURREDFLAG=1"+char(10)+
			"where CASEID=@pnCaseId"+char(10)+
			"and  EVENTNO=@nCPAModifyEvent"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPAModifyEvent	int,
							  @pnCaseId		int',
							  @nCPAModifyEvent,
							  @pnCaseId

			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)"+char(10)+
				"select C.CASEID, E.EVENTNO, 1, convert(varchar,getdate(),112), 1"+char(10)+
				"from CASES C"+char(10)+
				"join EVENTS E on (E.EVENTNO=@nCPAModifyEvent)"+char(10)+
				"where C.CASEID=@pnCaseId"+char(10)+
				"and not exists"+char(10)+
				"(select * from CASEEVENT CE"+char(10)+
				" where CE.CASEID=C.CASEID"+char(10)+
				" and   CE.EVENTNO=E.EVENTNO)"
		
				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@nCPAModifyEvent	int,
								  @pnCaseId		int',
								  @nCPAModifyEvent,
								  @pnCaseId
			End
		End

		-- Case does not require Modification so we need to clear out the Event

		Else If @pbPoliceCase=1
		Begin
			-- If Policing is ON then just update the CaseEvent to clear it out as 
			-- this will cause Policing to delete it after attempting to do a recalculation
			Set @sSQLString=
			"update CASEEVENT"+char(10)+
			"set EVENTDATE=NULL,"+char(10)+
			"OCCURREDFLAG=0"+char(10)+
			"where CASEID=@pnCaseId"+char(10)+
			"and  EVENTNO=@nCPAModifyEvent"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPAModifyEvent	int,
							  @pnCaseId		int',
							  @nCPAModifyEvent,
							  @pnCaseId
		End
		Else Begin
			-- If Policing is OFF then delete the CaseEvent directly
			Set @sSQLString=
			"delete from CASEEVENT"+char(10)+
			"where CASEID=@pnCaseId"+char(10)+
			"and  EVENTNO=@nCPAModifyEvent"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPAModifyEvent	int,
							  @pnCaseId		int',
							  @nCPAModifyEvent,
							  @pnCaseId
		End
	end
	
	-- Insert or update an Event for Cases not rejected if an EventNo is available.
	If @nCPAReceivedEvent is not null
	and (@pbAcceptDifferences=1 OR @pnCaseId is null)
	Begin
		-- Now insert the CASEEVENT rows to indicate that CPA have received the case	
		-- for all cases not rejected
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)"+char(10)+
		"select CPA.CASEID, @nCPAReceivedEvent, 1, convert(varchar,getdate(),112), 1"+char(10)+
		"from CPARECEIVE CPA"+char(10)+
		"join CASES C on (C.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+					-- 10731 Filter by Office
		"join EVENTS E on (E.EVENTNO=@nCPAReceivedEvent)"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
		"and   CPA.CASEID is not null"+char(10)+
		"and   CPA.IPRURN is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from #TEMPREJECTEDCASES R"+char(10)+
		" where R.CASEID=CPA.CASEID"+char(10)+
		" and R.REJECTFLAG=1)"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=@nCPAReceivedEvent)"

		Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCPAReceivedEvent	int,
						  @pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @nCPAReceivedEvent,
						  @pnBatchNo,
						  @psCPANarrative

		-- Alternatively update the CASEEVENT rows to indicate that CPA have received the case.
		-- This handles the situation where the CaseEvent row existed as a due date only.
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Update CASEEVENT"+char(10)+
			"set EVENTDATE=convert(varchar,getdate(),112),"+char(10)+
			"    OCCURREDFLAG=1"+char(10)+
			"from CASEEVENT CE"+char(10)+
			"join CPARECEIVE CPA on (CPA.CASEID=CE.CASEID)"+char(10)+
			"join CASES C on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"where CE.EVENTNO=@nCPAReceivedEvent"+char(10)+
			"and   CE.OCCURREDFLAG=0"+char(10)+
			"and  CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and   isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and  CPA.IPRURN is not null"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES R"+char(10)+
			" where R.CASEID=CPA.CASEID"+char(10)+
			" and R.REJECTFLAG=1)"

			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCPAReceivedEvent	int,
						  @pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @nCPAReceivedEvent,
						  @pnBatchNo,
						  @psCPANarrative
		End
	End
	
	-- Insert or update an Event for Cases whose Narrative is pointing to an Event
	If @ErrorCode=0
	and @pnCaseId is null
	Begin
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)"+char(10)+
		"select distinct CPA.CASEID, N.CASEEVENTNO, 1, convert(varchar,getdate(),112), 1"+char(10)+
		"from CPARECEIVE CPA"+char(10)+
		"join CPANARRATIVE N on ( CPA.NARRATIVE = N.CPANARRATIVE"+char(10)+
		"                     or (CPA.NARRATIVE like N.CPANARRATIVE AND N.CPANARRATIVE like '%\%%' ESCAPE'\'))"+char(10)+
		"join CASES C on (C.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+					-- 10731 Filter by Office
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CPA.CASEID    is not null"+char(10)+
		"and   isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
		"and   N.CASEEVENTNO is not null"+char(10)+
/****** SQA13268
		"and not exists"+char(10)+
		"(select * from #TEMPREJECTEDCASES R"+char(10)+
		" where R.CASEID=CPA.CASEID"+char(10)+
		" and R.REJECTFLAG=1)"+char(10)+
********SQA13268 ******/
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=N.CASEEVENTNO)"

		Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @pnBatchNo,
						  @psCPANarrative

		-- Alternatively update the CASEEVENT rows.
		-- This handles the situation where the CaseEvent row existed as a due date only.
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Update CASEEVENT"+char(10)+
			"set EVENTDATE=convert(varchar,getdate(),112),"+char(10)+
			"    OCCURREDFLAG=1"+char(10)+
			"from CASEEVENT CE"+char(10)+
			"join CPARECEIVE CPA on (CPA.CASEID=CE.CASEID)"+char(10)+
			"join CPANARRATIVE N on ( CPA.NARRATIVE = N.CPANARRATIVE"+char(10)+
			"                     or (CPA.NARRATIVE like N.CPANARRATIVE AND N.CPANARRATIVE like '%\%%' ESCAPE'\'))"+char(10)+
			"join CASES C on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"where CE.EVENTNO=N.CASEEVENTNO"+char(10)+
			"and   CE.OCCURREDFLAG=0"+char(10)+
			"and   CE.CYCLE=1"       +char(10)+
			"and  CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and   isnull(CPA.ACKNOWLEDGED,0)=0"
/****** SQA13268
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES R"+char(10)+
			" where R.CASEID=CPA.CASEID"+char(10)+
			" and R.REJECTFLAG=1)"
******* SQA13268 *****/

			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @pnBatchNo,
						  @psCPANarrative
		End
	End

	-- Cases that have not been rejected are to update certain data against the Case.

	If (@pbAcceptDifferences=1 OR @pnCaseId is null)
	Begin
		-- Cases that have not been rejected but have a non matching Official Number
		-- are to have the CPA version of the Official Number saved in the database.

		-- ApplicationNo
		
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.APPLICATIONNO)), '6',1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE='6')"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.APPLICATIONNO is not null"+char(10)+
			"and ltrim(rtrim(CPA.APPLICATIONNO))<> ltrim(rtrim(S.APPLICATIONNO))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.APPLICATIONNO))),LEN(ltrim(rtrim(CPA.APPLICATIONNO)))))"+char(10)+ --SQA20008
			"			=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.APPLICATIONNO))),LEN(ltrim(rtrim(S.APPLICATIONNO)))))"+char(10)+ 
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE='6')"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							@psCPANarrative	nvarchar(50)',
							@pnBatchNo,
							@psCPANarrative
		End
	
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Update OFFICIALNUMBERS"+char(10)+
			"Set OFFICIALNUMBER= ltrim(rtrim(CPA.APPLICATIONNO))"+char(10)+
			"From OFFICIALNUMBERS OFN"+char(10)+
			"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
			"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and OFN.NUMBERTYPE='6'"+char(10)+
			"and ltrim(rtrim(CPA.APPLICATIONNO)) <> ltrim(rtrim(OFN.OFFICIALNUMBER))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.APPLICATIONNO))),LEN(ltrim(rtrim(CPA.APPLICATIONNO)))))"+char(10)+
			"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+ --SQA20008
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50)',
							  @pnBatchNo,
							  @psCPANarrative
		End
		-----------------------------------------------------------
		-- If the CPA number returned is substantially different
		-- from the number sent then an optional number type may be
		-- provided as a site control to indicate that the CPA
		-- number is to be held against the Case for later
		-- investigation.
		-----------------------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sMismatchNumberType=S.COLCHARACTER
			from SITECONTROL S
			where S.CONTROLID='CPA Mismatch-Application No'"
			
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@sMismatchNumberType	nvarchar(3)	    OUTPUT',
							  @sMismatchNumberType=@sMismatchNumberType OUTPUT
		End
		
		If @sMismatchNumberType is not null
		and @ErrorCode =0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.APPLICATIONNO)), @sMismatchNumberType,1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE=@sMismatchNumberType)"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.APPLICATIONNO is not null"+char(10)+
			"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.APPLICATIONNO))),LEN(ltrim(rtrim(CPA.APPLICATIONNO)))))"+char(10)+ 
			"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.APPLICATIONNO))),LEN(ltrim(rtrim(S.APPLICATIONNO)))))"+char(10)+ 
			"		or S.APPLICATIONNO is null)"+char(10)+  
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE=@sMismatchNumberType)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50),
							  @sMismatchNumberType	nvarchar(3)',
							  @pnBatchNo,
							  @psCPANarrative,
							  @sMismatchNumberType
							  
			-- Update the previously mismatched value if changed and still different
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Update OFFICIALNUMBERS"+char(10)+
				"Set OFFICIALNUMBER= ltrim(rtrim(CPA.APPLICATIONNO))"+char(10)+
				"From OFFICIALNUMBERS OFN"+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.APPLICATIONNO))),LEN(ltrim(rtrim(CPA.APPLICATIONNO)))))"+char(10)+
				"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+
				"		or OFN.OFFICIALNUMBER is null)"+char(10)+
				"and isnull(CPA.ACKNOWLEDGED,0)=0"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50),
							  @sMismatchNumberType	nvarchar(3)',
							  @pnBatchNo,
							  @psCPANarrative,
							  @sMismatchNumberType
							  
			End
			-- Need to remove the mismatched value if now similar to firm official number (assume already held in CPA format value).
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sApplicationNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER))))) "+char(10)+
				"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN_M.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN_M.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN_M.OFFICIALNUMBER))))))"

				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sMismatchNumberType	nvarchar(3),
								  @sApplicationNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sMismatchNumberType,
								  @sApplicationNumberType
							  
			End
			-- Also need to remove the CPA format value if now same as firm official number.
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sApplicationNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE='6'"+char(10)+
				"and ltrim(rtrim(OFN_M.OFFICIALNUMBER)) = ltrim(rtrim(OFN.OFFICIALNUMBER))"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sApplicationNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sApplicationNumberType
			End
		End
	
		-- AcceptanceNo
	
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.ACCEPTANCENO)), '7',1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE='7')"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.ACCEPTANCENO is not null"+char(10)+
			"and ltrim(rtrim(CPA.ACCEPTANCENO))<>ltrim(rtrim(S.ACCEPTANCENO))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.ACCEPTANCENO))),LEN(ltrim(rtrim(CPA.ACCEPTANCENO)))))"+char(10)+ --SQA20008
			"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(S.ACCEPTANCENO))),LEN(ltrim(rtrim(S.ACCEPTANCENO))))) "+char(10)+
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE='7')"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50)',
							  @pnBatchNo,
							  @psCPANarrative
		End
	
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Update OFFICIALNUMBERS"+char(10)+
			"Set OFFICIALNUMBER=ltrim(rtrim(CPA.ACCEPTANCENO))"+char(10)+
			"From OFFICIALNUMBERS OFN"+char(10)+
			"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
			"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and OFN.NUMBERTYPE='7'"+char(10)+
			"and ltrim(rtrim(CPA.ACCEPTANCENO)) <> ltrim(rtrim(OFN.OFFICIALNUMBER))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.ACCEPTANCENO))),LEN(ltrim(rtrim(CPA.ACCEPTANCENO)))))"+char(10)+
			"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+ --SQA20008
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50)',
							  @pnBatchNo,
							  @psCPANarrative
		End
		-----------------------------------------------------------
		-- If the CPA number returned is substantially different
		-- from the number sent then an optional number type may be
		-- provided as a site control to indicate that the CPA
		-- number is to be held against the Case for later
		-- investigation.
		-----------------------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sMismatchNumberType=S.COLCHARACTER
			from SITECONTROL S
			where S.CONTROLID='CPA Mismatch-Acceptance No'"
			
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@sMismatchNumberType	nvarchar(3)	    OUTPUT',
							  @sMismatchNumberType=@sMismatchNumberType OUTPUT
		End
		
		If @sMismatchNumberType is not null
		and @ErrorCode =0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.ACCEPTANCENO)), @sMismatchNumberType,1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE=@sMismatchNumberType)"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.ACCEPTANCENO is not null"+char(10)+
			"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.ACCEPTANCENO))),LEN(ltrim(rtrim(CPA.ACCEPTANCENO)))))"+char(10)+
			"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(S.ACCEPTANCENO))),LEN(ltrim(rtrim(S.ACCEPTANCENO)))))"+char(10)+ 
			"		or S.ACCEPTANCENO is null)"+char(10)+ 
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE=@sMismatchNumberType)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50),
							  @sMismatchNumberType	nvarchar(3)',
							  @pnBatchNo,
							  @psCPANarrative,
							  @sMismatchNumberType
							  
			-- Update the previously mismatched value if changed and still different
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Update OFFICIALNUMBERS"+char(10)+
				"Set OFFICIALNUMBER= ltrim(rtrim(CPA.ACCEPTANCENO))"+char(10)+
				"From OFFICIALNUMBERS OFN"+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.ACCEPTANCENO))),LEN(ltrim(rtrim(CPA.ACCEPTANCENO)))))"+char(10)+
				"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+ 
				"		or OFN.OFFICIALNUMBER is null)"+char(10)+ 
				"and isnull(CPA.ACKNOWLEDGED,0)=0"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sMismatchNumberType	nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sMismatchNumberType
							  
			End
			-- Need to remove the mismatched value if now similar to firm official number (assume already held in CPA format value).
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sAcceptanceNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER))))) "+char(10)+
				"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN_M.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN_M.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN_M.OFFICIALNUMBER))))))"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sMismatchNumberType	nvarchar(3),
								  @sAcceptanceNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sMismatchNumberType,
								  @sAcceptanceNumberType
							  
			End
			-- Also need to remove the CPA format value if now same as firm official number.
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sAcceptanceNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE='7'"+char(10)+
				"and ltrim(rtrim(OFN_M.OFFICIALNUMBER)) = ltrim(rtrim(OFN.OFFICIALNUMBER))"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sAcceptanceNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sAcceptanceNumberType
							  
			End
		End
	
		-- PublicationNo
	
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.PUBLICATIONNO)), '8',1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE='8')"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.PUBLICATIONNO is not null"+char(10)+
			"and ltrim(rtrim(CPA.PUBLICATIONNO))<> ltrim(rtrim(S.PUBLICATIONNO))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.PUBLICATIONNO))),LEN(ltrim(rtrim(CPA.PUBLICATIONNO)))))"+char(10)+ --SQA20008
			"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.PUBLICATIONNO))),LEN(ltrim(rtrim(S.PUBLICATIONNO))))) "+char(10)+
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE='8')"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50)',
							  @pnBatchNo,
							  @psCPANarrative
		End
	
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Update OFFICIALNUMBERS"+char(10)+
			"Set OFFICIALNUMBER=ltrim(rtrim(CPA.PUBLICATIONNO))"+char(10)+
			"From OFFICIALNUMBERS OFN"+char(10)+
			"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
			"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and OFN.NUMBERTYPE='8'"+char(10)+
			"and ltrim(rtrim(CPA.PUBLICATIONNO)) <> ltrim(rtrim(OFN.OFFICIALNUMBER))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.PUBLICATIONNO))),LEN(ltrim(rtrim(CPA.PUBLICATIONNO)))))"+char(10)+
			"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+ --SQA20008
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50)',
							  @pnBatchNo,
							  @psCPANarrative
							  
		End
		-----------------------------------------------------------
		-- If the CPA number returned is substantially different
		-- from the number sent then an optional number type may be
		-- provided as a site control to indicate that the CPA
		-- number is to be held against the Case for later
		-- investigation.
		-----------------------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sMismatchNumberType=S.COLCHARACTER
			from SITECONTROL S
			where S.CONTROLID='CPA Mismatch-Publication No'"
			
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@sMismatchNumberType	nvarchar(3)	    OUTPUT',
							  @sMismatchNumberType=@sMismatchNumberType OUTPUT
		End
		
		If @sMismatchNumberType is not null
		and @ErrorCode =0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.PUBLICATIONNO)), @sMismatchNumberType,1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE=@sMismatchNumberType)"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.PUBLICATIONNO is not null"+char(10)+
			"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.PUBLICATIONNO))),LEN(ltrim(rtrim(CPA.PUBLICATIONNO)))))"+char(10)+
			"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.PUBLICATIONNO))),LEN(ltrim(rtrim(S.PUBLICATIONNO)))))"+char(10)+ 
			"		or S.PUBLICATIONNO is null)"+char(10)+ 
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE=@sMismatchNumberType)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50),
							  @sMismatchNumberType	nvarchar(3)',
							  @pnBatchNo,
							  @psCPANarrative,
							  @sMismatchNumberType
							  
			-- Update the previously mismatched value if changed and still different		
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Update OFFICIALNUMBERS"+char(10)+
				"Set OFFICIALNUMBER= ltrim(rtrim(CPA.PUBLICATIONNO))"+char(10)+
				"From OFFICIALNUMBERS OFN"+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.PUBLICATIONNO))),LEN(ltrim(rtrim(CPA.PUBLICATIONNO)))))"+char(10)+
				"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+
				"		or OFN.OFFICIALNUMBER is null)"+char(10)+ 
				"and isnull(CPA.ACKNOWLEDGED,0)=0"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sMismatchNumberType	nvarchar(3)',
								  @pnBatchNo,								  
								  @psCPANarrative,
								  @sMismatchNumberType
			End
			-- Need to remove the mismatched value if now similar to firm official number (assume already held in CPA format value).
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sPublicationNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER))))) "+char(10)+
				"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN_M.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN_M.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN_M.OFFICIALNUMBER))))))"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sMismatchNumberType	nvarchar(3),
								  @sPublicationNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sMismatchNumberType,
								  @sPublicationNumberType
							  
			End
			-- Also need to remove the CPA format value if now same as firm official number.
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sPublicationNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE='8'"+char(10)+
				"and ltrim(rtrim(OFN_M.OFFICIALNUMBER)) = ltrim(rtrim(OFN.OFFICIALNUMBER))"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sPublicationNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sPublicationNumberType
							  
			End
		End
	
		-- RegistrationNo
	
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.REGISTRATIONNO)), '9',1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE='9')"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.REGISTRATIONNO is not null"+char(10)+
			"and ltrim(rtrim(CPA.REGISTRATIONNO))<>ltrim(rtrim(S.REGISTRATIONNO))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.REGISTRATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.REGISTRATIONNO))),LEN(ltrim(rtrim(CPA.REGISTRATIONNO)))))"+char(10)+ --SQA20008
			"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.REGISTRATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.REGISTRATIONNO))),LEN(ltrim(rtrim(S.REGISTRATIONNO))))) "+char(10)+
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE='9')"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50)',
							  @pnBatchNo,
							  @psCPANarrative
						  
		End
	
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Update OFFICIALNUMBERS"+char(10)+
			"Set OFFICIALNUMBER=ltrim(rtrim(CPA.REGISTRATIONNO))"+char(10)+
			"From OFFICIALNUMBERS OFN"+char(10)+
			"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
			"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and OFN.NUMBERTYPE='9'"+char(10)+
			"and ltrim(rtrim(CPA.REGISTRATIONNO)) <> ltrim(rtrim(OFN.OFFICIALNUMBER))"+char(10)+
			"and dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.REGISTRATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.REGISTRATIONNO))),LEN(ltrim(rtrim(CPA.REGISTRATIONNO)))))"+char(10)+
			"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from #TEMPREJECTEDCASES T"+char(10)+
			" where T.CASEID=CPA.CASEID"+char(10)+
			" and T.REJECTFLAG=1)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50)',
							  @pnBatchNo,
							  @psCPANarrative
							  
		End
		-----------------------------------------------------------
		-- If the CPA number returned is substantially different
		-- from the number sent then an optional number type may be
		-- provided as a site control to indicate that the CPA
		-- number is to be held against the Case for later
		-- investigation.
		-----------------------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @sMismatchNumberType=S.COLCHARACTER
			from SITECONTROL S
			where S.CONTROLID='CPA Mismatch-Registration No'"
			
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@sMismatchNumberType	nvarchar(3)	    OUTPUT',
							  @sMismatchNumberType=@sMismatchNumberType OUTPUT
		End
		
		If @sMismatchNumberType is not null
		and @ErrorCode =0
		Begin
			Set @sSQLString=
			"Insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT)"+char(10)+
			"Select CPA.CASEID, ltrim(rtrim(CPA.REGISTRATIONNO)), @sMismatchNumberType,1"+char(10)+
			"From CPARECEIVE CPA"+char(10)+
			"join CPASENDCOMPARE S     on (S.CASEID =CPA.CASEID"+char(10)+
			"				and S.BATCHNO= (select max (BATCHNO)"+char(10)+
			"				from CPASENDCOMPARE "+char(10)+
			"				where CASEID = CPA.CASEID))"+char(10)+
			"join NUMBERTYPES N on (N.NUMBERTYPE=@sMismatchNumberType)"+char(10)+
			"join CASES C 	    on (C.CASEID=CPA.CASEID)"+char(10)+
			@sOfficeJoin+					-- 10731 Filter by Office
			"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
			"and CPA.REGISTRATIONNO is not null"+char(10)+
			"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.REGISTRATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.REGISTRATIONNO))),LEN(ltrim(rtrim(CPA.REGISTRATIONNO)))))"+char(10)+
			"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.REGISTRATIONNO,PATINDEX('%[^0]%',S.REGISTRATIONNO),LEN(S.REGISTRATIONNO)))"+char(10)+ 
			"		or S.REGISTRATIONNO is null)"+char(10)+ 
			"and isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
			"and not exists"+char(10)+
			"(select * from OFFICIALNUMBERS OFN"+char(10)+
			" where OFN.CASEID=CPA.CASEID"+char(10)+
			" and   OFN.NUMBERTYPE=@sMismatchNumberType)"
	
			Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50),
							  @sMismatchNumberType	nvarchar(3)',
							  @pnBatchNo,
							  @psCPANarrative,
							  @sMismatchNumberType

			-- Update the previously mismatched value if changed and still different		
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Update OFFICIALNUMBERS"+char(10)+
				"Set OFFICIALNUMBER= ltrim(rtrim(CPA.REGISTRATIONNO))"+char(10)+
				"From OFFICIALNUMBERS OFN"+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=CPA.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"Where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(CPA.REGISTRATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(CPA.REGISTRATIONNO))),LEN(ltrim(rtrim(CPA.REGISTRATIONNO)))))"+char(10)+
				"		<>dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER)))))"+char(10)+ 
				"		or OFN.OFFICIALNUMBER is null)"+char(10)+ 
				"and isnull(CPA.ACKNOWLEDGED,0)=0"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @psCPANarrative	nvarchar(50),
							  @sMismatchNumberType	nvarchar(3)',
							  @pnBatchNo,
							  @psCPANarrative,
							  @sMismatchNumberType
			End
			-- Need to remove the mismatched value if now similar to firm official number (assume already held in CPA format value).
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sRegistrationNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE=@sMismatchNumberType"+char(10)+
				"and (dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN.OFFICIALNUMBER))))) "+char(10)+
				"		=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(OFN_M.OFFICIALNUMBER)),PATINDEX('%[^0]%',ltrim(rtrim(OFN_M.OFFICIALNUMBER))),LEN(ltrim(rtrim(OFN_M.OFFICIALNUMBER))))))"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sMismatchNumberType	nvarchar(3),
								  @sRegistrationNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sMismatchNumberType,
								  @sRegistrationNumberType
							  
			End
			-- Also need to remove the CPA format value if now same as firm official number.
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"Delete OFN_M"+char(10)+
				"from OFFICIALNUMBERS OFN_M"+char(10)+
				"left join OFFICIALNUMBERS OFN on (OFN.CASEID = OFN_M.CASEID "+char(10)+
				"				and OFN.NUMBERTYPE in ("+@sRegistrationNumberType+")"+char(10)+
				"				and OFN.ISCURRENT =1) "+char(10)+
				"join CPARECEIVE CPA on (CPA.CASEID=OFN_M.CASEID)"+char(10)+
				"join CASES C 	     on (C.CASEID=OFN_M.CASEID)"+char(10)+
				@sOfficeJoin+					-- 10731 Filter by Office
				"where CPA.BATCHNO=@pnBatchNo"+char(10)+
				"and OFN_M.NUMBERTYPE='9'"+char(10)+
				"and ltrim(rtrim(OFN_M.OFFICIALNUMBER)) = ltrim(rtrim(OFN.OFFICIALNUMBER))"
		
				Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter
	
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnBatchNo		int,
								  @psCPANarrative	nvarchar(50),
								  @sRegistrationNumberType nvarchar(3)',
								  @pnBatchNo,
								  @psCPANarrative,
								  @sRegistrationNumberType
							  
			End
		End
	End
	-- End section official number update

	-- If cases rows that do not match are to be rejected then 
	-- insert or update a CaseEvent for each rejected case in the batch
	If  @nCPARejectedEvent is not null
	and @pbAcceptDifferences=0
	and @ErrorCode=0
	Begin
		-- Now insert the CASEEVENT rows to indicate that the record has been rejected
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)"+char(10)+
		"select CPA.CASEID, @nCPARejectedEvent, 1, convert(varchar,getdate(),112), 1"+char(10)+
		"from #TEMPREJECTEDCASES CPA"+char(10)+
		"join EVENTS E on (E.EVENTNO=@nCPARejectedEvent)"+char(10)+
		"join CASES C  on (C.CASEID=CPA.CASEID)"+char(10)+
		"where CPA.REJECTFLAG=1"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=@nCPARejectedEvent)"

		Set @sSQLString=@sSQLString+char(10)+@sWhere

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCPARejectedEvent	int',
						  @nCPARejectedEvent

		-- Now update the CASEEVENT rows to indicate that the case has been rejected.
		-- This handles the situation where the CaseEvent row existed as a due date only.
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Update CASEEVENT"+char(10)+
			"set EVENTDATE=convert(varchar,getdate(),112),"+char(10)+
			"    OCCURREDFLAG=1"+char(10)+
			"from CASEEVENT CE"+char(10)+
			"join #TEMPREJECTEDCASES CPA on (CPA.CASEID=CE.CASEID"+char(10)+
			"                            and CPA.REJECTFLAG=1)"+char(10)+
			"where CE.EVENTNO=@nCPARejectedEvent"+char(10)+
			"and   CE.OCCURREDFLAG=0"

			Set @sSQLString=@sSQLString+char(10)+@sWhere

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCPARejectedEvent	int',
						  @nCPARejectedEvent
		End
	End

	-- Insert a Policing request for each CASEID.
	-- (Previous reference to Site Control setting no longer relevant - removed by MF 17 Jan 2014)
	
	If  @ErrorCode=0
	begin
		Set @sSQLString="
		insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
					ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		select	getdate(), T.POLICINGSEQNO, convert(varchar, getdate(),126)+convert(varchar,T.POLICINGSEQNO),1,0,
			T.EVENTNO, T.CASEID, 1, 3, substring(SYSTEM_USER,1,18), @pnUserIdentityId
		from #TEMPPOLICING T"

		Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	 int',
				@pnUserIdentityId = @pnUserIdentityId
	end

	-- Cases that are to be accepted are to be marked as Acknowledged.
	
	If (@pbAcceptDifferences=1 OR @pnCaseId is null)
	and @ErrorCode=0
	Begin
		Set @sSQLString=
		"Update CPASEND"+char(10)+
		"Set ACKNOWLEDGED=1,"+char(10)+
		"    NARRATIVE=NULL"+char(10)+	-- SQA16508
		"from CPASEND S"+char(10)+
		"join CPARECEIVE CPA on (CPA.CASEID =S.CASEID"+char(10)+
		"                    and CPA.BATCHNO=S.BATCHNO)"+char(10)+
		"join CASES C 	     on (C.CASEID=S.CASEID)"+char(10)+
		@sOfficeJoin+					-- 10731 Filter by Office
		"where S.BATCHNO=@pnBatchNo"+char(10)+
		"and   isnull(S.ACKNOWLEDGED,0)=0"+char(10)+  -- 8721 
		"and   S.CASEID is not null"+char(10)+
		"and   CPA.IPRURN   is not null"+char(10)+	-- Only accept if the Case is on the CPA Portfolio
		"and not exists"+char(10)+
		"(select * from #TEMPREJECTEDCASES R"+char(10)+
		" where R.CASEID=S.CASEID"+char(10)+
		" and R.REJECTFLAG=1)"
		Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @pnBatchNo,
						  @psCPANarrative	
	End

	-- Cases that are to be rejected are to be marked as Acknowledged and have the user
	-- entered Narrative updated
	If  @pbAcceptDifferences=0
	and @ErrorCode=0
	Begin
		Set @sSQLString=
		"Update CPASEND"+char(10)+
		"Set ACKNOWLEDGED=1,"+char(10)+
		"    NARRATIVE=@psNarrative"+char(10)+
		"from CPASEND CPA"+char(10)+
		"join #TEMPREJECTEDCASES R on (R.CASEID=CPA.CASEID)"+char(10)+
		"where R.REJECTFLAG=1"+char(10)+
		"and CPA.BATCHNO=@pnBatchNo"

		Set @sSQLString=@sSQLString+char(10)+@sWhere

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@psNarrative	nvarchar(50),
						  @pnBatchNo	int',
						  @psNarrative,
						  @pnBatchNo
	end

	-- Update the CPARECEIVE rows to indicate that they have either been rejected or accepted.
		
	If @ErrorCode=0
	Begin
		Set @sSQLString=
		"Update CPARECEIVE"+char(10)+
		"set ACKNOWLEDGED=1"+char(10)+
		"from CPARECEIVE CPA"+char(10)+
		"join CPASEND S on (S.CASEID =CPA.CASEID"+char(10)+
		"               and S.BATCHNO=CPA.BATCHNO)"+char(10)+
		"join CASES C   on (C.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+					-- Filter by Office
		"where isnull(CPA.ACKNOWLEDGED,0)=0"+char(10)+
		"and CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and  S.ACKNOWLEDGED=1"

		Set @sSQLString=@sSQLString+char(10)+@sWhere+@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psCPANarrative	nvarchar(50)',
						  @pnBatchNo,
						  @psCPANarrative	
	End

	-- Commit the transaction if it has successfully completed

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-- The Result Set should return the CaseIds of the Cases rejected only if 
-- the AcceptDifferences flag is set to NULL to indicate a decision is
-- required by the operator

If @ErrorCode=0
Begin
	If @pbAcceptDifferences is null
	Begin
		Set @sSQLString="
		select @ErrorCode, T.CASEID
		from #TEMPREJECTEDCASES T
		order by T.CASEID"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@ErrorCode		int',
						  @ErrorCode
	End
End
Else Begin
	select @ErrorCode, NULL
End

Return @ErrorCode
go

grant execute on dbo.cpa_BatchComparison to public
go
