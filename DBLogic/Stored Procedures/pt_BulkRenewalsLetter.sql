-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_BulkRenewalsLetter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pt_BulkRenewalsLetter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pt_BulkRenewalsLetter.'
	Drop procedure [dbo].[pt_BulkRenewalsLetter]
End
Print '**** Creating Stored Procedure dbo.pt_BulkRenewalsLetter...'
Print ''
GO

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE [dbo].[pt_BulkRenewalsLetter]
		@psEntryPoint		nvarchar(30),
		@psWhenRequested	varchar(50),
		@psSqlUser		nvarchar(40),
		@psCaseId		varchar(20),
		@psAlwayRecalculate	char(1)	= '0'	,	-- this flag forces a new calculation to be performed when set to '1'
		@psSaveTheEstimate	char(1)	= '1',		-- this flag causes the estimate to be saved when set to '1'
		@pnUserIdentityId	int	= null

as
-- PROCEDURE :	pt_BulkRenewalsLetter
-- VERSION :	16
-- DESCRIPTION:	Returns the Case Reference (IRN) of Cases from ACTIVITYREQUEST rows for the same letter
--		going to the same Renewal Instructor.  Used to consolidate multiple letters into a single letter.
-- COPYRIGHT : 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2003	JEK	RFC621	1	Procedure created
-- 17/01/2001	CS			Procedure created
-- 05/03/2003	MF			Explicitly list columns in ACTIVITYHISTORY as new columns
--					have been added.
-- 20/03/2003	MF			Also return the Bad Debtor details and the Entity Size
-- 26/01/2004   MVT             	Make this work for BWT.
-- 20/05/2004   MVT    1:       	bulk renewals report has been run for a particular month, then instruction are received on some
--                              	cases, If for some reason, the re port needs to be re-produced, for the cases on which instructions
--                              	have been received, the entry should be suppressed on the report.
-- 03/12/2004	AB	10763		Formatting, naming, case-sensitivity errors, add collate database_default syntax,
--					change definitions to doublebyte
-- 18/04/2005	JB	11237	2	Fixed format for case-sensitive servers and comments to /*
-- 24/05/2005	TM	RFC1990	3	Increase Stem defined in #TEMPCASEDETAILS to 30 characters.
-- 16/11/2005	vql	9704	4	When updating ACTIVITYHISTORY table insert @pnUserIdentityId. Create @pnUserIdentityId also.
-- 11 AUG 2007	DL	16723	5	Tag ACTIVITYHISTORY rows that being consolidated with the current request to allow DocGen to attach the letter to cases.
-- 28 Sep 2007	CR	14901	6	Changed Exchange Rate field sizes to (8,4)
-- 15 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 21 Oct 2011	DL	19708	8	Change @psSqlUser from varchar(20) to nvarchar(40) to match ACTIVITYREQUEST.SQLUSER
-- 05 Dec 2011	LP	R11070	9	Default instruction at office level where available, before falling back to home name instruction.
-- 05 Jul 2013	vql	R13629	10	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 13 Sep 2013	MF	S21588	11	Correction to SQL introduced with RFC11070
-- 17 Sep 2013	MF	S21588	12	Failed testing.
-- 02 May 2014	SF 	33461	13	IDENTITYID from the ACTIVITYREQUEST should not be lost.
-- 05 Jan 2015	MF	43043	14	Changes to support unicode and increase IRN to 30 characters..
-- 20 Oct 2015  MS      R53933  15      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 14 Nov 2018  AV  75198/DR-45358	16   Date conversion errors when creating cases and opening names in Chinese DB

Set NOCOUNT on
Set CONCAT_NULL_YIELDS_NULL off
Set ANSI_WARNINGS off

Create	table #TEMPCASEDETAILS (
			CASEID			int,
			IRN			nvarchar(30)  	collate database_default null,
                        TITLE                   nvarchar(254) 	collate database_default null,
			FAMILY			nvarchar(20)	collate database_default null,
			STEM			nvarchar(30)	collate database_default null,
			OFFICIALNO		nvarchar(36)	collate database_default null,
			PARENTNO		nvarchar(36)	collate database_default null,
			CLIENTSREF		nvarchar(50)	collate database_default null,
			COUNTRYCODE		nvarchar(3)  	collate database_default null,
			COUNTRYADJECTIVE	nvarchar(60) 	collate database_default null,
			PROPERTYTYPE		nvarchar(2) 	collate database_default null,
			PROPERTYNAME		nvarchar(50) 	collate database_default null,
			CASECATEGORYDESC	nvarchar(50)	collate database_default null,
			ENTITYSIZE		nvarchar(80)	collate database_default null,
			DEBTORSTATUS		nvarchar(50)	collate database_default null,
			RENEWINSTNAMENO		int		null,
			OWNERNAMENO		int		null,
			OWNERNAME		nvarchar(254)	collate database_default null,
			NEXTRENEWALDATE		datetime	null,
			RENEWALYEAR		smallint	null,
			RENEWALTERM		smallint	null,
			REREGISTRATION		nvarchar(60)	collate database_default null,
			CYCLE			smallint	null,
			AGEOFCASE		nvarchar(10)	collate database_default null,
                        COST                    decimal (11,2)  NULL,
                        CASEDETAILS             nvarchar (254) 	collate database_default null,
                        APPLICANT               nvarchar (254) 	collate database_default null,
                        LOCALCLASSES            nvarchar (254) 	collate database_default null,
                        RENEWALOCCURREDFLAG     decimal (5,2) 	NULL,
                        OFFICEID		int		NULL
			)

Declare @sIRN			nvarchar(30)
Declare @dtCurrentLetterDate	datetime
Declare @dtOldLetterDate	datetime
Declare @dtWhenOccurred 	datetime
Declare @dtWhenRequested	datetime
Declare @nProcessedFlag		int
Declare @nLetterNo		int
Declare @nCaseId		int
Declare	@ErrorCode		int
Declare @TranCountStart		int
Declare @nForeignAssociate	int
Declare @nClientCategory	int
Declare @sSQLString		nvarchar(max),
	@prsDisbCurrency	nvarchar(3),
	@prnDisbExchRate	decimal(11,4),
	@prsServCurrency	nvarchar(3),
	@prnServExchRate	decimal(11,4),
	@prsBillCurrency	nvarchar(3),
	@prnBillExchRate	decimal(11,4),
	@prsDisbTaxCode		nvarchar(3),
	@prsServTaxCode		nvarchar(3),
	@prnDisbNarrative	int,
	@prnServNarrative	int,
	@prsDisbWIPCode		nvarchar(6),
	@prsServWIPCode		nvarchar(6),
	@prnDisbOrigAmount	decimal(11,2),
	@prnDisbHomeAmount	decimal(11,2),
	@prnDisbBillAmount	decimal(11,2),
	@prnServOrigAmount	decimal(11,2),
	@prnServHomeAmount	decimal(11,2),
	@prnServBillAmount	decimal(11,2),
	@prnTotHomeDiscount	decimal(11,2),
	@prnTotBillDiscount	decimal(11,2),
	@prnDisbTaxAmt		decimal(11,2),
	@prnDisbTaxHomeAmt	decimal(11,2),
	@prnDisbTaxBillAmt	decimal(11,2),
	@prnServTaxAmt		decimal(11,2),
	@prnServTaxHomeAmt	decimal(11,2),
	@prnServTaxBillAmt	decimal(11,2),
	-- MF 27/02/2002 Add new output parameters to return the new components of the calculation
	@prnDisbDiscOriginal	decimal(11,2),
	@prnDisbHomeDiscount 	decimal(11,2),
	@prnDisbBillDiscount 	decimal(11,2),
	@prnServDiscOriginal	decimal(11,2),
	@prnServHomeDiscount 	decimal(11,2),
	@prnServBillDiscount 	decimal(11,2),
	@prnDisbCostHome	decimal(11,2),
	@prnDisbCostOriginal	decimal(11,2),
	@propertytype     	nchar(1),
        @cAgeOfCase             nvarchar(10),
	@nActivityId		int

Select	@ErrorCode		= 0
Select	@nForeignAssociate	= 601
Select	@sIRN               	= @psEntryPoint
Select	@dtCurrentLetterDate 	= getdate()
Select	@nCaseId		= convert(int, @psCaseId)
Select	@dtOldLetterDate	= NULL
Select	@nProcessedFlag		= NULL
Select	@nLetterNo		= NULL
Select	@dtWhenOccurred		= NULL

-- Convert the WhenRequested parameter from the international date format to a normal date
If patindex('%}%', @psWhenRequested)>0
	Select @dtWhenRequested = convert(datetime,substring(@psWhenRequested,7,23),121)
Else
	Select @dtWhenRequested = convert(datetime,@psWhenRequested)

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
End

-- Check the ActivityRequest row, if it has a WhenOccurred date then it is a
-- reprint that was recovered from ACTIVITYHISTORY.
If @ErrorCode=0
Begin
	Set @sSQLString="
		Select	@dtOldLetterDateOUT = AR.LETTERDATE,
			@dtWhenOccurredOUT  = AR.WHENOCCURRED,
			@nLetterNoOUT       = AR.LETTERNO,
			@nActivityId	    = AR.ACTIVITYID
		from	ACTIVITYREQUEST AR
		where	WHENREQUESTED = @dtWhenRequested
		and	AR.CASEID     = @nCaseId
		and	AR.SQLUSER    = @psSqlUser"

	Execute @ErrorCode=sp_executesql @sSQLString,
					N'@dtWhenRequested      datetime,
					  @nCaseId              int,
					  @psSqlUser            nvarchar(40),
					  @dtOldLetterDateOUT	datetime OUTPUT,
					  @dtWhenOccurredOUT	datetime OUTPUT,
					  @nLetterNoOUT		int      OUTPUT,
					  @nActivityId		int	 OUTPUT',
					  @dtWhenRequested,
					  @nCaseId,
					  @psSqlUser,
					  @dtOldLetterDateOUT=@dtOldLetterDate OUTPUT,
					  @dtWhenOccurredOUT =@dtWhenOccurred  OUTPUT,
					  @nLetterNoOUT      =@nLetterNo       OUTPUT,
					  @nActivityId	     = @nActivityId	OUTPUT
End

If @ErrorCode=0
Begin

	If @dtWhenOccurred is null /* and @@rowcount >0 */
	Begin
		-- Copy all of the ACTIVITYREQUEST rows for the same Instructor and same Letterno
		-- to the ACTIVITYHISTORY table
		Print '(1) Letter No: ' + CAST(@nLetterNo as varchar(100))
		Print 'Letter Date: ' +  CAST(@dtCurrentLetterDate as varchar(100))
		Print 'Case ID:' + CAST(@nCaseId as varchar(100))


		Set @sSQLString="
		Insert into ACTIVITYHISTORY (CASEID,WHENREQUESTED,SQLUSER,QUESTIONNO,INSTRUCTOR,OWNER,EMPLOYEENO,
			PROGRAMID,ACTION,EVENTNO,CYCLE,LETTERNO,ALTERNATELETTER,COVERINGLETTERNO,HOLDFLAG,
			SPLITBILLFLAG,BILLPERCENTAGE,DEBITNOTENO,ENTITYNO,DEBTORNAMETYPE,DEBITNOTEDETAIL,
			LETTERDATE,DELIVERYID,ACTIVITYTYPE,ACTIVITYCODE,PROCESSED,TRANSACTIONFLAG,PRODUCECHARGES,
			WHENOCCURRED,STATUSCODE,RATENO,PAYFEECODE,ENTEREDQUANTITY,ENTEREDAMOUNT,DISBCURRENCY,
			DISBEXCHANGERATE,SERVICECURRENCY,SERVEXCHANGERATE,BILLCURRENCY,BILLEXCHANGERATE,
			DISBTAXCODE,SERVICETAXCODE,DISBNARRATIVE,SERVICENARRATIVE,DISBAMOUNT,SERVICEAMOUNT,
			DISBTAXAMOUNT,SERVICETAXAMOUNT,TOTALDISCOUNT,DISBWIPCODE,SERVICEWIPCODE,SYSTEMMESSAGE,
			DISBEMPLOYEENO,SERVEMPLOYEENO,IDENTITYID, GROUPACTIVITYID)
		select 	AR.CASEID,WHENREQUESTED,SQLUSER,QUESTIONNO,INSTRUCTOR,OWNER,EMPLOYEENO,PROGRAMID,ACTION,EVENTNO,
			CYCLE,LETTERNO,ALTERNATELETTER,COVERINGLETTERNO,1,SPLITBILLFLAG,  
			/*  change the holdflag to 1 */
			AR.BILLPERCENTAGE,DEBITNOTENO,ENTITYNO,DEBTORNAMETYPE,
			DEBITNOTEDETAIL,@dtCurrentLetterDate,DELIVERYID,ACTIVITYTYPE,
			ACTIVITYCODE,1,TRANSACTIONFLAG,PRODUCECHARGES,@dtCurrentLetterDate,
			AR.STATUSCODE,RATENO,PAYFEECODE,ENTEREDQUANTITY,ENTEREDAMOUNT,
			DISBCURRENCY,DISBEXCHANGERATE,SERVICECURRENCY,SERVEXCHANGERATE,
			BILLCURRENCY,BILLEXCHANGERATE,DISBTAXCODE,SERVICETAXCODE,
			DISBNARRATIVE,SERVICENARRATIVE,DISBAMOUNT,SERVICEAMOUNT,
			DISBTAXAMOUNT,SERVICETAXAMOUNT,TOTALDISCOUNT,DISBWIPCODE,
			SERVICEWIPCODE,SYSTEMMESSAGE,DISBEMPLOYEENO,SERVEMPLOYEENO,isnull(AR.IDENTITYID, @pnUserIdentityId), 
			@nActivityId
		from	CASENAME CN
		join	ACTIVITYREQUEST AR on (AR.CASEID in (Select CN1.CASEID
							     from CASENAME CN1
							     where CN1.CASEID <>CN.CASEID
							     and   CN1.NAMENO  =CN.NAMENO
							     and   CN1.NAMETYPE=CN.NAMETYPE)
			and AR.LETTERNO=@nLetterNo)
		where	CN.CASEID   =@nCaseId
		and	CN.NAMETYPE = 'R'"

		Execute @ErrorCode=sp_executesql @sSQLString,
							N'@nCaseId              int,
							  @dtCurrentLetterDate	datetime,
							  @nLetterNo            int,
							  @pnUserIdentityId	int,
							  @nActivityId		int',
							  @nCaseId,
							  @dtCurrentLetterDate,
							  @nLetterNo,
							  @pnUserIdentityId=@pnUserIdentityId,
							  @nActivityId = @nActivityId
		/* Now delete activiyrequest that has just been copied to history,
		Take Note: This will prevent another copy of the same letter being initiated by
		the activityrequest for another case of the same instructor and letterno being printed.*/

		Set @sSQLString="
                Delete  ACTIVITYREQUEST
		from	CASENAME CN
		join	ACTIVITYREQUEST AR	on (AR.CASEID in (Select CN1.CASEID
								from CASENAME CN1
								where CN1.CASEID <>CN.CASEID
								and   CN1.NAMENO  =CN.NAMENO
								and   CN1.NAMETYPE=CN.NAMETYPE)
							and AR.LETTERNO=@nLetterNo)
		where	CN.CASEID   =@nCaseId
		and	CN.NAMETYPE = 'R'"

		Execute @ErrorCode=sp_executesql @sSQLString,
							N'@nCaseId              int,
							  @dtCurrentLetterDate	datetime,
							  @nLetterNo            int',
							  @nCaseId,
							  @dtCurrentLetterDate,
							  @nLetterNo
	End
	Else 
	Begin
		-- If the Letters have previously been processed there is no need to move
		-- them to ActivityHistory however the LetterDate and WhenOccurred need
		-- to be updated
		Set @sSQLString="
		Update	ACTIVITYHISTORY
		set	WHENOCCURRED = @dtCurrentLetterDate,
			LETTERDATE   = @dtCurrentLetterDate
		from	ACTIVITYHISTORY AH
		join	CASENAME CN	on (CN.CASEID=AH.CASEID
					and CN.NAMETYPE='R'
					and CN.NAMENO =(Select min(CN1.NAMENO)
							from CASENAME CN1
							where CN1.CASEID=@nCaseId
							and   CN1.NAMETYPE=CN.NAMETYPE))
		where AH.LETTERNO   = @nLetterNo
		and   AH.LETTERDATE = @dtOldLetterDate"

		Execute @ErrorCode=sp_executesql @sSQLString,
							N'@nCaseId		int,
							  @nLetterNo		int,
							  @dtCurrentLetterDate	datetime,
							  @dtOldLetterDate	datetime',
							  @nCaseId,
							  @nLetterNo,
							  @dtCurrentLetterDate,
							  @dtOldLetterDate
	End

