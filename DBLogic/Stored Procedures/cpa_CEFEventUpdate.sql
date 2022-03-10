-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_CEFEventUpdate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_CEFEventUpdate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_CEFEventUpdate.'
	drop procedure dbo.cpa_CEFEventUpdate
end
print '**** Creating procedure dbo.cpa_CEFEventUpdate...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_CEFEventUpdate 
		@pnBatchNo 		int,			-- mandatory
		@pbPoliceCase		tinyint		=1,	-- 1=Police results
		@psOfficeCPACode	nvarchar(3)	=null,
		@pnUserIdentityId	int		= null
		
as
-- PROCEDURE :	cpa_CEFEventUpdate
-- VERSION :	23
-- DESCRIPTION:	Processes events recorded on an imported CEF file, updating/inserting corresponding 
--		Inproma events and creating policing requests if required.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16/09/2002	MF			Procedure Created
-- 09/12/2002	MF	8298		Allow the dates loaded from the CPA Composite Event File to be mapped to specific Events.
-- 08/01/2002	MF	8340		The loading of the CEF can result in a SQL duplicate key error.  
--					This occurs when more than one CEF record for the same case is loaded 
--					which results in the same Event being loaded.  The insert and updates have been
--					modified to handle this.
-- 18/02/2003	MF	8366		When updating an Event associated with a CPA Event from the Composite Event File, 
--					the cycle should be set to the lowest open cycle for the Action that the Event 
--					is defined for.
-- 17/06/2003	MF	8720		Only update the Event associated with the CPA Event if the Case is flagged as being
--					reportable to CPA.
-- 10 Sep 2003	MF	9230	6	Incorrect Event Date being updated from a CPA CEF file.
-- 02 Dec 2003	MF	9510	7	Increase the size of POLICINGSEQNO to int to cater for large number of 
--					Policing requests on an initial CPA Interface extract.
-- 28 Apr 2004	MF	9969	8	It is possible that the AGENTCASECODE will not contain the IRN of the Case
--					however in that situation the CLIENTCASECODE will have the IRN.
-- 20 May 2004	MF	9969	9	Do all of the allocation of CASEID in this stored procedure.
-- 05 Aug 2004	AB	8035	10	Add collate database_default to temp table definitions
-- 29 Mar 2005	MF	10481	11	An option now exists to allow the CASEID to be recorded in the CPA database
--					instead of the IRN which may exceed the 15 character CPA limit.  This change will
--					consider this Site Control and join on CASEID when appropriate.
-- 09 May 2005	MF	10731	12	Allow cases to be filtered by Office User Code.
-- 16 Nov 2005	vql	9704	13	When updating POLICING table insert @pnUserIdentityId.
--					Create @pnUserIdentityId also.
-- 21 Jun 2007	AvdA	14929	14	Use CLIENTCASECODE for IRN match only if CPA-CEF Use ClientCaseCode is on.
-- 30 Jul 2007	MF	15067	15	Rename the site control "CPA-CEF Use ClientCaseCode" to "CPA-Use ClientCaseCode"
--					so that it can be used more generically.
-- 11 Dec 2008	MF	17136	16	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jun 2011	MF	19686	17	CPA Event shows cases as having had a CaseEvent update which have not.
-- 05 Jul 2011	MF	RFC10944 18	Revisit SQA19686. Correction to SQL error in constructed SQL.
-- 23 Mar 2012	AvdA	20437	19	Match CEF events to cases based on previously imported PSF case match (see 19558 improved PSF matching).
-- 05 Jul 2013	vql	R13629	20	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 17 Jul 2015	AvdA	SDR-15522  21	If unmatched on IPRURN, try IRN PLUS countrycode PLUS app/reg/grant/pub which may be in REGISTRATIONNO.
-- 21 Jul 2016	MF	63331	22	Ensure time component is stripped when EVENTDATE is being updated.
-- 14 Nov 2018  AV  75198/DR-45358	23   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
set concat_null_yields_null off

-- Need a temporary POLICING table to allocate a unique sequence number.

CREATE TABLE #TEMPPOLICING (
			POLICINGSEQNO		int	identity(0,1),
			CASEID			int,
			EVENTNO			int,
			CYCLE			smallint
)

declare	@ErrorCode		int
declare @RowCount		int
declare	@TranCountStart		int
declare @bUpdateRejectList	tinyint
declare	@sSQLString		nvarchar(4000)
declare @sFilter		nvarchar(100)
declare @sOfficeJoin		nvarchar(100)

-- The event numbers mapped to the the CEF dates
declare @nCEFEventNo		int
declare @nCEFRenewalEventNo	int
declare @nCEFNextRenewalEventNo	int
declare @nCEFExpiryEventNo	int
declare @nCEFLapseEventNo	int

