-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetCaseDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetCaseDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetCaseDetails.'
	Drop procedure [dbo].[cs_GetCaseDetails]
End
Print '**** Creating Stored Procedure dbo.cs_GetCaseDetails...'
Print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_GetCaseDetails
(
	@pnCaseId			int,	
	@pbFetchDataInstructor		bit=0,
	@prdtEarliestPriorityDate 	datetime=null 		output,
	@prdtExpiryDate 		datetime=null 		output,
	@prdtFilingDate 		datetime=null 		output,
	@prdtInstructionsDate 		datetime=null 		output,
	@prdtLastEventDate 		datetime=null 		output,
	@prdtNextRenewalDate 		datetime=null 		output,
	@prdtPublicationDate 		datetime=null 		output,
	@prdtRegistrationDate 		datetime=null 		output,
	@prnYear 			int=null 		output,
	@prsAgent 			nvarchar(254)=null 	output,
	@prsCategory 			nvarchar(50)=null 	output,
	@prsCountry 			nvarchar(60)=null 	output,
	@prsEarliestPriorityCountry 	nvarchar(60)=null 	output,
	@prsEarliestPriorityNumber 	nvarchar(36)=null 	output,
	@prsFilingNumber 		nvarchar(36)=null 	output,
	@prsInstructor 			nvarchar(254)=null 	output,
	@prsLastEvent 			nvarchar(100)=null 	output,
	@prsOwners 			nvarchar(2000)=null 	output,
	@prsProperty 			nvarchar(50)=null 	output,
	@prsPublicationNumber 		nvarchar(36)=null 	output,
	@prsRegistrationNumber 		nvarchar(36)=null 	output,
	@prsRenewalStatus		nvarchar(50)=null 	output,
	@prsStatus 			nvarchar(50)=null 	output,
	@prsTitle 			nvarchar(254)=null 	output,
	@prsApplicant			nvarchar(254)=null	output,
	@prsRenewalRemarks		nvarchar(254)=null	output,	
	@prsOfficialNumbers		nvarchar(254)=null	output,
	@prdtParentFilingDate 		datetime=null 		output,
	@prdtRenewalStartDate 		datetime=null 		output,
	@prsLocation			nvarchar(80)=null 	output,
	@prsStaff			nvarchar(254)=null	output,
	@prsSignatory			nvarchar(254)=null	output,
	@prdtCPARenewalDate		datetime=null		output,
	@prsEarliestPriorityCountryCode nvarchar(3)=null	output,
	@prsBasis			nvarchar(50)=null	output,
	@prsCaseType	 		nvarchar(50)=null 	output,
	@prsDataInstructor 		nvarchar(254)=null 	output

)
as
-- PROCEDURE :	cs_GetCaseDetails
-- VERSION :	27
-- DESCRIPTION:	Returns case details to be used in Case Summary screen
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- ------------	-------	------		-------	----------------------------------------------- 
-- 08/08/2002	IB				Procedure created
-- 28/08/2002	MF				Modify code for getting earliest priority to only return 1 row
-- 29/08/2002	CR				Extended to included data needed for the Process Instructions dialog.
-- 09/09/2002	MF				To ensure consistant results in getting the earliest priority date get the
--						event held directly against the related case rather than the copied data.
-- 08/10/2002	CR				Added @prsLocation, @prsStaff and prsSignatory 
-- 24/10/2002	CR				Modified SQL used for location to improve performance
-- 30/10/2002	MF				Modified SQL used for location as there were situations where Case details
--						were not being returned if no location existed.
-- 29/05/2003	MF	8315			Improve performance on non SQLServer2000 databases by modifying how @prnYear is 
--						calculated and also standardise the extraction of the NRD by calling another procedure.
-- 15/07/2003	AT	8060			Added @prsEarliestPriorityCountryCode
-- 30/01/2004	TM	RFC846			Increase the EventDescription field to varchar(100). Increase the @prsLastEvent datasize
--						from nvarchar(50) to nvarchar(100).
-- 31 Mar 2004	MF	9853			Return the description of Basis.
-- 17 Aug 2004	MF	10383		11	Last Event should also consider the EventDate as there are likely to be 
--						multiple OpenAction rows.
-- 18 Nov 2004	MF	10682		12	Return the Earliest Priority Date from the current case if there is no Related
--						Case details available.
-- 29 Nov 2004	AB	7280		13	Increase the Renewal Notes field to 254 characters. Change @prsRenewalRemarks nvarchar(50)=null to (254).
-- 03 Jun 2005	MF	11449		14	Split up the SELECT statement that is getting the main Case Event dates into 
--						separate SELECT statements.  Some sites were experiencing poor performance on
--						the single SELECT approach because the optimiser was starting to perform an 
--						index SCAN rather than an index SEEK.
-- 12 Jan 2006	vql	11189		15	Modify the way earliest priority is retrieved.
-- 29 Sep 2006	IB	12300		16	Added @prsCaseType and @prsDataInstructor.
-- 16 Nov 2006	JP	12899		17	Display Application Number when the relationship of the case matches with the site control 'Earliest Priority'
--						otherwise display current official number.
-- 21 Dec 2006	IB	13908		18	Changed the way the @prsDataInstructor is retrieved.
-- 13 Feb 2007	AT	12899		19	Official number should display on case summary even if no earliest priority date.
-- 01 Mar 2007	PY	14425 		20 	Reserved word [year]
-- 14 Mar 2007	MF	12300		21	Revisit to split out the SELECT that retrieves @prsDataInstructor to simplify
--						and improve performance of the code.
-- 16 Mar 2007	MF	14553		22	Added an optional input parameter @pbFetchDataInstructor.  Default its value to zero.
--						Only fetch Data Instructor if the @pbFetchDataInstructor parameter is equal to one. 
-- 19 Mar 2007	MF	14553		22	Get the Data Instructor with the lowest Sequence followed by NameNo
-- 11 Aug 2008	KR	16786		23	Modified the Join to ede tables to left joins while getting data instructor	
-- 11 Dec 2008	MF	17136		24	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 21 Jul 2009	MF	17748		25	Reduce locking level to ensure other activities are not blocked.
-- 24 Jul 2009	MF	16548		25	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 17 Sep 2010	MF	RFC9777		26	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 16 Oct 2018	vql	DR-44773	27	Use function to conctenate owners list (solution by AvB).

	Set nocount on
	Set concat_null_yields_null off

	Declare @nErrorCode 		int
	Declare	@nCycle			smallint
	Declare @sSQLString		nvarchar(4000)
	Declare	@sCurrentOffNumber	nvarchar(36)
	Declare	@sConcatenatedString	nchar(80)	
	-- SQA17748 Reduce the locking level to avoid blocking other processes
	set transaction isolation level read uncommitted

	Set @nErrorCode = 0
	
	-- Get the earliest priority details from related case.
	If @nErrorCode=0
	Begin					
		-- get Earliest Priority info
		Set @sSQLString="
		Select  Top 1
			@prdtEarliestPriorityDate   = isnull(CE.EVENTDATE,RC.PRIORITYDATE), 			
			@prsEarliestPriorityNumber  = COALESCE(O.OFFICIALNUMBER, C.CURRENTOFFICIALNO , RC.OFFICIALNUMBER),
			@prsEarliestPriorityCountry = CT.COUNTRY,
			@prsEarliestPriorityCountryCode = CT.COUNTRYCODE
			
		From 
			RELATEDCASE RC
		Join
			CASERELATION CR 	on (CR.RELATIONSHIP=RC.RELATIONSHIP)
		Join
			SITECONTROL SC 		on (SC.COLCHARACTER=RC.RELATIONSHIP
						and SC.CONTROLID = 'Earliest Priority')
		Left Join
			CASES C 		on (C.CASEID = RC.RELATEDCASEID)
		Left Join
			OFFICIALNUMBERS O 	on (O.CASEID = RC.RELATEDCASEID
						and O.NUMBERTYPE = 'A'
						and O.ISCURRENT = 1)
		Left Join 
			CASEEVENT CE		on (CE.CASEID=RC.RELATEDCASEID
						and CE.EVENTNO=isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
						and CE.CYCLE=1)
		Left Join
			COUNTRY CT		on (CT.COUNTRYCODE=isnull(C.COUNTRYCODE, RC.COUNTRYCODE))
		Where
			RC.CASEID = @pnCaseId
		order by 1,2"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prdtEarliestPriorityDate	datetime     OUTPUT,
						  @prsEarliestPriorityNumber	nvarchar(36) OUTPUT,
						  @prsEarliestPriorityCountry	nvarchar(60) OUTPUT,
						  @prsEarliestPriorityCountryCode nvarchar(3) OUTPUT,
						  @pnCaseId			int',
						  @prdtEarliestPriorityDate =@prdtEarliestPriorityDate    OUTPUT,
						  @prsEarliestPriorityNumber =@prsEarliestPriorityNumber  OUTPUT,
						  @prsEarliestPriorityCountry=@prsEarliestPriorityCountry OUTPUT,
						  @prsEarliestPriorityCountryCode=@prsEarliestPriorityCountryCode OUTPUT,
						  @pnCaseId                  =@pnCaseId

						  
	End

	-- Get dates
	-- It is safe to hardcode the EventNos for Filing, Registration, Expiry, Instructions, Priority and Renewal Start
	-- however get the Publication EventNo associated with the Publication Number Type.
	-- The eventno for the parent filing date will depend on the site control 'CPA DATE-PARENT'. 
	-- Note only get the EarliestPriorityDate if it has not been retrieved from the related case.
	If @nErrorCode=0
	Begin 
		Set @sSQLString="
		select	
			@prdtFilingDate		 = FILING.EVENTDATE,
			@prdtRegistrationDate	 = REGISTRATION.EVENTDATE
		from 
			CASES C
		left join 
			CASEEVENT FILING	on (FILING.CASEID = C.CASEID
						and FILING.EVENTNO = -4)
		left join 
			CASEEVENT REGISTRATION	on (REGISTRATION.CASEID = C.CASEID
						and REGISTRATION.EVENTNO = -8)

		Where 
			C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prdtFilingDate	datetime OUTPUT,
						  @prdtRegistrationDate	datetime OUTPUT,
						  @pnCaseId		int',
						  @prdtFilingDate      =@prdtFilingDate 	OUTPUT,
						  @prdtRegistrationDate=@prdtRegistrationDate	OUTPUT,
						  @pnCaseId            =@pnCaseId
	End

	If @nErrorCode=0
	Begin 
		Set @sSQLString="
		select	
			@prdtExpiryDate		 = isnull(EXPIRY.EVENTDATE, EXPIRY.EVENTDUEDATE),
			@prdtInstructionsDate	 = INSTRUCTIONS.EVENTDATE
		from 
			CASES C
		left join 
			CASEEVENT EXPIRY	on (EXPIRY.CASEID = C.CASEID
						and EXPIRY.EVENTNO = -12)
		left join 
			CASEEVENT INSTRUCTIONS	on (INSTRUCTIONS.CASEID = C.CASEID
						and INSTRUCTIONS.EVENTNO = -16)

		Where 
			C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prdtExpiryDate	datetime OUTPUT,
						  @prdtInstructionsDate	datetime OUTPUT,
						  @pnCaseId		int',
						  @prdtExpiryDate      =@prdtExpiryDate		OUTPUT,
						  @prdtInstructionsDate=@prdtInstructionsDate	OUTPUT,
						  @pnCaseId            =@pnCaseId
	End

	If @nErrorCode=0
	Begin 
		Set @sSQLString="
		select	
			@prdtPublicationDate	 = PUBLICATION.EVENTDATE,
			@prdtParentFilingDate    = PARENTFILING.EVENTDATE
		from 
			CASES C
		     join
			NUMBERTYPES NT		on (NT.NUMBERTYPE='P')
		left join 
			CASEEVENT PUBLICATION	on (PUBLICATION.CASEID = C.CASEID
						and PUBLICATION.EVENTNO = NT.RELATEDEVENTNO)
		left join 
			SITECONTROL SCFD	on (SCFD.CONTROLID='CPA Date-Parent')
		left join 
			CASEEVENT PARENTFILING	on (PARENTFILING.CASEID = C.CASEID
						and PARENTFILING.EVENTNO = SCFD.COLINTEGER)

		Where 
			C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prdtPublicationDate	datetime OUTPUT,
					     	  @prdtParentFilingDate datetime OUTPUT,
						  @pnCaseId		int',
						  @prdtPublicationDate =@prdtPublicationDate	OUTPUT,
						  @prdtParentFilingDate = @prdtParentFilingDate OUTPUT,
						  @pnCaseId            =@pnCaseId
	End

	If @nErrorCode=0
	Begin 
		Set @sSQLString="
		select	
			@prdtRenewalStartDate    = RENEWALSTART.EVENTDATE,
			@prdtEarliestPriorityDate= isnull(@prdtEarliestPriorityDate, PRIORITY.EVENTDATE)
		from 
			CASES C
		left join 
			CASEEVENT PRIORITY	on (PRIORITY.CASEID = C.CASEID
						and PRIORITY.EVENTNO = -1)
		Left join 
			CASEEVENT RENEWALSTART	on (RENEWALSTART.CASEID = C.CASEID
						and RENEWALSTART.EVENTNO = -9)

		Where 
			C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prdtRenewalStartDate datetime OUTPUT,
						  @prdtEarliestPriorityDate datetime OUTPUT,
						  @pnCaseId		int',
						  @prdtRenewalStartDate = @prdtRenewalStartDate OUTPUT,
						  @prdtEarliestPriorityDate=@prdtEarliestPriorityDate OUTPUT,
						  @pnCaseId            =@pnCaseId
	End

	-- get Next Renewal Date by calling another stored procedure that is used
	-- elsewhere in the system.

	If @nErrorCode=0
	Begin 
		Exec @nErrorCode= dbo.cs_GetNextRenewalDate
					@pnCaseKey		=@pnCaseId,
					@pbCallFromCentura	=0,
					@pdtNextRenewalDate 	=@prdtNextRenewalDate	output,
					@pdtCPARenewalDate	=@prdtCPARenewalDate	output,
					@pnCycle		=@nCycle		output

		-- As the Case Summary screen is currently only displaying one Renewal Date from
		-- @prdtNextRenewalDate then we should substitute the CPA date if it exists.  Eventually
		-- we will change the Case program to distinguish between the two dates.

		If  @nErrorCode = 0
		and @prdtCPARenewalDate is not null
		Begin
			Set @prdtNextRenewalDate=@prdtCPARenewalDate
		End
	End


	-- get the Renewal Year - Age Of Case
	-- only do this if there is an Expiry Date as this information is meaningless for
	-- Cases that have indefinite lives.

	If  @nErrorCode=0
	and @prdtExpiryDate is not null
	Begin
		Exec @nErrorCode = 
			dbo.pt_GetAgeOfCase 
				@pnCaseId           =@pnCaseId, 
				@pnCycle            =@nCycle, 
				@pdtRenewalStartDate=@prdtRenewalStartDate,
				@pdtNextRenewalDate =@prdtNextRenewalDate,
				@pdtCPARenewalDate  =@prdtCPARenewalDate,
				@pnAgeOfCase        =@prnYear output
	end
	
	If @nErrorCode=0
	Begin
		-- get last event
		Set @sSQLString="
		Select  Top 1
			@prdtLastEventDate = C.EVENTDATE,
			@prsLastEvent	   = EC.EVENTDESCRIPTION
		From	OPENACTION O
		Join	EVENTS E	on (E.EVENTNO=O.LASTEVENT)
		Join	ACTIONS A	on (A.ACTION=O.ACTION)
		Join	CASEEVENT C	on (C.CASEID=O.CASEID
					and C.EVENTNO=O.LASTEVENT
					and C.EVENTDATE is not null
					and ((C.CYCLE =O.CYCLE AND A.NUMCYCLESALLOWED>1)
					 or  (A.NUMCYCLESALLOWED=1
						and C.CYCLE=(	select max(CYCLE)
								from CASEEVENT C1
								where C1.CASEID=C.CASEID
								and   C1.EVENTNO=C.EVENTNO
								and   C1.EVENTDATE is not null))))
		Left Join OPENACTION OA on (OA.CASEID=O.CASEID
					and OA.ACTION=E.CONTROLLINGACTION)
		Join	EVENTCONTROL EC	on (EC.CRITERIANO=isnull(OA.CRITERIANO,O.CRITERIANO)
					and EC.EVENTNO=O.LASTEVENT)
		Where O.CASEID = @pnCaseId
		Order by C.EVENTDATE DESC, O.DATEUPDATED DESC"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prdtLastEventDate	datetime     	OUTPUT,
						  @prsLastEvent		nvarchar(100) 	OUTPUT,
						  @pnCaseId		int',
						  @prdtLastEventDate=@prdtLastEventDate	OUTPUT,
						  @prsLastEvent     =@prsLastEvent	OUTPUT,
						  @pnCaseId         =@pnCaseId
	End
	
	If @nErrorCode=0
	Begin
		-- get case info
		Set @sSQLString="
		Select 
			@prsCaseType 	  = CT.CASETYPEDESC,
			@prsCategory 	  = CC.CASECATEGORYDESC,
			@prsCountry 	  = CO.COUNTRY,
			@prsProperty 	  = PT.PROPERTYNAME,
			@prsBasis	  = VB.BASISDESCRIPTION,
			@prsStatus 	  = S.INTERNALDESC,
			@prsTitle 	  = C.TITLE, 
			@prsRenewalStatus = R.INTERNALDESC,
			@prsRenewalRemarks = P.RENEWALNOTES
			
		From
			CASES C
		Join
			CASETYPE CT 		On (CT.CASETYPE = C.CASETYPE)
		Join
			COUNTRY CO 		On (CO.COUNTRYCODE = C.COUNTRYCODE)
		Join
			VALIDPROPERTY PT 	On (PT.PROPERTYTYPE = C.PROPERTYTYPE
						and PT.COUNTRYCODE = (	select min(PT1.COUNTRYCODE)
									from VALIDPROPERTY PT1
									where PT1.PROPERTYTYPE=C.PROPERTYTYPE
									and   PT1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		Left Join
			VALIDCATEGORY CC 	On (CC.CASETYPE = C.CASETYPE
						and CC.PROPERTYTYPE=C.PROPERTYTYPE
						and CC.CASECATEGORY=C.CASECATEGORY
						and CC.COUNTRYCODE =(	select min(CC1.COUNTRYCODE)
									from VALIDCATEGORY CC1
									where CC1.CASETYPE=CC.CASETYPE
									and   CC1.PROPERTYTYPE=CC.PROPERTYTYPE
									and   CC1.CASECATEGORY=CC.CASECATEGORY
									and   CC1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		Left Join
			STATUS S 		On (S.STATUSCODE = C.STATUSCODE)
		Left Join 
			PROPERTY P		On (P.CASEID=C.CASEID)
		Left Join
			STATUS R		On (R.STATUSCODE=P.RENEWALSTATUS)
		Left Join
			VALIDBASIS VB	 	On (VB.PROPERTYTYPE=C.PROPERTYTYPE
						and VB.BASIS=P.BASIS
						and VB.COUNTRYCODE =(	select min(VB1.COUNTRYCODE)
									from VALIDBASIS VB1
									where VB1.PROPERTYTYPE=VB.PROPERTYTYPE
									and   VB1.BASIS=VB.BASIS
									and   VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		
		Where   C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsCaseType		nvarchar(50)		OUTPUT,
						  @prsCategory		nvarchar(50)		OUTPUT,
						  @prsCountry		nvarchar(60)		OUTPUT,
						  @prsProperty		nvarchar(50)		OUTPUT,
						  @prsBasis		nvarchar(50)		OUTPUT,
						  @prsStatus		nvarchar(50)		OUTPUT,
						  @prsTitle		nvarchar(254)		OUTPUT,
						  @prsRenewalStatus	nvarchar(50)		OUTPUT,
						  @prsRenewalRemarks	nvarchar(50)		OUTPUT,
						  @pnCaseId		int',
						  @prsCaseType		=@prsCaseType		OUTPUT,
						  @prsCategory		=@prsCategory		OUTPUT,
						  @prsCountry     	=@prsCountry		OUTPUT,
						  @prsProperty     	=@prsProperty		OUTPUT,
						  @prsBasis		=@prsBasis		OUTPUT,
						  @prsStatus       	=@prsStatus		OUTPUT,
						  @prsTitle        	=@prsTitle		OUTPUT,
						  @prsRenewalStatus	=@prsRenewalStatus	OUTPUT,	
						  @prsRenewalRemarks	=@prsRenewalRemarks 	OUTPUT,
						  @pnCaseId        	=@pnCaseId
	End
	
	If @nErrorCode=0
	Begin
		-- get case names
		Set @sSQLString="
		Select 
			@prsInstructor    = NI.NAME+CASE WHEN NI.FIRSTNAME is not NULL THEN ', '+NI.FIRSTNAME END,
			@prsAgent         = NA.NAME+CASE WHEN NA.FIRSTNAME is not NULL THEN ', '+NA.FIRSTNAME END,
			@prsApplicant	  = NO.NAME+CASE WHEN NO.FIRSTNAME is not NULL THEN ', '+NO.FIRSTNAME END,
			@prsStaff         = NE.NAME+CASE WHEN NE.FIRSTNAME is not NULL THEN ', '+NE.FIRSTNAME END,
			@prsSignatory	  = NS.NAME+CASE WHEN NS.FIRSTNAME is not NULL THEN ', '+NS.FIRSTNAME END
			
		From
			CASES C
		Left Join
			CASENAME CI		On (CI.CASEID=C.CASEID
						and CI.NAMETYPE='I'
						and CI.SEQUENCE=(	select min(CI1.SEQUENCE)
									from CASENAME CI1
									where CI1.CASEID=CI.CASEID
									and   CI1.NAMETYPE=CI.NAMETYPE
									and  (CI1.EXPIRYDATE is NULL OR CI1.EXPIRYDATE > getdate())))
		Left Join 
			NAME NI			On (NI.NAMENO=CI.NAMENO)
		Left Join
			CASENAME CA		On (CA.CASEID=C.CASEID
						and CA.NAMETYPE='A'
						and CA.SEQUENCE=(	select min(CA1.SEQUENCE)
									from CASENAME CA1
									where CA1.CASEID=CA.CASEID
									and   CA1.NAMETYPE=CA.NAMETYPE
									and  (CA1.EXPIRYDATE is NULL OR CA1.EXPIRYDATE > getdate())))
		Left Join 
			NAME NA			On (NA.NAMENO=CA.NAMENO)
		Left Join
			CASENAME CNO		On (CNO.CASEID=C.CASEID
						and CNO.NAMETYPE='O'
						and CNO.SEQUENCE=(	select min(CNO1.SEQUENCE)
									from CASENAME CNO1
									where CNO1.CASEID=CNO.CASEID
									and   CNO1.NAMETYPE=CNO.NAMETYPE
									and  (CNO1.EXPIRYDATE is NULL OR CNO1.EXPIRYDATE > getdate())))
		Left Join 
			NAME NO			On (NO.NAMENO=CNO.NAMENO)
		Left Join
			CASENAME CNE		On (CNE.CASEID=C.CASEID
						and CNE.NAMETYPE='EMP'
						and CNE.SEQUENCE=(	select min(CNE1.SEQUENCE)
									from CASENAME CNE1
									where CNE1.CASEID=CNE.CASEID
									and   CNE1.NAMETYPE=CNE.NAMETYPE
									and  (CNE1.EXPIRYDATE is NULL OR CNE1.EXPIRYDATE > getdate())))
		Left Join 
			NAME NE			On (NE.NAMENO=CNE.NAMENO)
		Left Join
			CASENAME CNS		On (CNS.CASEID=C.CASEID
						and CNS.NAMETYPE='SIG'
						and CNS.SEQUENCE=(	select min(CNS1.SEQUENCE)
									from CASENAME CNS1
									where CNS1.CASEID=CNS.CASEID
									and   CNS1.NAMETYPE=CNS.NAMETYPE
									and  (CNS1.EXPIRYDATE is NULL OR CNS1.EXPIRYDATE > getdate())))
		Left Join 
			NAME NS			On (NS.NAMENO=CNS.NAMENO)
		
		Where   C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsInstructor	nvarchar(254)		OUTPUT,
						  @prsAgent		nvarchar(254)		OUTPUT,
						  @prsApplicant		nvarchar(254)		OUTPUT,	
						  @prsStaff		nvarchar(254)		OUTPUT,
					  	  @prsSignatory		nvarchar(254)		OUTPUT,
						  @pnCaseId		int',
						  @prsInstructor   	=@prsInstructor		OUTPUT,
						  @prsAgent        	=@prsAgent		OUTPUT,
						  @prsApplicant	   	=@prsApplicant		OUTPUT,	
						  @prsStaff		=@prsStaff		OUTPUT,
					  	  @prsSignatory		=@prsSignatory		OUTPUT,
						  @pnCaseId        	=@pnCaseId
	End
	
	If @nErrorCode=0
	and @pbFetchDataInstructor = 1
	Begin
		-- get Data Instructor
		Set @sSQLString="
		Select	@prsDataInstructor = NDI.NAME+CASE WHEN NDI.FIRSTNAME is not NULL THEN ', '+NDI.FIRSTNAME END
		From	CASES C
		Left join 	EDECASEMATCH ECM	on (ECM.DRAFTCASEID = C.CASEID)
		Left join	EDESENDERDETAILS ESD	on (ESD.BATCHNO = ECM.BATCHNO)
		Left join	EDEREQUESTTYPE ERT	on (ERT.REQUESTTYPECODE = isnull(ESD.SENDERREQUESTTYPE,'Data Input'))
		join	CASENAME CDI		On (CDI.CASEID=C.CASEID
						and CDI.NAMETYPE=ERT.REQUESTORNAMETYPE
						and CDI.NAMENO=convert(int,substring(
								(	select min(convert(char(11),CDI1.SEQUENCE)
										+  convert(char(11),CDI1.NAMENO))
									from CASENAME CDI1
									where CDI1.CASEID=CDI.CASEID
									and   CDI1.NAMETYPE=CDI.NAMETYPE
									and  (CDI1.EXPIRYDATE is NULL OR CDI1.EXPIRYDATE > getdate())),12,11))
								)
		join	NAME NDI		On (NDI.NAMENO=CDI.NAMENO)
		
		Where   C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsDataInstructor	nvarchar(254)		OUTPUT,	
						  @pnCaseId		int',
						  @prsDataInstructor   	=@prsDataInstructor	OUTPUT,	
						  @pnCaseId        	=@pnCaseId
	End
	
	If @nErrorCode=0
	Begin
		-- get case info
		Set @sSQLString="
		Select 	@prsLocation	  = TC.DESCRIPTION			
		From	CASELOCATION CL
		Join 	TABLECODES TC	On (TC.TABLECODE = CL.FILELOCATION) 
		Where   CL.WHENMOVED = (SELECT MAX(CL1.WHENMOVED)
					FROM CASELOCATION CL1
					WHERE CL1.CASEID = CL.CASEID)

		and	CL.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsLocation		nvarchar(80) 		OUTPUT,
						  @pnCaseId		int',
						  @prsLocation		=@prsLocation 		OUTPUT,
						  @pnCaseId        	=@pnCaseId
	End
	
	-- Get a concatenated list of owners
	-- SQA9853 - Code rewritten to remove multiple database accesses and WHILE loop
	If @nErrorCode=0
	Begin
		select @prsOwners=dbo.fn_GetConcatenatedNames(@pnCaseId, 'O', '; ', getdate(), null)
	End
	
	If @nErrorCode=0
	Begin					
		-- get Filing Number
		Set @sSQLString="
		Select 
			@prsFilingNumber      = OA.OFFICIALNUMBER,
			@prsPublicationNumber = OP.OFFICIALNUMBER,
			@prsRegistrationNumber= RG.OFFICIALNUMBER
		From
			CASES C
		Left Join	
			OFFICIALNUMBERS OA On (OA.CASEID = C.CASEID 
							and OA.ISCURRENT=1
							AND OA.NUMBERTYPE = 'A')
		Left Join	
			OFFICIALNUMBERS OP On (OP.CASEID = C.CASEID 
							and OP.ISCURRENT=1
							AND OP.NUMBERTYPE = 'P')
		Left Join	
			OFFICIALNUMBERS RG On (RG.CASEID = C.CASEID 
							and RG.ISCURRENT=1
							AND RG.NUMBERTYPE = 'R')
		Where
			C.CASEID = @pnCaseId"

		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsFilingNumber	 nvarchar(36)    OUTPUT,
						  @prsPublicationNumber	 nvarchar(36) 	OUTPUT,
						  @prsRegistrationNumber nvarchar(36)	OUTPUT,
						  @pnCaseId		 int',
						  @prsFilingNumber      =@prsFilingNumber	OUTPUT,
						  @prsPublicationNumber =@prsPublicationNumber	OUTPUT,
						  @prsRegistrationNumber=@prsRegistrationNumber OUTPUT,
						  @pnCaseId             =@pnCaseId
	End

	-- 7393/7634
	-- get the Official Numbers
	-- SQA9853 - Code rewritten to remove multiple database accesses and WHILE loop
	If @nErrorCode=0
	Begin
		Set @sSQLString="	
		Select @prsOfficialNumbers=isnull(nullif(@prsOfficialNumbers+char(13)+char(10),char(13)+char(10)),'')
					  +N.DESCRIPTION+':'+char(9)+O.OFFICIALNUMBER
		
		from OFFICIALNUMBERS O
		join NUMBERTYPES N 	on (N.NUMBERTYPE=O.NUMBERTYPE
					and N.ISSUEDBYIPOFFICE=1)
		where O.ISCURRENT=1
		and   O.CASEID=@pnCaseId
		Order by N.DISPLAYPRIORITY, N.NUMBERTYPE, O.DATEENTERED"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@prsOfficialNumbers	nvarchar(254)	OUTPUT,
						  @pnCaseId		int',
						  @prsOfficialNumbers=@prsOfficialNumbers	OUTPUT,
						  @pnCaseId=@pnCaseId
	End

	
	If @nErrorCode=0
	Begin				
		Select 
			@prdtEarliestPriorityDate	as EarliestPriorityDate,
			@prdtExpiryDate			as ExpiryDate,
			@prdtFilingDate			as FilingDate,
			@prdtInstructionsDate		as InstructionsDate,
			@prdtLastEventDate		as LastEventDate,
			@prdtNextRenewalDate		as NextRenewalDate,
			@prdtPublicationDate		as PublicationDate,
			@prdtRegistrationDate		as RegistrationDate,
			@prnYear			as [Year],
			@prsAgent			as Agent,
			@prsCategory			as Category,
			@prsCountry			as Country,
			@prsEarliestPriorityCountry	as EarliestPriorityCountry,
			@prsEarliestPriorityNumber	as EarliestPriorityNumber,
			@prsFilingNumber		as FilingNumber,
			@prsInstructor			as Instructor,
			@prsLastEvent			as LastEvent,
			@prsOwners			as Owners,
			@prsProperty			as Property,
			@prsPublicationNumber		as PublicationNumber,
			@prsRegistrationNumber		as RegistrationNumber,
			@prsRenewalStatus		as RenewalStatus,
			@prsStatus			as Status,
			@prsTitle			as Title,
-- 7393/7634			
			@prsApplicant			as Applicant,
			@prsRenewalRemarks		as RenewalRemarks,	
			@prsOfficialNumbers		as OfficialNumbers,
			@prdtParentFilingDate 		as ParentFilingDate,
			@prdtRenewalStartDate 		as RenewalStartDate,
			@prsLocation			as Location,
			@prsStaff			as Staff,
			@prsSignatory			as Signatory,
-- 8060
			@prsEarliestPriorityCountryCode as EarliestPriorityCountryCode,
			@prsBasis			as Basis,
			@prsCaseType			as CaseType,
			@prsDataInstructor		as DataInstructor

		Select @nErrorCode=@@ERROR
	End	
	
	Return @nErrorCode
go

grant execute on dbo.cs_GetCaseDetails to public
go