End

If @ErrorCode=0
Begin
        /* Update the main ActivityRequest row that is currently being processed
	by setting its LETTERDATE and WHENOCCURRED date. */

	Set @sSQLString="
	Update	ACTIVITYREQUEST
	set	WHENOCCURRED = @dtCurrentLetterDate,
		LETTERDATE   = @dtCurrentLetterDate
	from	ACTIVITYREQUEST AR
	where	WHENREQUESTED = @dtWhenRequested
	and	AR.CASEID     = @nCaseId"

	Execute @ErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int,
						  @dtCurrentLetterDate	datetime,
						  @dtWhenRequested	datetime',
						  @nCaseId,
						  @dtCurrentLetterDate,
						  @dtWhenRequested
End

If @ErrorCode=0
Begin
	-- Now delete the ActivityRequest rows moved to ActivityHistory
	Set @sSQLString="
	Delete	ACTIVITYREQUEST
	from	CASES C
	join 	CASENAME CN		on (CN.CASEID  =C.CASEID
					and CN.NAMETYPE='R')
	join	ACTIVITYREQUEST AR	on (AR.LETTERNO=@nLetterNo
					and AR.CASEID in (	Select	CN1.CASEID
								from	CASENAME CN1
								where	CN1.NAMETYPE = 'R'
								and	CN1.NAMENO   = CN.NAMENO
								and	CN1.CASEID  <> C.CASEID) )
	where	C.IRN       = @sIRN
	and	AR.LETTERNO = @nLetterNo"