declare @bCaseIdFlag		bit -- Indicates that CPA hold the CASEID instead of the IRN as casecode
declare @bUseClientCaseCode	bit -- Indicates that CPA store the casecode in the CLIENTCASECODE column instead of the AGENTCASECODE
declare @sApplicationNumberType	 nvarchar(20)
declare @sRegistrationNumberType nvarchar(20)
declare @sPublicationNumberType nvarchar(20)

declare @bPortfolioExists	bit

Set	@ErrorCode	=0
Set	@TranCountStart	=0

-- SQA 10731
-- Filter on Office

If @psOfficeCPACode is not null
Begin
	Set @sFilter=char(10)+"and O.CPACODE=@psOfficeCPACode"

	Set @sOfficeJoin="join OFFICE O on (O.OFFICEID=CS.OFFICEID)"+char(10)
End

-- Get the client specific mappings from SITECONTROL for the EventNos mapped to the CEF.

If @ErrorCode=0
Begin
	set @sSQLString="
	Select	@nCEFEventNoOUT		  =S2.COLINTEGER,
		@nCEFRenewalEventNoOUT	  =S3.COLINTEGER,
		@nCEFNextRenewalEventNoOUT=S4.COLINTEGER,
		@nCEFExpiryEventNoOUT	  =S5.COLINTEGER,
		@nCEFLapseEventNoOUT	  =S6.COLINTEGER,
		@bCaseIdFlagOUT		  =S7.COLBOOLEAN,
		@bUseClientCaseCodeOUT    =S8.COLBOOLEAN,
		@sApplicationNumberType = dbo.fn_WrapQuotes(isnull(S9.COLCHARACTER,'A'),0,0), -- Intentionally not including 6 here.
		@sRegistrationNumberType = dbo.fn_WrapQuotes(isnull(S10.COLCHARACTER,'R'),0,0), -- Intentionally not including 9 here.
		@sPublicationNumberType = dbo.fn_WrapQuotes(isnull(S11.COLCHARACTER,'P'),0,0) -- Intentionally not including 7 here.
	from	  SITECONTROL S1
	left join SITECONTROL S2  on (S2.CONTROLID ='CPA-CEF Event')
	left join SITECONTROL S3  on (S3.CONTROLID ='CPA-CEF Renewal')
	left join SITECONTROL S4  on (S4.CONTROLID ='CPA-CEF Next Renewal')
	left join SITECONTROL S5  on (S5.CONTROLID ='CPA-CEF Expiry')
	left join SITECONTROL S6  on (S6.CONTROLID ='CPA-CEF Case Lapse')
	left join SITECONTROL S7  on (S7.CONTROLID ='CPA Use CaseId as Case Code')
	left join SITECONTROL S8  on (S8.CONTROLID ='CPA-Use ClientCaseCode')
	left join SITECONTROL S9 on (S9.CONTROLID='CPA Number-Application')
	left join SITECONTROL S10 on (S10.CONTROLID='CPA Number-Registration')
	left join SITECONTROL S11 on (S11.CONTROLID='CPA Number-Publication')
	where	S1.CONTROLID='CPA User Code'
	"

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@nCEFEventNoOUT		int 			OUTPUT,
					  @nCEFRenewalEventNoOUT	int 			OUTPUT,
					  @nCEFNextRenewalEventNoOUT	int 			OUTPUT,
					  @nCEFExpiryEventNoOUT		int			OUTPUT,
					  @nCEFLapseEventNoOUT		int 			OUTPUT,
					  @bCaseIdFlagOUT		bit			OUTPUT,
					  @bUseClientCaseCodeOUT	bit			OUTPUT,
					  @sApplicationNumberType	nvarchar(20)		OUTPUT,
					  @sRegistrationNumberType	nvarchar(20)		OUTPUT,
					  @sPublicationNumberType	nvarchar(20)		OUTPUT',
					  @nCEFEventNoOUT	    =@nCEFEventNo		OUTPUT,
					  @nCEFRenewalEventNoOUT    =@nCEFRenewalEventNo	OUTPUT,
					  @nCEFNextRenewalEventNoOUT=@nCEFNextRenewalEventNo	OUTPUT,
					  @nCEFExpiryEventNoOUT     =@nCEFExpiryEventNo 	OUTPUT,
					  @nCEFLapseEventNoOUT      =@nCEFLapseEventNo		OUTPUT,
					  @bCaseIdFlagOUT	    =@bCaseIdFlag		OUTPUT,
					  @bUseClientCaseCodeOUT    =@bUseClientCaseCode	OUTPUT,
					  @sApplicationNumberType   =@sApplicationNumberType	OUTPUT,
					  @sRegistrationNumberType  =@sRegistrationNumberType	OUTPUT,
					  @sPublicationNumberType   =@sPublicationNumberType	OUTPUT