End

If @ErrorCode=0
Begin
	/* Return the data for each of the ActivityRequest and ActivityHistory rows
	   being consolidated onto the one letter.  If there are any Cases used in
	   Reregistrations then return a row for each of the different
	   registration countries */

	Set @sSQLString="
	Insert into #TEMPCASEDETAILS (CASEID, CYCLE, REREGISTRATION, IRN, LOCALCLASSES)
	Select	DISTINCT AR.CASEID, AR.CYCLE, CT.COUNTRY, C.IRN,  C.LOCALCLASSES
	from	ACTIVITYREQUEST AR
	left join RELATEDCASE R on (R.RELATEDCASEID=AR.CASEID
				and R.RELATIONSHIP ='RER')
	left join CASES C	on (C.CASEID       =AR.CASEID)
	left join STATUS S	on (S.STATUSCODE   =C.STATUSCODE
				and S.LIVEFLAG     =1)
	left join COUNTRY CT	on (CT.COUNTRYCODE =C.COUNTRYCODE)
	where	DATEDIFF (dd, AR.WHENREQUESTED , @dtWhenRequested) = 0
	and	AR.CASEID  = @nCaseId
        and  AR.LETTERNO   = @nLetterNo

	UNION

        Select	distinct AR.CASEID, AR.CYCLE, CT.COUNTRY, C.IRN, C.LOCALCLASSES
	from	ACTIVITYREQUEST AR
	left join RELATEDCASE R on (R.RELATEDCASEID=AR.CASEID
				and R.RELATIONSHIP ='RER')
	left join CASES C	on (C.CASEID       =AR.CASEID)
	left join STATUS S	on (S.STATUSCODE   =C.STATUSCODE
				and S.LIVEFLAG     =1)
	join	CASENAME CN	on (CN.CASEID=AR.CASEID
				and CN.NAMETYPE='R'
				and CN.NAMENO =(Select min(CN1.NAMENO)
						from  CASENAME CN1
						where CN1.CASEID= @nCaseId
						and   CN1.NAMETYPE=CN.NAMETYPE))
	left join COUNTRY CT	on (CT.COUNTRYCODE =C.COUNTRYCODE)
	where	DATEDIFF (dd, AR.WHENREQUESTED ,  @dtWhenRequested) = 0
        and  AR.LETTERNO   = @nLetterNo


        UNION

	Select	AH.CASEID, AH.CYCLE, CT.COUNTRY, C.IRN, C.LOCALCLASSES
	from 	ACTIVITYHISTORY AH
	join	CASENAME CN	on (CN.CASEID=AH.CASEID
				and CN.NAMETYPE='R'
				and CN.NAMENO =(Select min(CN1.NAMENO)
						from  CASENAME CN1
						where CN1.CASEID=@nCaseId
						and   CN1.NAMETYPE=CN.NAMETYPE))
        join  ACTIVITYREQUEST AR on (AR.CASEID = @nCaseId and AR.LETTERNO = @nLetterNo and DATEDIFF(dd,AR.WHENREQUESTED, AH.WHENREQUESTED )=0)
	left join RELATEDCASE R on (R.RELATEDCASEID=AH.CASEID
				and R.RELATIONSHIP ='RER')
        left join CASES C	on (C.CASEID       =AH.CASEID)
	left join STATUS S	on (S.STATUSCODE   =C.STATUSCODE
				and S.LIVEFLAG     =1)
	left join COUNTRY CT	on (CT.COUNTRYCODE =C.COUNTRYCODE)
	where	AH.LETTERNO   = @nLetterNo
	and	DATEDIFF(dd, AH.LETTERDATE , @dtCurrentLetterDate)=0"  


	Execute @ErrorCode=sp_executesql @sSQLString,
						N'@nCaseId		int,
						  @nLetterNo		int,
						  @dtWhenRequested	datetime,
						  @dtCurrentLetterDate	datetime',
						  @nCaseId,
						  @nLetterNo,
						  @dtWhenRequested,
						  @dtCurrentLetterDate
End

-- Now get additional information about the Cases to be renewed.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCASEDETAILS
	Set	IRN		=C.IRN,
                TITLE           =C.TITLE,
		FAMILY		=C.FAMILY,
		STEM		=C.STEM,
		OFFICIALNO	=C.CURRENTOFFICIALNO,
		CLIENTSREF	=CN.REFERENCENO,
		RENEWINSTNAMENO	=CN.NAMENO,
		COUNTRYCODE	=C.COUNTRYCODE,
		COUNTRYADJECTIVE=CT.COUNTRYADJECTIVE,
		PROPERTYTYPE	=C.PROPERTYTYPE,
		NEXTRENEWALDATE =isnull(RN.EVENTDUEDATE, RN.EVENTDATE),
                RENEWALOCCURREDFLAG = RN.OCCURREDFLAG, /* 1:+ */
		RENEWALYEAR	=datediff(yy,RS.EVENTDATE, isnull(RN.EVENTDUEDATE,RN.EVENTDATE)),
		OWNERNAMENO	=OW.NAMENO,
		OWNERNAME	=N.NAME + CASE WHEN(N.FIRSTNAME is not null) THEN ', ' + N.FIRSTNAME END,
		OFFICEID	=C.OFFICEID

	from	#TEMPCASEDETAILS T
	     join	CASES C		on (C.CASEID=T.CASEID)
	     join	CASENAME CN	on (CN.CASEID=C.CASEID
					and CN.NAMETYPE='R')
	     join	COUNTRY CT	on (CT.COUNTRYCODE=C.COUNTRYCODE)
	     join       CASEEVENT RN	on (RN.CASEID =C.CASEID		/* Get the Next Renewal date */
					and RN.EVENTNO=-11
					and RN.CYCLE  =T.CYCLE)

	     join OPENACTION OA		on (OA.CASEID =C.CASEID		/* marina: only get Next Renewal Date for cases where the Renewal Action is actually open */
					and OA.ACTION='RN'
					and OA.CYCLE  =RN.CYCLE
                                        AND POLICEEVENTS = 1)

	     join CASEEVENT RS		on (RS.CASEID=C.CASEID		/* Get the Renewal Start date */
					and RS.EVENTNO=-9
					and RS.CYCLE  =1)
	left join CASEEVENT NX		on (NX.CASEID =C.CASEID		/* Get the following Next Renewal Date */
					and NX.EVENTNO=-11
					and NX.CYCLE  =RN.CYCLE+1)
	left join CASENAME OW		on (OW.CASEID  =C.CASEID	/* Get the first Owner */
					and OW.NAMETYPE='O'
					and OW.EXPIRYDATE is null
					and OW.SEQUENCE=(Select min(OW1.SEQUENCE)
							 from CASENAME OW1
							 where OW1.CASEID  =OW.CASEID
							 and   OW1.NAMETYPE=OW.NAMETYPE
							 and   OW1.EXPIRYDATE is null))
	left join NAME N		on (N.NAMENO=OW.NAMENO)