End


-- SQA 20437 If data exists in CPAPORTFOLIO then match on IPRURN to collect the CASEID

Set @bPortfolioExists=0
-- Determine if there are Cases in the Portfolio already
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bPortfolioExists=1
	from CPAPORTFOLIO CPA"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bPortfolioExists	bit 		OUTPUT',
				  @bPortfolioExists=@bPortfolioExists	OUTPUT
End
-- Now find cases based on the Portfolio match if possible.
If  @ErrorCode=0
Begin
	If @bPortfolioExists =1
	Begin
		Set @sSQLString="
		Update CPAEVENT
		set CASEID=CP.CASEID
		from CPAEVENT CE
		join CPAPORTFOLIO CP on (CP.IPRURN = CE.IPRURN
					and CP.CASEID is not null)
		where CE.BATCHNO=@pnBatchNo"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		  int',
						  @pnBatchNo
	End
End
-- SDR-15522 Now try to match any cases that were not found on the portfolio 
-- SQA 14929 If Inprotech firm is known by CPA as a Managing Agent, then the IRN will be held in  
	-- the CLIENTCASECODE and their clients' codes will be in the AGENTCASECODE field (ie not to be used
	-- for matching purposes). Otherwise the IRN will be held in the AGENTCASECODE column. 
If  @ErrorCode=0
Begin
	Set @sSQLString="
	Update CPAEVENT
	set CASEID=CS.CASEID
	from CPAEVENT CPA
	join CASES CS on ("+CASE WHEN (@bUseClientCaseCode=1) THEN "CPA.CLIENTCASECODE=" ELSE "CPA.AGENTCASECODE=" END
				+CASE WHEN(@bCaseIdFlag=1) THEN "cast(CS.CASEID as varchar(15)))" ELSE "CS.IRN)" END + "
	join COUNTRY C on (C.COUNTRYCODE = CS.COUNTRYCODE  -- eliminates those where the country code does not match
				 and coalesce(C.ALTERNATECODE,C.COUNTRYCODE) = CPA.COUNTRYCODE)
	-- collect the Inprotech ApplicationNo
	left join  OFFICIALNUMBERS ONA on (ONA.CASEID = CS.CASEID 
				and ONA.NUMBERTYPE = (select min(NUMBERTYPE) from OFFICIALNUMBERS 
										where CASEID =ONA.CASEID 
										and charindex(NUMBERTYPE,@sApplicationNumberType) <>0
										and ISCURRENT = 1)
						and ONA.ISCURRENT = 1)
	-- collect the Inprotech RegistrationNo
	left join  OFFICIALNUMBERS ONR on (ONR.CASEID = CS.CASEID 
					and ONR.NUMBERTYPE = (select min(NUMBERTYPE) from OFFICIALNUMBERS 
										where CASEID =ONR.CASEID 
										and charindex(NUMBERTYPE,@sRegistrationNumberType) <>0
										and ISCURRENT = 1)
						and ONR.ISCURRENT = 1)
						
	-- collect the Inprotech PublicationNo
	left join  OFFICIALNUMBERS ONP on (ONP.CASEID = CS.CASEID 
					and ONP.NUMBERTYPE = (select min(NUMBERTYPE) from OFFICIALNUMBERS 
										where CASEID =ONP.CASEID 
										and charindex(NUMBERTYPE,@sPublicationNumberType) <>0
										and ISCURRENT = 1)
						and ONP.ISCURRENT = 1)
	-- and eliminate any where the official numbers don't roughly match at least
	where
	((nullif(ltrim(rtrim(replace(replace(replace(replace(upper(ONA.OFFICIALNUMBER),' ',''),'.',''),'-',''),',',''))),'' )
	 = nullif(ltrim(rtrim(replace(replace(replace(replace(upper(CPA.REGISTRATIONNO),' ',''),'.',''),'-',''),',',''))),'' ))
	or
	 (nullif(ltrim(rtrim(replace(replace(replace(replace(upper(ONR.OFFICIALNUMBER),' ',''),'.',''),'-',''),',',''))),'' )
	= nullif(ltrim(rtrim(replace(replace(replace(replace(upper(CPA.REGISTRATIONNO),' ',''),'.',''),'-',''),',',''))),'' ))
	or
	 (nullif(ltrim(rtrim(replace(replace(replace(replace(upper(ONP.OFFICIALNUMBER),' ',''),'.',''),'-',''),',',''))),'' )
	= nullif(ltrim(rtrim(replace(replace(replace(replace(upper(CPA.REGISTRATIONNO),' ',''),'.',''),'-',''),',',''))),'' ))
	)
	and CPA.BATCHNO=@pnBatchNo
	and CPA.CASEID is null	
	"
					  
	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@pnBatchNo		  int,
				  @sApplicationNumberType	nvarchar(20),
				  @sRegistrationNumberType	nvarchar(20),
				  @sPublicationNumberType	nvarchar(20)',
				  @pnBatchNo,
				  @sApplicationNumberType =@sApplicationNumberType,
				  @sRegistrationNumberType=@sRegistrationNumberType,
				  @sPublicationNumberType=@sPublicationNumberType
End

-- Record a temporary table row for each Case that is to be policed. This will
-- allocate a unique sequence number for insertion into the POLICING table. 
-- Do this outside of the main transaction to keep the transaction as short
-- as possible.
	
If @pbPoliceCase=1
Begin
	
	-- Insert a row to be policed for each row where the CPA Event is mapped to an InProma Event.
	-- Only do this if the Case is flagged as being reportable to CPA.

	If @ErrorCode=0
	Begin	
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO, CYCLE)"+char(10)+
		"Select distinct CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE,1)"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		"join CPAEVENTCODE EC on (EC.CPAEVENTCODE=CPA.EVENTCODE)"+char(10)+
		"join EVENTS E        on (E.EVENTNO=EC.CASEEVENTNO)"+char(10)+
		@sOfficeJoin+
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EC on (EC.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EC.EVENTNO=E.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+
		@sFilter
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @psOfficeCPACode	nvarchar(3)',
						  @pnBatchNo,
						  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFEventNo is not null
	Begin
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO, CYCLE)"+char(10)+
		"Select distinct CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE, 1)"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		"join EVENTS E        on (E.EVENTNO=@nCEFEventNo)"+char(10)+
		@sOfficeJoin+
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EC on (EC.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EC.EVENTNO=E.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.EVENTDATE is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=E.EVENTNO"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1)"+char(10)+
		" and   CE.EVENTDATE=convert(nvarchar,CPA.EVENTDATE,112))"+
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		int,
						  @nCEFEventNo		int,
						  @psOfficeCPACode	nvarchar(3)',
						  @pnBatchNo,
						  @nCEFEventNo,
						  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFRenewalEventNo is not null
	Begin
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO, CYCLE)"+char(10)+
		"Select distinct CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE,1)"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		"join EVENTS E        on (E.EVENTNO=@nCEFRenewalEventNo)"+char(10)+
		@sOfficeJoin+
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EC on (EC.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EC.EVENTNO=E.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.RENEWALEVENTDATE is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=E.EVENTNO"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1)"+char(10)+
		" and   CE.EVENTDATE=convert(nvarchar,CPA.RENEWALEVENTDATE,112))"+
		@sFilter
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		  int,
						  @nCEFRenewalEventNo	  int,
						  @psOfficeCPACode	  nvarchar(3)',
						  @pnBatchNo,
						  @nCEFRenewalEventNo,
						  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFNextRenewalEventNo is not null
	Begin
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO, CYCLE)"+char(10)+
		"Select distinct CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE,1)"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		"join EVENTS E        on (E.EVENTNO=@nCEFNextRenewalEventNo)"+char(10)+
		@sOfficeJoin+
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EC on (EC.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EC.EVENTNO=E.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.NEXTRENEWALDATE is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=E.EVENTNO"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1)"+char(10)+
		" and   CE.EVENTDATE=convert(nvarchar,CPA.NEXTRENEWALDATE,112))"+
		@sFilter
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		  int,
						  @nCEFNextRenewalEventNo int,
						  @psOfficeCPACode	  nvarchar(3)',
						  @pnBatchNo,
						  @nCEFNextRenewalEventNo,
						  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFExpiryEventNo is not null
	Begin
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO, CYCLE)"+char(10)+
		"Select distinct CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE,1)"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		"join EVENTS E        on (E.EVENTNO=@nCEFExpiryEventNo)"+char(10)+
		@sOfficeJoin+
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EC on (EC.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EC.EVENTNO=E.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.EXPIRYDATE is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=E.EVENTNO"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1)"+char(10)+
		" and   CE.EVENTDATE=convert(nvarchar,CPA.EXPIRYDATE,112))"+
		@sFilter
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		  int,
						  @nCEFExpiryEventNo	  int,
						  @psOfficeCPACode	  nvarchar(3)',
						  @pnBatchNo,
						  @nCEFExpiryEventNo,
						  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFLapseEventNo is not null
	Begin
		Set @sSQLString=
		"Insert into #TEMPPOLICING(CASEID, EVENTNO, CYCLE)"+char(10)+
		"Select distinct CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE,1)"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		"join EVENTS E        on (E.EVENTNO=@nCEFLapseEventNo)"+char(10)+
		@sOfficeJoin+
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EC on (EC.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EC.EVENTNO=E.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.CASELAPSEDATE  is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=E.EVENTNO"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1)"+char(10)+
		" and   CE.EVENTDATE=convert(nvarchar,CPA.CASELAPSEDATE,112))"+
		@sFilter
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnBatchNo		  int,
						  @nCEFLapseEventNo	  int,
						  @psOfficeCPACode	  nvarchar(3)',
						  @pnBatchNo,
						  @nCEFLapseEventNo,
						  @psOfficeCPACode
	End
End

If  @ErrorCode=0
begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	-- Insert an Event for Cases where the CPA Event has been mapped to an InProma Event
	-- and the CaseEvent does not already exist

	Set @sSQLString=
	"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA)"+char(10)+
	"select CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE,1), convert(varchar,max(CPA.EVENTDATE),112), 1, OA.ACTION, OA.CRITERIANO"+char(10)+
	"from CPAEVENT CPA"+char(10)+
	"join CASES CS             on (CS.CASEID=CPA.CASEID)"+char(10)+
	"join CPAEVENTCODE EC      on (EC.CPAEVENTCODE=CPA.EVENTCODE)"+char(10)+
	"join EVENTS E             on (E.EVENTNO=EC.CASEEVENTNO)"+char(10)+
	@sOfficeJoin+
	-- The following determines the Cycle to use by locating an OpenAction with the lowest
	-- cycle number for which the Event may be attached
	"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
	"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
	"                                           from OPENACTION OA1"+char(10)+
	"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
	"                                           where EV.EVENTNO=E.EVENTNO"+char(10)+
	"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
	"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
	"                                        from OPENACTION OA1"+char(10)+
	"                                        where OA1.CASEID=OA.CASEID"+char(10)+
	"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
	"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
	"where CPA.BATCHNO=@pnBatchNo"+char(10)+
	"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
	"and   CPA.CASEEVENTNO    is null"+char(10)+
	"and   CPA.CASEEVENTCYCLE is null"+char(10)+
	"and not exists"+char(10)+
	"(select * from CASEEVENT CE"+char(10)+
	" where CE.CASEID=CPA.CASEID"+char(10)+
	" and   CE.EVENTNO=E.EVENTNO"+char(10)+
	" and   CE.CYCLE=isnull(OA.CYCLE,1))"+
	@sFilter+char(10)+
	" group by CPA.CASEID, E.EVENTNO, isnull(OA.CYCLE,1), OA.ACTION, OA.CRITERIANO"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @psOfficeCPACode

	-- Alternatively update the CASEEVENT rows for the Event mapped to the CPA Event.

	If @ErrorCode=0
	Begin
		Set @sSQLString=
		"Update CASEEVENT"+char(10)+
		"set EVENTDATE=convert(varchar,CPA.EVENTDATE,112),"+char(10)+
		"    OCCURREDFLAG=1"+char(10)+
		"from CASEEVENT CE"+char(10)+
		"join (	select CPA.CASEID, EC.CASEEVENTNO as EVENTNO, max(CPA.EVENTDATE) as EVENTDATE"+char(10)+
		"	from CPAEVENT CPA"+char(10)+
		"	join CPAEVENTCODE EC	on (EC.CPAEVENTCODE=CPA.EVENTCODE)"+char(10)+
		"	where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"	and  CPA.CASEEVENTNO    is null"+char(10)+
		"	and  CPA.CASEEVENTCYCLE is null"+char(10)+
		"	group by CPA.CASEID, EC.CASEEVENTNO) CPA"+char(10)+
		"			on (CPA.CASEID=CE.CASEID"+char(10)+
		"			and CPA.EVENTNO=CE.EVENTNO)"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		"join EVENTS E        on (E.EVENTNO=CPA.EVENTNO)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CE.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=E.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CE.EVENTNO=E.EVENTNO"+char(10)+
		"and   CE.CYCLE  =isnull(OA.CYCLE,1)"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @psOfficeCPACode
	End
	
	-- Insert an Event for Cases where the CPA CEF dates have been mapped to an InProma Event
	-- and the CaseEvent does not already exist

	If  @ErrorCode=0
	and @nCEFEventNo is not null
	Begin
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA)"+char(10)+
		"select CPA.CASEID, @nCEFEventNo, isnull(OA.CYCLE,1), convert(varchar,max(CPA.EVENTDATE),112), 1, OA.ACTION, OA.CRITERIANO"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=@nCEFEventNo"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.EVENTDATE is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=@nCEFEventNo"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1))"+
		@sFilter+char(10)+
		" group by CPA.CASEID, isnull(OA.CYCLE,1), OA.ACTION, OA.CRITERIANO"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @nCEFEventNo		int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @nCEFEventNo,
					  @psOfficeCPACode
	End

	-- Alternatively update the CASEEVENT rows for the Event mapped to the CPA Event.

	If @ErrorCode=0
	and @nCEFEventNo is not null
	Begin
		Set @sSQLString=
		"Update CASEEVENT"+char(10)+
		"set EVENTDATE=convert(varchar,CPA.EVENTDATE,112),"+char(10)+
		"    OCCURREDFLAG=1"+char(10)+
		"from CASEEVENT CE"+char(10)+
		"join (	select CPA.CASEID, max(CPA.EVENTDATE) as EVENTDATE"+char(10)+
		"	from CPAEVENT CPA"+char(10)+
		"	where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"	and  CPA.CASEEVENTNO    is null"+char(10)+
		"	and  CPA.CASEEVENTCYCLE is null"+char(10)+
		"	and  CPA.EVENTDATE      is not null"+char(10)+
		"	group by CPA.CASEID) CPA"+char(10)+
		"		      on (CPA.CASEID=CE.CASEID)"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CE.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=CE.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CE.EVENTNO=@nCEFEventNo"+char(10)+
		"and   CE.CYCLE  =isnull(OA.CYCLE,1)"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @nCEFEventNo		int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @nCEFEventNo,
					  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFRenewalEventNo is not null
	Begin
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA)"+char(10)+
		"select CPA.CASEID, @nCEFRenewalEventNo, isnull(OA.CYCLE,1), convert(varchar,max(CPA.RENEWALEVENTDATE),112), 1, OA.ACTION, OA.CRITERIANO"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=@nCEFRenewalEventNo"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO      is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE   is null"+char(10)+
		"and   CPA.RENEWALEVENTDATE is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=@nCEFRenewalEventNo"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1))"+
		@sFilter+char(10)+
		"group by CPA.CASEID, isnull(OA.CYCLE,1), OA.ACTION, OA.CRITERIANO"
		
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		  int,
					  @nCEFRenewalEventNo	  int,
					  @psOfficeCPACode	  nvarchar(3)',
					  @pnBatchNo,
					  @nCEFRenewalEventNo,
					  @psOfficeCPACode
	End

	If @ErrorCode=0
	and @nCEFRenewalEventNo is not null
	Begin
		Set @sSQLString=
		"Update CASEEVENT"+char(10)+
		"set EVENTDATE=convert(varchar,CPA.EVENTDATE,112),"+char(10)+
		"    OCCURREDFLAG=1"+char(10)+
		"from CASEEVENT CE"+char(10)+
		"join (	select CPA.CASEID, max(CPA.RENEWALEVENTDATE) as EVENTDATE"+char(10)+
		"	from CPAEVENT CPA"+char(10)+
		"	where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"	and  CPA.CASEEVENTNO      is null"+char(10)+
		"	and  CPA.CASEEVENTCYCLE   is null"+char(10)+
		"	and  CPA.RENEWALEVENTDATE is not null"+char(10)+
		"	group by CPA.CASEID) CPA"+char(10)+
		"		      on (CPA.CASEID=CE.CASEID)"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CE.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=CE.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CE.EVENTNO=@nCEFRenewalEventNo"+char(10)+
		"and   CE.CYCLE  =isnull(OA.CYCLE,1)"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @nCEFRenewalEventNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @nCEFRenewalEventNo,
					  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFNextRenewalEventNo is not null
	Begin
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA)"+char(10)+
		"select CPA.CASEID, @nCEFNextRenewalEventNo, isnull(OA.CYCLE,1), convert(varchar,max(CPA.NEXTRENEWALDATE),112), 1, OA.ACTION, OA.CRITERIANO"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=@nCEFNextRenewalEventNo"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO     is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE  is null"+char(10)+
		"and   CPA.NEXTRENEWALDATE is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=@nCEFNextRenewalEventNo"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1))"+
		@sFilter+char(10)+
		"group by CPA.CASEID, isnull(OA.CYCLE,1), OA.ACTION, OA.CRITERIANO"
		
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		  int,
					  @nCEFNextRenewalEventNo int,
					  @psOfficeCPACode	  nvarchar(3)',
					  @pnBatchNo,
					  @nCEFNextRenewalEventNo,
					  @psOfficeCPACode
	End

	If @ErrorCode=0
	and @nCEFNextRenewalEventNo is not null
	Begin
		Set @sSQLString=
		"Update CASEEVENT"+char(10)+
		"set EVENTDATE=convert(varchar,CPA.EVENTDATE,112),"+char(10)+
		"    OCCURREDFLAG=1"+char(10)+
		"from CASEEVENT CE"+char(10)+
		"join (	select CPA.CASEID, max(CPA.NEXTRENEWALDATE) as EVENTDATE"+char(10)+
		"	from CPAEVENT CPA"+char(10)+
		"	where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"	and  CPA.CASEEVENTNO     is null"+char(10)+
		"	and  CPA.CASEEVENTCYCLE  is null"+char(10)+
		"	and  CPA.NEXTRENEWALDATE is not null"+char(10)+
		"	group by CPA.CASEID) CPA"+char(10)+
		"		      on (CPA.CASEID=CE.CASEID)"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CE.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=CE.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CE.EVENTNO=@nCEFNextRenewalEventNo"+char(10)+
		"and   CE.CYCLE  =isnull(OA.CYCLE,1)"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo			int,
					  @nCEFNextRenewalEventNo	int,
					  @psOfficeCPACode		nvarchar(3)',
					  @pnBatchNo,
					  @nCEFNextRenewalEventNo,
					  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFExpiryEventNo is not null
	Begin
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA)"+char(10)+
		"select CPA.CASEID, @nCEFExpiryEventNo, isnull(OA.CYCLE,1), convert(varchar,max(CPA.EXPIRYDATE),112), 1, OA.ACTION, OA.CRITERIANO"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=@nCEFExpiryEventNo"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.EXPIRYDATE     is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=@nCEFExpiryEventNo"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1))"+
		@sFilter+char(10)+
		"group by CPA.CASEID, isnull(OA.CYCLE,1), OA.ACTION, OA.CRITERIANO"
		
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		  int,
					  @nCEFExpiryEventNo	  int,
					  @psOfficeCPACode	  nvarchar(3)',
					  @pnBatchNo,
					  @nCEFExpiryEventNo,
					  @psOfficeCPACode
	End

	If @ErrorCode=0
	and @nCEFExpiryEventNo is not null
	Begin
		Set @sSQLString=
		"Update CASEEVENT"+char(10)+
		"set EVENTDATE=convert(varchar,CPA.EVENTDATE,112),"+char(10)+
		"    OCCURREDFLAG=1"+char(10)+
		"from CASEEVENT CE"+char(10)+
		"join (	select CPA.CASEID, max(CPA.EXPIRYDATE) as EVENTDATE"+char(10)+
		"	from CPAEVENT CPA"+char(10)+
		"	where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"	and  CPA.CASEEVENTNO    is null"+char(10)+
		"	and  CPA.CASEEVENTCYCLE is null"+char(10)+
		"	and  CPA.EXPIRYDATE     is not null"+char(10)+
		"	group by CPA.CASEID) CPA"+char(10)+
		"		      on (CPA.CASEID=CE.CASEID)"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CE.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=CE.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CE.EVENTNO=@nCEFExpiryEventNo"+char(10)+
		"and   CE.CYCLE  =isnull(OA.CYCLE,1)"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @nCEFExpiryEventNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @nCEFExpiryEventNo,
					  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFLapseEventNo is not null
	Begin
		Set @sSQLString=
		"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA)"+char(10)+
		"select CPA.CASEID, @nCEFLapseEventNo, isnull(OA.CYCLE,1), convert(varchar,max(CPA.CASELAPSEDATE),112), 1, OA.ACTION, OA.CRITERIANO"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=@nCEFLapseEventNo"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+char(10)+
		"and   CPA.CASEEVENTNO    is null"+char(10)+
		"and   CPA.CASEEVENTCYCLE is null"+char(10)+
		"and   CPA.CASELAPSEDATE  is not null"+char(10)+
		"and not exists"+char(10)+
		"(select * from CASEEVENT CE"+char(10)+
		" where CE.CASEID=CPA.CASEID"+char(10)+
		" and   CE.EVENTNO=@nCEFLapseEventNo"+char(10)+
		" and   CE.CYCLE=isnull(OA.CYCLE,1))"+
		@sFilter+char(10)+
		"group by CPA.CASEID, isnull(OA.CYCLE,1), OA.ACTION, OA.CRITERIANO"
		
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		  int,
					  @nCEFLapseEventNo	  int,
					  @psOfficeCPACode	  nvarchar(3)',
					  @pnBatchNo,
					  @nCEFLapseEventNo,
					  @psOfficeCPACode
	End

	If  @ErrorCode=0
	and @nCEFLapseEventNo is not null
	Begin
		Set @sSQLString=
		"Update CASEEVENT"+char(10)+
		"set EVENTDATE=convert(varchar,CPA.EVENTDATE,112),"+char(10)+
		"    OCCURREDFLAG=1"+char(10)+
		"from CASEEVENT CE"+char(10)+
		"join (	select CPA.CASEID, max(CPA.CASELAPSEDATE) as EVENTDATE"+char(10)+
		"	from CPAEVENT CPA"+char(10)+
		"	where CPA.BATCHNO=@pnBatchNo"+char(10)+
		"	and  CPA.CASEEVENTNO    is null"+char(10)+
		"	and  CPA.CASEEVENTCYCLE is null"+char(10)+
		"	and  CPA.CASELAPSEDATE  is not null"+char(10)+
		"	group by CPA.CASEID) CPA"+char(10)+
		"		      on (CPA.CASEID=CE.CASEID)"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CE.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=CE.EVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"where CE.EVENTNO=@nCEFLapseEventNo"+char(10)+
		"and   CE.CYCLE  =isnull(OA.CYCLE,1)"+char(10)+
		"and   CS.REPORTTOTHIRDPARTY=1"+
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @nCEFLapseEventNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @nCEFLapseEventNo,
					  @psOfficeCPACode
	End

	-- Insert a Policing request for each CASEID.  If Smart Policing is not on then insert the
	-- Policing requests with the On Hold Flag set ON. 
	
	If  @ErrorCode=0
	begin
		Set @sSQLString="
		insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
					ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		select	getdate(), T.POLICINGSEQNO, convert(varchar, getdate(),126)+convert(varchar,T.POLICINGSEQNO),1,
			CASE WHEN(S.COLBOOLEAN=1) THEN 0 ELSE 1 END,
			T.EVENTNO, T.CASEID, T.CYCLE, 3, substring(SYSTEM_USER,1,18), @pnUserIdentityId
		from #TEMPPOLICING T
		left join SITECONTROL S on (S.CONTROLID='Smart Policing')"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	 int',
					@pnUserIdentityId = @pnUserIdentityId
	end

	-- Finally update the CPAEVENT rows just updated as an audit to indicate that they have
	-- been processed.

	If @ErrorCode=0
	Begin
		Set @sSQLString=
		"Update CPAEVENT"+char(10)+
		"set CASEEVENTDATE =CE.EVENTDATE,"+char(10)+
		"    CASEEVENTNO   =CE.EVENTNO,"+char(10)+
		"    CASEEVENTCYCLE=CE.CYCLE"+char(10)+
		"from CPAEVENT CPA"+char(10)+
		"join CASES CS        on (CS.CASEID=CPA.CASEID)"+char(10)+
		@sOfficeJoin+
		"join CPAEVENTCODE EC on (EC.CPAEVENTCODE=CPA.EVENTCODE)"+char(10)+
		-- The following determines the Cycle to use by locating an OpenAction with the lowest
		-- cycle number for which the Event may be attached
		"left join OPENACTION OA   on (OA.CASEID=CPA.CASEID"+char(10)+
		"                          and OA.ACTION = (select max(OA1.ACTION)"+char(10)+
		"                                           from OPENACTION OA1"+char(10)+
		"                                           join EVENTCONTROL EV on (EV.CRITERIANO=OA1.CRITERIANO)"+char(10)+
		"                                           where EV.EVENTNO=EC.CASEEVENTNO"+char(10)+
		"                                           and OA1.CASEID=OA.CASEID)"+char(10)+
		"                          and OA.CYCLE=(select min(OA1.CYCLE)"+char(10)+
		"                                        from OPENACTION OA1"+char(10)+
		"                                        where OA1.CASEID=OA.CASEID"+char(10)+
		"                                        and   OA1.ACTION=OA.ACTION"+char(10)+
		"                                        and   OA1.POLICEEVENTS=1))"+char(10)+
		"join CASEEVENT CE    on (CE.CASEID =CPA.CASEID"+char(10)+
		"                     and CE.EVENTNO=EC.CASEEVENTNO"+char(10)+
		"                     and CE.CYCLE  =isnull(OA.CYCLE,1)"+char(10)+
		"                     and CE.OCCURREDFLAG=1)"+char(10)+
		"where CPA.CASEEVENTNO  is null"+char(10)+
		"and CPA.CASEEVENTCYCLE is null"+char(10)+
		"and CPA.BATCHNO=@pnBatchNo"+char(10)+
		"and CS.REPORTTOTHIRDPARTY=1"+	-- SQA19686
		@sFilter

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnBatchNo,
					  @psOfficeCPACode
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

select @ErrorCode

Return @ErrorCode
go
set QUOTED_IDENTIFIER off
go

grant execute on dbo.cpa_CEFEventUpdate to public
go