--	left join TABLECODES TC		on (TC.TABLECODE=C.ENTITYSIZE)
"
-- Get the Entity Size
--	left join RELATEDCASE RC	on (RC.CASEID=C.CASEID
--					and RC.RELATIONSHIP='PAR'
--					and RC.RELATIONSHIPNO=(	select min(RC1.RELATIONSHIPNO)
--								from RELATEDCASE RC1
--								where RC1.CASEID=RC.CASEID
--								and   RC1.RELATIONSHIP=RC.RELATIONSHIP))

--	left join CASES C1		on (C1.CASEID=RC.RELATEDCASEID)
	Execute @ErrorCode=sp_executesql @sSQLString

End

Declare @sCountryAdjective	nvarchar(254),
	@sPropertyName		nvarchar(254),
	@sApplication		nvarchar(254), 
	@sOfficialNo		nvarchar(254),
        @sApplicationNo		nvarchar(254),
        @sNoX			nvarchar(254)

If @ErrorCode=0
Begin
	Declare CASEDETAILSCURSOR CURSOR FOR
	Select distinct IRN, CYCLE
	from #TEMPCASEDETAILS
	for read only

	Declare @IRN			nvarchar (20),
        	@casedetails		nvarchar (254),
        	@applicant		nvarchar (254),
        	@applicantTotal		nvarchar (254),
        	@OfficialNumber		nvarchar (36),
        	@nCycle			smallint,
        	@nAgeOfCase		int,
        	@pnCaseID		int

	Open CASEDETAILSCURSOR
	fetch next from CASEDETAILSCURSOR  INTO @IRN, @nCycle

	While @@FETCH_STATUS = 0 and @ErrorCode IN ( 0 ,-2, -3)
	Begin
		Select
	         	@prnDisbBillAmount	=0  ,
	         	@prnServBillAmount	=0 ,
	         	@prnTotBillDiscount	=0 ,
	         	@prnDisbTaxBillAmt	=0 ,
	         	@prnServTaxBillAmt	=0 ,
	         	@prnDisbBillDiscount 	=0 ,
	         	@prnServBillDiscount 	=0

		Select @casedetails		=null, /* initialise these variables */
			@sCountryAdjective 	=null,
			@sPropertyName 		=null,
			@sApplication		=null,
			@sOfficialNo 		=null,
			@sApplicationNo 	=null,
			@OfficialNumber 	=null

		-- if case is registered then print REGISTRATION NO
		Select  @sCountryAdjective = CASE  WHEN C.CASECATEGORY = 'X'
                                             THEN 'European ('+ COUNTRY +')'
                                             ELSE COUNTRYADJECTIVE
                                             END,
		@sPropertyName = VP.PROPERTYNAME,
		@sApplication =  null,
		@sOfficialNo= O.OFFICIALNUMBER
		from  CASES C, COUNTRY CT, VALIDPROPERTY VP, OFFICIALNUMBERS O
		where CT.COUNTRYCODE=C.COUNTRYCODE
		and   VP.COUNTRYCODE IN (C.COUNTRYCODE, 'ZZZ')
		and   VP.PROPERTYTYPE=C.PROPERTYTYPE
		and   C.IRN = @IRN
		and  C.CASEID=O.CASEID
		and   O.NUMBERTYPE IN ('R')

		If  @sOfficialNo is not null               /*  there is a registration No */
 			Select @sApplicationNo= ' ('+O.OFFICIALNUMBER+ ')'
			from  CASES C,OFFICIALNUMBERS O
			where C.IRN = @IRN
			and C.CASEID=O.CASEID
			and   O.NUMBERTYPE IN ('A')

		If  @sOfficialNo is null
			Select  @sCountryAdjective = CASE  WHEN C.CASECATEGORY = 'X'
                                             THEN 'European ('+ COUNTRY +')'
                                             ELSE COUNTRYADJECTIVE END,
			@sPropertyName = VP.PROPERTYNAME ,
			@sApplication = CASE WHEN O.NUMBERTYPE<>'R' THEN 'Application ' END,
			@sOfficialNo= O.OFFICIALNUMBER
			from CASES C,COUNTRY CT,VALIDPROPERTY VP, OFFICIALNUMBERS O
			where CT.COUNTRYCODE=C.COUNTRYCODE
			and VP.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')
			and VP.PROPERTYTYPE=C.PROPERTYTYPE
			and C.IRN = @IRN
			and C.CASEID=O.CASEID
			and O.NUMBERTYPE in ('0','A','C')

		If  @sOfficialNo is null
			Select  @sCountryAdjective = CASE WHEN C.CASECATEGORY = 'X' THEN 'European ('+ COUNTRY +')'
                                       	ELSE COUNTRYADJECTIVE END,
				@sPropertyName = VP.PROPERTYNAME,
				@sApplication = 'Application '
			from CASES C, COUNTRY CT, VALIDPROPERTY VP
			where CT.COUNTRYCODE=C.COUNTRYCODE
			and   VP.COUNTRYCODE IN (C.COUNTRYCODE, 'ZZZ')
			and   VP.PROPERTYTYPE=C.PROPERTYTYPE
			and   C.IRN = @IRN


		Select @casedetails= ISNULL(@sCountryAdjective,'') +' '+ ISNULL(@sPropertyName,'')
			+ ' ' + ISNULL(@sApplication,'') + ' '+ 'No.' + ' ' + ISNULL(@sOfficialNo,'') +
        		ISNULL(@sApplicationNo,'')

		Select @OfficialNumber =  O.OFFICIALNUMBER
		from  CASES C,OFFICIALNUMBERS O
		where C.IRN =@IRN
		and   O.CASEID=C.CASEID
		and   O.NUMBERTYPE IN ('A')
		and   exists (Select * from CASEEVENT CE where C.CASEID = CE.CASEID 
				and EVENTNO = -8 and EVENTDATE is not null)

		Select @OfficialNumber =  O.OFFICIALNUMBER
		from  CASES C,OFFICIALNUMBERS O
		where C.IRN =@IRN
		and   O.CASEID=C.CASEID
		and   O.NUMBERTYPE IN ('A')
		and   exists (Select * from CASEEVENT CE where C.CASEID = CE.CASEID 
				and EVENTNO = -8 and EVENTDATE is not null)


		Select @OfficialNumber = O.OFFICIALNUMBER
		from  CASES C,OFFICIALNUMBERS O
		where C.IRN =@IRN
		and   O.CASEID=C.CASEID
		and   O.NUMBERTYPE IN ('R')
		and   NOT exists (Select * from CASEEVENT CE where C.CASEID = CE.CASEID 
				and EVENTNO = -8 and EVENTDATE is not null)


		Declare APPLICANT_CURSOR CURSOR  FOR
			Select  CASE WHEN N.TITLE IS NOT NULL THEN N.TITLE + ' '  END
			            + CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME + ' ' END
			            + N.NAME
         		from  NAME N, CASENAME CN, CASES C
			where C.IRN     = @IRN
			and   CN.NAMETYPE  = 'O'  /*applicant*/
			and   N.NAMENO = CN.NAMENO
			and   CN.CASEID=C.CASEID
			order by SEQUENCE
		for read only

		Select @applicantTotal = null
		open APPLICANT_CURSOR
   		fetch next from APPLICANT_CURSOR INTO @applicant
		while @@FETCH_STATUS =0
		Begin
			If @applicantTotal is null
				Select  @applicantTotal = @applicant
			Else
				Select @applicantTotal = @applicantTotal + ';  '+ @applicant
			fetch next from APPLICANT_CURSOR into @applicant
		End
		Close APPLICANT_CURSOR
   		Deallocate APPLICANT_CURSOR

		/* Use the Best fit logic to determine which RateNo is being applied for a case. */
		Declare @nCriteria  int
		Select @nCriteria =
			convert(int,
			Substring ( max(
			CASE WHEN C.CASETYPE        is null THEN '0' ELSE '1' END +
			CASE WHEN C.PROPERTYTYPE    is null THEN '0' ELSE '1' END +
			CASE WHEN C.COUNTRYCODE	    is null THEN '0' ELSE '1' END +
			CASE WHEN C.CASECATEGORY    is null THEN '0' ELSE '1' END +
			CASE WHEN C.SUBTYPE	    is null THEN '0' ELSE '1' END +
			CASE WHEN C.LOCALCLIENTFLAG is null THEN '0' ELSE '1' END +
			CASE WHEN C.TYPEOFMARK      is null THEN '0' ELSE '1' END +
			CASE WHEN C.TABLECODE	    is null THEN '0' ELSE '1' END +
			isnull(convert(char(8), DATEOFACT,112),'00000000')+		/* valid from date in YYYYMMDD format */
			convert(char(11),C.CRITERIANO)),17,11))
		from  CRITERIA C  , CASES CC
		where C.RULEINUSE	= 1
		and   C.PURPOSECODE	= 'F'
		and   C.RATENO		 in (100073, 99996)
		and ( C.CASETYPE	= CC.CASETYPE		or C.CASETYPE		is null)
		and ( C.PROPERTYTYPE	= CC.PROPERTYTYPE	or C.PROPERTYTYPE	is null)
		and ( C.COUNTRYCODE	= CC.COUNTRYCODE	or C.COUNTRYCODE	is null)
		and ( C.CASECATEGORY	= CC.CASECATEGORY	or C.CASECATEGORY	is null)
		and ( C.SUBTYPE		= CC.SUBTYPE		or C.SUBTYPE		is null)
		and ( C.TYPEOFMARK	= CC.TYPEOFMARK		or C.TYPEOFMARK		is null)
	        and CC.IRN = @IRN

		Declare @rateno int
		Select @rateno = RATENO
		from CRITERIA
		where CRITERIANO = @nCriteria

	          Execute @ErrorCode =pt_GetEstimateAndSaveCall
			@IRN,
			null,
			null,
			null,
			@rateno, /* renewal fee */
			'0',
			'0',
			@psAlwayRecalculate,	/* this flag forces a new calculation to be performed when set to '1' */
			@psSaveTheEstimate,	/* this flag causes the estimate to be saved when set to '1' */
			null,
			null,
			null,
			null,
			null,
	         	@prsBillCurrency	OUTPUT ,
	         	@prnBillExchRate	OUTPUT ,
	         	@prnDisbBillAmount	OUTPUT ,
	         	@prnServBillAmount	OUTPUT ,
	         	@prnTotBillDiscount	OUTPUT ,
	         	@prnDisbTaxBillAmt	OUTPUT ,
	         	@prnServTaxBillAmt	OUTPUT ,
	         	@prnDisbBillDiscount 	OUTPUT ,
	         	@prnServBillDiscount 	OUTPUT


		If   @ErrorCode  in (0,-2, -3)  /*  NOTE: -2 means there was no matching criteria for this rateno */
		Begin
			Select @pnCaseID = CASEID , @propertytype = PROPERTYTYPE
			from CASES where IRN = @IRN

			If @propertytype not in ('T','I') /* do not show age of case for Trademark and Domain Name */
                 	Begin
				Exec @ErrorCode=pt_GetAgeOfCase @pnCaseID,
	                 			@nCycle,
		        	         	0,
         			        	@nAgeOfCase output
				Select @cAgeOfCase = convert(varchar(10),@nAgeOfCase)
			End
			Else
			Begin
				Select @cAgeOfCase = '-'
				Select @ErrorCode = 0
			End
		End

		If   @ErrorCode  IN ( 0 , -2, -3)
	       	Begin
			If datalength(LTRIM(RTRIM(@OfficialNumber))) >0
				Select @OfficialNumber = ' ('+@OfficialNumber +')'
			Else
				Select @OfficialNumber = null

			Update #TEMPCASEDETAILS
			Set COST = isnull(@prnDisbBillAmount,0)+ 
				isnull(@prnServBillAmount,0) - isnull(@prnTotBillDiscount,0) + 
				isnull(@prnServTaxBillAmt,0)+ isnull(@prnDisbTaxBillAmt,0),
			CASEDETAILS = @casedetails,
			APPLICANT   = @applicantTotal,
			AGEOFCASE   = @cAgeOfCase,
			OFFICIALNO  = ' ('+@OfficialNumber +')'
			where IRN = @IRN
	
        	        FETCH NEXT FROM CASEDETAILSCURSOR  INTO @IRN, @nCycle
		End
	End
	Close CASEDETAILSCURSOR
	Deallocate  CASEDETAILSCURSOR

	------------------------------
	-- Get the bad debtor information.  This is done as a separate Update for
	-- performance reasons
	If @ErrorCode IN (0, -2, -3)
	Begin
		Set @sSQLString="
		Update	#TEMPCASEDETAILS
		Set	DEBTORSTATUS=DS.DEBTORSTATUS
		From	#TEMPCASEDETAILS T
		join CASENAME RD		on (RD.CASEID  =T.CASEID	-- Get the first Renewal Debtor
						and RD.NAMETYPE='Z'
						and RD.EXPIRYDATE is null
						and RD.SEQUENCE=(Select min(RD1.SEQUENCE)
								 from CASENAME RD1
								 where RD1.CASEID  =RD.CASEID
								 and   RD1.NAMETYPE=RD.NAMETYPE
								 and   RD1.EXPIRYDATE is null))
		join IPNAME IP			on (IP.NAMENO=RD.NAMENO)
		join DEBTORSTATUS DS		on (DS.BADDEBTOR=IP.BADDEBTOR)"
	
	
		Execute @ErrorCode=sp_executesql @sSQLString
	
	
	End
	/* Some flexibility in the sort order of the Cases to be renewed is required.  Direct clients
	   will possibly require sorting of Cases belonging to the same Family to be done.  This can be done
	   by sorting on FAMILY, STEM then IRN.  Foreign Agents will however require Cases to be sorted by the 
	   Owner first.
	   The method I am using to determine the sort order is to check to see if the Renewal Instructor is
	   a Foreign Associate.  This could easily be changed to use some other method such as the existence
	   of a TABLEATTRIBUTE for the Renewal Instructor with a specific value. */
	
	If @ErrorCode IN (0, -2, -3)
	Begin
		Set @sSQLString="
		Select @nClientCategoryOUT=IP.CATEGORY
		from CASENAME CN
		join IPNAME IP	on (IP.NAMENO=CN.NAMENO)
		where CN.CASEID=@nCaseId
		and   CN.NAMETYPE='R'
		and   CN.EXPIRYDATE is null"
	
	
	
		Execute @ErrorCode=sp_executesql @sSQLString,
						N'@nCaseId              int,
						  @nClientCategoryOUT	int OUTPUT',
						  @nCaseId,
						  @nClientCategoryOUT=@nClientCategory OUTPUT
	
	End
	
	/* Update all ActivityHistory Rows just having been produced, in order to stop 
	duplicate letters being produced from the docgeneration when Already produced letters 
	are chosen. The problem being that for each case and each client a letter is being 
	produced */
	
	if @ErrorCode IN (0, -2, -3)
	Begin
		Print '(2) Letter No: ' + CAST(@nLetterNo as varchar(100))

		Set @sSQLString="
			Update	ACTIVITYHISTORY
			set	WHENREQUESTED = DateAdd (ms, 5, WHENREQUESTED),
				HOLDFLAG = 1
			from	ACTIVITYHISTORY AH
			join	CASENAME CN	on (CN.CASEID=AH.CASEID
						and CN.NAMETYPE='R'
						and CN.NAMENO =(select min(CN1.NAMENO)
								from CASENAME CN1
								where CN1.CASEID=@nCaseId
								and   CN1.NAMETYPE=CN.NAMETYPE))
			where AH.LETTERNO   = @nLetterNo
			and   AH.LETTERDATE = @dtCurrentLetterDate"
	
	
			Execute @ErrorCode=sp_executesql @sSQLString,
								N'@nCaseId		int,
								  @nLetterNo		int,
								  @dtCurrentLetterDate	datetime,
								  @dtOldLetterDate	datetime',
								  @nCaseId,
								  @nLetterNo,
								  @dtCurrentLetterDate,
								  @dtOldLetterDate
	End
	
	If @ErrorCode IN (0,-2, -3)
	Begin
		-- Now compare the Client Category against the Foreign Associate constant
		If @nClientCategory=@nForeignAssociate
		Begin
			Select	I.DESCRIPTION,
				T.CASEDETAILS,
				T.APPLICANT,
	                        T.TITLE,
				T.OFFICIALNO,
				convert(varchar(20),T.RENEWALTERM),
				convert(nvarchar(30),T.NEXTRENEWALDATE,112),
	                        CLIENTSREF,
	                        T.COST,
	                        T.AGEOFCASE,
	                        T.IRN,
	                        'Associate' ASSOCIATE,
	                        T.LOCALCLASSES
	
			from #TEMPCASEDETAILS T
			left join INSTRUCTIONS I on (I.INSTRUCTIONCODE=dbo.fn_StandingInstruction(T.CASEID,'R'))
	                WHERE T.NEXTRENEWALDATE is not null
	                      AND isnull(T.RENEWALOCCURREDFLAG,0) <> 1 /* 1:+ */
			order by I.DESCRIPTION, T.OWNERNAME, T.NEXTRENEWALDATE, T.FAMILY, T.STEM, T.IRN, T.REREGISTRATION
	
		End
		Else 
		Begin
			Select	I.DESCRIPTION,
				T.CASEDETAILS,
				T.APPLICANT,
	                        T.TITLE,
				T.OFFICIALNO,
				convert(varchar(20),T.RENEWALTERM),
				convert(nvarchar(30),T.NEXTRENEWALDATE, 112),
	                        CLIENTSREF,
	                        T.COST,
	                        T.AGEOFCASE,
	                        T.IRN,
	                        'Private' ASSOCIATE,
	                        T.LOCALCLASSES
	
			from #TEMPCASEDETAILS T
			left join INSTRUCTIONS I on (I.INSTRUCTIONCODE=dbo.fn_StandingInstruction(T.CASEID,'R'))
	                where T.NEXTRENEWALDATE is not null
	                      AND isnull(T.RENEWALOCCURREDFLAG,0) <> 1 /* 1:+ */
			order by I.DESCRIPTION, T.FAMILY, T.STEM, T.IRN, T.REREGISTRATION
	
		End
	End
	
	-- Commit or Rollback the transaction
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End
go

grant execute on [dbo].[pt_BulkRenewalsLetter] to public
go
