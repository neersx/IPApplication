-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_ListCandidateIRN
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_ListCandidateIRN]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_ListCandidateIRN.'
	drop procedure dbo.cpa_ListCandidateIRN
end
print '**** Creating procedure dbo.cpa_ListCandidateIRN...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_ListCandidateIRN 
		@pnPortfolioNo 		int		=null,	-- Restrict to a single portfolio entry
		@psOfficeCPACode	nvarchar(3)	=null,
		@pnReportMode 		tinyint		=0
as
-- PROCEDURE :	cpa_ListCandidateIRN
-- VERSION :	23
-- DESCRIPTION:	Returns a list of possible IRNS for a Portfolio Record with a missing or invalid IRN. 
--		If a specific Portfolio record is not identified then this procedure will update the
--		Portfolio with the IRN it is automatically proposing.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION HISTORY
-- --------------------
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Nov 2002	MF			Procedure Created
-- 11 Dec 2002	MF	8301		IRN Correction should not propose an IRN to use if existing 
--					AgentCaseCode matches on the beginning of the IRN being proposed. 
--					This is because CPA generate Cases with a suffix attached to the 
--					originating Case Code because they generate separate entries in the
--					portfolio for things like Nominal Working or Affidavit of Use.
-- 25 Mar 2003	MF	8560		Only determine a candidate IRN for Cases on the CPAPORTFOLIO that are flagged
--					as Live.
-- 16 Oct 2003	MF	9356	5	Strip out noise characters when performing a match on official numbers
--					on the CPA Portfolio 
-- 15 Mar 2004	MF	9800	6	Allow dead and transferred cases to also have their IRN corrected.
-- 05 Aug 2004	AB	8035	7	Add collate database_default to temp table definitions
-- 29 Mar 2005	MF	10481	8	An option now exists to allow the CASEID to be recorded in the CPA database
--					instead of the IRN which may exceed the 15 character CPA limit.  This change will
--					consider this Site Control and join on CASEID when appropriate.
-- 09 May 2005	MF	10731	9	Allow cases to be filtered by Office User Code.
-- 18 Jul 2005	MF	10481	10	Revisit.
-- 22 Aug 2006	MF	13283	11	Take the full range of CPA Property Types into consideration when mapping to 
--					the Inprotech standard of T, D and P.  Also remove any empty Official number
--					strings after the "noise" characters have been removed.
-- 24 Aug 2006	MF	13283	12	Revist to extend matching on property type.
-- 09 Mar 2007	MF	14545	13	Ensure that IRNs that exceed 15 characters in length are not proposed as CPA
--					cannot store IRNs over 15 characters.
-- 13 Jun 2007	AvdA	14921	14	Refine CPA Property Types used when mapping to the Inprotech standard of T, D and P.
--					Fix TP for patents renewal type Semiconductor Topography to correctly map to P.
--					Remove assumption that unknown types map to Patent.
-- 15 Jun 2007	AvdA	14931	15	Add @pnReportMode so that when this is 1, where more than one Inprotech
--					case is found to match one CPA case, this list is reported.
-- 13 Jul 2007	MF	15030	16	Performance issue introduced with  14921.  Modify join on Property Type.
-- 16 Jul 2007	MF	14960	16	No Cases being returned when "CPA USE CASEID AS CASE CODE" sitecontrol turned on.
-- 03 Mar 2008	MF	16021	17	Expand IRN matching to cater for 30 character IRNs.
-- 01 Jul 2008	AvdA	16638	18	For managing agents Case Reference will be in CLIENTCASECODE column.
-- 02 Jul 2008	AvdA	16639	19	Remove unique index on #TEMPOFFICIALNUMBERS to avoid crash if clients have multiples of same type
-- 16 Jul 2008	AvdA	16638	20	Revisit - report mode output needs to contain IRN. Also add office/account/clientref/IPRURN.
-- 30 Jul 2008	MF	16639	21	Revist 16639 to reinstate the index but as non unique
-- 11 Dec 2008	MF	17136	22	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 29 Sep 2011	AvdA 20018	23	Don't propose the same IRN for more than one CPA case.

set nocount on
set concat_null_yields_null off

-- Temporary table of the extracted data

Create table	#TEMPPROPOSEDCASE
		(	PORTFOLIONO		int		NOT NULL,
			IRN			nvarchar(30)	collate database_default NOT NULL
 		)

-- Temporaty table for storing Official Numbers that have had the noise 
-- characters stripped out of it.

Create table	#TEMPCPAPORTFOLIO
		(	PORTFOLIONO		INT		NOT NULL,
			CASECODE		nvarchar(30)	collate database_default NULL,
			COUNTRYCODE		nvarchar(3)	collate database_default NULL,
			PROPERTYTYPE		char(1)		collate database_default NULL,
			APPLICATIONNO		nvarchar(36)	collate database_default NULL,
			PUBLICATIONNO		nvarchar(36)	collate database_default NULL,
			REGISTRATIONNO		nvarchar(36)	collate database_default NULL,
			APPLICATIONDATE		datetime	NULL,
			GRANTDATE		datetime	NULL,
			EXPIRYDATE		datetime	NULL
		)

-- For performance reasons we need to create a temporary table of Official Numbers
-- if the procedure is being run for the entire CPAPORTFOLIO

Create table	#TEMPOFFICIALNUMBERS
		(	CASEID			int		NOT NULL,
			NUMBERTYPE		nchar(1)	collate database_default NOT NULL,
			OFFICIALNUMBER		nvarchar(36)	collate database_default NOT NULL
		)
 
Create INDEX XPKTEMPOFFICIALNUMBERS ON #TEMPOFFICIALNUMBERS
		(	CASEID,
			NUMBERTYPE,
			OFFICIALNUMBER
		)

-- Flag to indicate that CPA hold the CASEID instead of the IRN
declare @bCaseIdFlag		bit

declare	@ErrorCode		int
declare	@TranCountStart		int
declare	@sSQLString		nvarchar(4000)
declare @sFilter		nvarchar(100)
declare @sOfficeJoin		nvarchar(100)

-- Flag to indicate that CPA store the IRN in the CLIENTCASECODE column instead of the AGENTCASECODE
declare @bUseClientCaseCode	bit

Set	@ErrorCode	=0
Set	@TranCountStart	=0

-- SQA 10731
-- Filter on Office

If @psOfficeCPACode is not null
Begin
	Set @sFilter=char(10)+"and OFC.CPACODE=@psOfficeCPACode"

	Set @sOfficeJoin="join OFFICE OFC on (OFC.OFFICEID=C.OFFICEID)"+char(10)
End

-- Get the SiteControl to see if the CASEID is being used as an alternative to
-- the IRN as a unique identifier of the Case.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bCaseIdFlag=S.COLBOOLEAN,
	@bUseClientCaseCode=S2.COLBOOLEAN
	from SITECONTROL S
	left join SITECONTROL S2  on (S2.CONTROLID ='CPA-Use ClientCaseCode')
	where S.CONTROLID='CPA Use CaseId as Case Code'"

	exec sp_executesql @sSQLString,
				N'@bCaseIdFlag		bit	OUTPUT,
				  @bUseClientCaseCode	bit	OUTPUT',
				  @bCaseIdFlag=@bCaseIdFlag	OUTPUT,
				  @bUseClientCaseCode=@bUseClientCaseCode	OUTPUT

End

-- Load a temporary table with the Cases that are missing an IRN and strip out
-- any noise characters during the load.

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCPAPORTFOLIO(	PORTFOLIONO, CASECODE, COUNTRYCODE,PROPERTYTYPE,
					APPLICATIONNO, PUBLICATIONNO, REGISTRATIONNO,
					APPLICATIONDATE, GRANTDATE, EXPIRYDATE)
	select 	P.PORTFOLIONO,"+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "P.CLIENTCASECODE" 
					ELSE "P.AGENTCASECODE" 
					END+", CT.COUNTRYCODE,
		CASE WHEN(P.TYPECODE in ('10','15','20','82','2Y','3Y','5Y','A3','AC','AD','AG',
			'AH','AI','AO','AP','AR','AS','AU','AV','BB','BF','BS','CH','CI','CL','CP',
			'CR','CS','CT','CU','CY','DG','DO','DP','DR','DV','E4','EA','EG','EI','EK',
			'EL','EM','EN','EP','ER','ES','EU','EX','EZ','FD','FF','FN','FO','FP','GE',
			'GF','GL','GN','GP','GR','GV','GZ','HA','HE','HG','HL','HN','HP','HR','HU',
			'IO','IP','IR','IS','JA','JB','JC','JD','JP','JW','JX','JY','JZ','KM','KN',
			'KS','KT','KU','LE','LG','LI','LJ','LL','LN','LR','LS','LU','LV','LX','ML',
			'MT','N2','N8','NG','NJ','NO','NP','NS','NW','NX','NY','OE','OG','OL','OM',
			'OP','OR','P-','P#','P1','P3','PA','PB','PC','PD','PE','PF','PG','PH','PI',
			'PJ','PK','PL','PM','PN','PO','PP','PQ','PR','PS','PT','PV','PW','PX','PY',
			'PZ','QE','QL','QS','RE','RO','RP','RR','RS','RX','RY','RZ','S1','S2','S3',
			'S9','SA','SB','SC','SE','SF','SG','SH','SI','SJ','SK','SO','SP','SQ','SR',
			'SU','SV','SW','SX','SY','SZ','TD','TE','TL','TP','TY','U1','U2','U3','U4',
			'UE','UF','UG','UJ','UK','UL','UM','UN','UP','UT','UU','UV','UW','UX','UZ',
			'VA','VB','VC','VF','VP','VQ','VR','VT','VZ','WA','WG','WL','WO','WS','XC',
			'ZB','ZE','ZL','ZN','ZP','ZU','ZZ'))
					 THEN 'P'
		     WHEN(P.TYPECODE in ('1D','A9','AQ','D0','D2','D3','D4','D5','D6','D7',
			'D8','D9','DA','DB','DC','DD','DE','DH','DJ','DK','DL','DM','DN','DQ','DS',
			'DT','DW','DX','DY','DZ','FL','GA','GD','GM','GX','HD','KD','MD','MJ','OD',
			'RD','SD','SL','SM','SN','XD','Z1','Z2','Z3','Z4','ZD'))
					 THEN 'D'
		     WHEN(P.TYPECODE in ('2A','3A','4A','5A','3C','1T','2T','3T','4T','6Y',
			'A1','A2','A5','A6','AF','AL','AM','AN','AT','CE','CM','CN','CO','D1','DF',
			'DI','DU','EV','FI','FR','HT','IC','IM','IN','J5','JF','JR','L2','LC','LO',
			'MG','MP','NF','OU','OV','OX','PU','RA','RN','RT','RU','S5','SS','ST','T1',
			'T2','T3','T4','T5','T6','T7','TA','TC','TF','TI','TK','TM','TR','TS','TT',
			'TU','TX','XX','ZA'))
					 THEN 'T'
		END,
		Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(P.APPLICATIONNO,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^','')),
		Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(P.PUBLICATIONNO,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^','')),
		Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(P.REGISTRATIONNO,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^','')),
		P.APPLICATIONDATE, P.GRANTDATE, P.EXPIRYDATE
	from CPAPORTFOLIO P
	join COUNTRY CT	on (isnull(CT.ALTERNATECODE,CT.COUNTRYCODE)=P.IPCOUNTRYCODE)
	where  (P.PORTFOLIONO = @pnPortfolioNo or @pnPortfolioNo is null)
	and P.CASEID is null"	
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPortfolioNo	int',
					  @pnPortfolioNo=@pnPortfolioNo
End
-- If the entire portfolio is being processed then
-- load a temporary table with the Official Numbers after
-- stripping out the noise characters.

If  @pnPortfolioNo is null
and @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPOFFICIALNUMBERS(CASEID, NUMBERTYPE, OFFICIALNUMBER)
	select 	O.CASEID, O.NUMBERTYPE,
		Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(O.OFFICIALNUMBER,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^',''))
	from OFFICIALNUMBERS O
	join NUMBERTYPES N	on (N.NUMBERTYPE=O.NUMBERTYPE)
	join CASES C		on (C.CASEID=O.CASEID)"+char(10)+
	@sOfficeJoin+"
	left join CPAPORTFOLIO P on (P.CASEID=O.CASEID)
	where N.ISSUEDBYIPOFFICE=1
	and P.CASEID is null"+
	@sFilter

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOfficeCPACode	nvarchar(3)',
					  @psOfficeCPACode
End

-- Remove any rows where the OfficialNumber is now empty after all of the noise chararacters
-- have been removed
If @ErrorCode=0
Begin
	Set @sSQLString="delete #TEMPOFFICIALNUMBERS where OFFICIALNUMBER = '' or OFFICIALNUMBER is NULL"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Load a row for each explicit match.  The number of times that a particular Case is loaded
-- for a single entry on the Portfolio will then help determine the most likely candidate Case.
-- To be considered there must be a match on CountryCode as well as at least one other
-- characteristic.

If @ErrorCode=0
begin
	-- Match on Application Number and Country
	Set @sSQLString="
	insert into #TEMPPROPOSEDCASE (PORTFOLIONO, IRN)
	select P.PORTFOLIONO, "+ CASE WHEN(@bCaseIdFlag=1)
					THEN "cast(C.CASEID as varchar(15))"
					ELSE "C.IRN"
				 END+"
	from #TEMPCPAPORTFOLIO P
	join CASES C		on ( C.COUNTRYCODE=P.COUNTRYCODE
				and  C.CASETYPE='A'
				and (C.PROPERTYTYPE=P.PROPERTYTYPE OR (P.PROPERTYTYPE is null and C.PROPERTYTYPE not in ('D','T','P'))))"+char(10)+
	@sOfficeJoin+"
	left join CPAPORTFOLIO P1 on ("+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "P1.CLIENTCASECODE" 
					ELSE "P1.AGENTCASECODE" 
					END+"="+CASE WHEN(@bCaseIdFlag=1)
						THEN "cast(C.CASEID as varchar(15))"
						ELSE "C.IRN"
						END+")
	where "+CASE WHEN(@bUseClientCaseCode=1) 
		THEN "P1.CLIENTCASECODE" 
		ELSE "P1.AGENTCASECODE" 
		END+" is null	-- Ensure the proposed Case is not already being used.
	"+ CASE WHEN(@bCaseIdFlag=1) 
		THEN "	and ( P.CASECODE <> cast(C.CASEID as varchar(15)) OR P.CASECODE is null)"
		ELSE "	and ( P.CASECODE not like C.IRN+'%' OR P.CASECODE is null)"
	   END+"
	and EXISTS
	(select * 
	 from "+

	-- If the entire portfolio is being processed then use the previously loaded
	-- temporary table of OfficialNumbers
	CASE WHEN(@pnPortfolioNo is null) THEN "#TEMPOFFICIALNUMBERS O"
					  ELSE "OFFICIALNUMBERS O"
	END+"
	 where O.CASEID=C.CASEID
	 and O.NUMBERTYPE='A'"+

	-- If the entire portfolio is being processed then match on the saved official
	-- number that already had the noise characters stripped from it
	CASE WHEN(@pnPortfolioNo is not null) THEN "
	 and Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(O.OFFICIALNUMBER,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^',''))"
					  ELSE "
	 and O.OFFICIALNUMBER"
	END+"
	    =P.APPLICATIONNO)"+
	@sFilter

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPortfolioNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnPortfolioNo=@pnPortfolioNo,
					  @psOfficeCPACode=@psOfficeCPACode
End

If @ErrorCode=0
begin
	-- Match on Publication Number and Country
	Set @sSQLString="
	insert into #TEMPPROPOSEDCASE (PORTFOLIONO, IRN)
	select P.PORTFOLIONO, "+ CASE WHEN(@bCaseIdFlag=1)
					THEN "cast(C.CASEID as varchar(15))"
					ELSE "C.IRN"
				 END+"
	from #TEMPCPAPORTFOLIO P
	join CASES C		  on ( C.COUNTRYCODE=P.COUNTRYCODE
				  and  C.CASETYPE='A'
				  and (C.PROPERTYTYPE=P.PROPERTYTYPE OR (P.PROPERTYTYPE is null and C.PROPERTYTYPE not in ('D','T','P'))))"+char(10)+
	@sOfficeJoin+"
	left join CPAPORTFOLIO P1 on ("+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "P1.CLIENTCASECODE" 
					ELSE "P1.AGENTCASECODE" 
					END+"="+CASE WHEN(@bCaseIdFlag=1)
						THEN "cast(C.CASEID as varchar(15))"
						ELSE "C.IRN"
						END+")
	where "+CASE WHEN(@bUseClientCaseCode=1) 
		THEN "P1.CLIENTCASECODE" 
		ELSE "P1.AGENTCASECODE" 
		END+" is null	-- Ensure the proposed Case is not already being used.
	"+ CASE WHEN(@bCaseIdFlag=1) 
		THEN "	and ( P.CASECODE <> cast(C.CASEID as varchar(15)) OR P.CASECODE is null)"
		ELSE "	and ( P.CASECODE not like C.IRN+'%' OR P.CASECODE is null)"
	   END+"
	and EXISTS
	(select * 
	 from "+

	-- If the entire portfolio is being processed then use the previously loaded
	-- temporary table of OfficialNumbers
	CASE WHEN(@pnPortfolioNo is null) THEN "#TEMPOFFICIALNUMBERS O"
					  ELSE "OFFICIALNUMBERS O"
	END+"
	 where O.CASEID=C.CASEID
	 and O.NUMBERTYPE='P'"+

	-- If the entire portfolio is being processed then match on the saved official
	-- number that already had the noise characters stripped from it
	CASE WHEN(@pnPortfolioNo is not null) THEN "
	 and Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(O.OFFICIALNUMBER,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^',''))"
					  ELSE "
	 and O.OFFICIALNUMBER"
	END+"
	    =P.PUBLICATIONNO)"+
	@sFilter
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPortfolioNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnPortfolioNo=@pnPortfolioNo,
					  @psOfficeCPACode=@psOfficeCPACode
End

If @ErrorCode=0
begin
	-- Match on Registration Number and Country
	Set @sSQLString="
	insert into #TEMPPROPOSEDCASE (PORTFOLIONO, IRN)
	select P.PORTFOLIONO, "+ CASE WHEN(@bCaseIdFlag=1)
					THEN "cast(C.CASEID as varchar(15))"
					ELSE "C.IRN"
				 END+"
	from #TEMPCPAPORTFOLIO P
	join CASES C		  on ( C.COUNTRYCODE=P.COUNTRYCODE
				  and  C.CASETYPE='A'
				  and (C.PROPERTYTYPE=P.PROPERTYTYPE OR (P.PROPERTYTYPE is null and C.PROPERTYTYPE not in ('D','T','P'))))"+char(10)+
	@sOfficeJoin+"
	left join CPAPORTFOLIO P1 on ("+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "P1.CLIENTCASECODE" 
					ELSE "P1.AGENTCASECODE" 
					END+"="+CASE WHEN(@bCaseIdFlag=1)
						THEN "cast(C.CASEID as varchar(15))"
						ELSE "C.IRN"
						END+")
	where "+CASE WHEN(@bUseClientCaseCode=1) 
		THEN "P1.CLIENTCASECODE" 
		ELSE "P1.AGENTCASECODE" 
		END+" is null	-- Ensure the proposed Case is not already being used.
	"+ CASE WHEN(@bCaseIdFlag=1) 
		THEN "	and ( P.CASECODE <> cast(C.CASEID as varchar(15)) OR P.CASECODE is null)"
		ELSE "	and ( P.CASECODE not like C.IRN+'%' OR P.CASECODE is null)"
	   END+"
	and EXISTS
	(select * 
	 from "+

	-- If the entire portfolio is being processed then use the previously loaded
	-- temporary table of OfficialNumbers
	CASE WHEN(@pnPortfolioNo is null) THEN "#TEMPOFFICIALNUMBERS O"
					  ELSE "OFFICIALNUMBERS O"
	END+"
	 where O.CASEID=C.CASEID
	 and O.NUMBERTYPE in ('R','T')"+

	-- If the entire portfolio is being processed then match on the saved official
	-- number that already had the noise characters stripped from it
	CASE WHEN(@pnPortfolioNo is not null) THEN "
	 and Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(O.OFFICIALNUMBER,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^',''))"
					  ELSE "
	 and O.OFFICIALNUMBER"
	END+"
	    =P.REGISTRATIONNO)"+
	@sFilter
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPortfolioNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnPortfolioNo=@pnPortfolioNo,
					  @psOfficeCPACode=@psOfficeCPACode
End

If @ErrorCode=0
begin
	-- Match on Application Date, any Official Number and Country
	Set @sSQLString="
	insert into #TEMPPROPOSEDCASE (PORTFOLIONO, IRN)
	select P.PORTFOLIONO, "+ CASE WHEN(@bCaseIdFlag=1)
					THEN "cast(C.CASEID as varchar(15))"
					ELSE "C.IRN"
				 END+"
	from #TEMPCPAPORTFOLIO P
	join CASES C		on ( C.COUNTRYCODE=P.COUNTRYCODE
				and  C.CASETYPE='A'
				and (C.PROPERTYTYPE=P.PROPERTYTYPE OR (P.PROPERTYTYPE is null and C.PROPERTYTYPE not in ('D','T','P'))))"+char(10)+
	@sOfficeJoin+"
	join CASEEVENT CE	on (CE.CASEID=C.CASEID
				and CE.EVENTNO=-4
				and CE.EVENTDATE=P.APPLICATIONDATE)
	left join CPAPORTFOLIO P1 on ("+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "P1.CLIENTCASECODE" 
					ELSE "P1.AGENTCASECODE" 
					END+"="+CASE WHEN(@bCaseIdFlag=1)
						THEN "cast(C.CASEID as varchar(15))"
						ELSE "C.IRN"
						END+")
	where "+CASE WHEN(@bUseClientCaseCode=1) 
		THEN "P1.CLIENTCASECODE" 
		ELSE "P1.AGENTCASECODE" 
		END+" is null	-- Ensure the proposed Case is not already being used.
	"+ CASE WHEN(@bCaseIdFlag=1) 
		THEN "	and ( P.CASECODE <> cast(C.CASEID as varchar(15)) OR P.CASECODE is null)"
		ELSE "	and ( P.CASECODE not like C.IRN+'%' OR P.CASECODE is null)"
	   END+"
	and EXISTS
	(select * 
	 from "+

	-- If the entire portfolio is being processed then use the previously loaded
	-- temporary table of OfficialNumbers
	CASE WHEN(@pnPortfolioNo is null) THEN "#TEMPOFFICIALNUMBERS O"
					  ELSE "OFFICIALNUMBERS O"
	END+"
	 where O.CASEID=C.CASEID
	 and O.NUMBERTYPE='A'"+

	-- If the entire portfolio is being processed then match on the saved official
	-- number that already had the noise characters stripped from it
	CASE WHEN(@pnPortfolioNo is not null) THEN "
	 and Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(O.OFFICIALNUMBER,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^',''))"
					  ELSE "
	 and O.OFFICIALNUMBER"
	END+"
	 in (P.APPLICATIONNO,P.PUBLICATIONNO,P.REGISTRATIONNO))"+
	@sFilter
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPortfolioNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnPortfolioNo=@pnPortfolioNo,
					  @psOfficeCPACode=@psOfficeCPACode
End

If @ErrorCode=0
begin
	-- Match on Registration Date, any Official Number and Country
	Set @sSQLString="
	insert into #TEMPPROPOSEDCASE (PORTFOLIONO, IRN)
	select P.PORTFOLIONO, "+ CASE WHEN(@bCaseIdFlag=1)
					THEN "cast(C.CASEID as varchar(15))"
					ELSE "C.IRN"
				 END+"
	from #TEMPCPAPORTFOLIO P
	join CASES C		on ( C.COUNTRYCODE=P.COUNTRYCODE
				and  C.CASETYPE='A'
				and (C.PROPERTYTYPE=P.PROPERTYTYPE OR (P.PROPERTYTYPE is null and C.PROPERTYTYPE not in ('D','T','P'))))"+char(10)+
	@sOfficeJoin+"
	join CASEEVENT CE	on (CE.CASEID=C.CASEID
				and CE.EVENTNO=-8
				and CE.EVENTDATE=P.GRANTDATE)
	left join CPAPORTFOLIO P1 on ("+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "P1.CLIENTCASECODE" 
					ELSE "P1.AGENTCASECODE" 
					END+"="+CASE WHEN(@bCaseIdFlag=1)
						THEN "cast(C.CASEID as varchar(15))"
						ELSE "C.IRN"
						END+")
	where "+CASE WHEN(@bUseClientCaseCode=1) 
		THEN "P1.CLIENTCASECODE" 
		ELSE "P1.AGENTCASECODE" 
		END+" is null	-- Ensure the proposed Case is not already being used.
	"+ CASE WHEN(@bCaseIdFlag=1) 
		THEN "	and ( P.CASECODE <> cast(C.CASEID as varchar(15)) OR P.CASECODE is null)"
		ELSE "	and ( P.CASECODE not like C.IRN+'%' OR P.CASECODE is null)"
	   END+"
	and EXISTS
	(select * 
	 from "+

	-- If the entire portfolio is being processed then use the previously loaded
	-- temporary table of OfficialNumbers
	CASE WHEN(@pnPortfolioNo is null) THEN "#TEMPOFFICIALNUMBERS O"
					  ELSE "OFFICIALNUMBERS O"
	END+"
	 where O.CASEID=C.CASEID
	 and O.NUMBERTYPE='A'"+

	-- If the entire portfolio is being processed then match on the saved official
	-- number that already had the noise characters stripped from it
	CASE WHEN(@pnPortfolioNo is not null) THEN "
	 and Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(O.OFFICIALNUMBER,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^',''))"
					  ELSE "
	 and O.OFFICIALNUMBER"
	END+"
	 in (P.APPLICATIONNO,P.PUBLICATIONNO,P.REGISTRATIONNO))"+
	@sFilter
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPortfolioNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnPortfolioNo=@pnPortfolioNo,
					  @psOfficeCPACode=@psOfficeCPACode
End

If @ErrorCode=0
begin
	-- Match on Expiry Date, any Official Number and Country
	Set @sSQLString="
	insert into #TEMPPROPOSEDCASE (PORTFOLIONO, IRN)
	select P.PORTFOLIONO, "+ CASE WHEN(@bCaseIdFlag=1)
					THEN "cast(C.CASEID as varchar(15))"
					ELSE "C.IRN"
				 END+"
	from #TEMPCPAPORTFOLIO P
	join CASES C		on ( C.COUNTRYCODE=P.COUNTRYCODE
				and  C.CASETYPE='A'
				and (C.PROPERTYTYPE=P.PROPERTYTYPE OR (P.PROPERTYTYPE is null and C.PROPERTYTYPE not in ('D','T','P'))))"+char(10)+
	@sOfficeJoin+"
	join CASEEVENT CE	on (CE.CASEID=C.CASEID
				and CE.EVENTNO=-12
				and CE.EVENTDATE=P.EXPIRYDATE)
	left join CPAPORTFOLIO P1 on ("+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "P1.CLIENTCASECODE" 
					ELSE "P1.AGENTCASECODE" 
					END+"="+CASE WHEN(@bCaseIdFlag=1)
						THEN "cast(C.CASEID as varchar(15))"
						ELSE "C.IRN"
						END+")
	where "+CASE WHEN(@bUseClientCaseCode=1) 
		THEN "P1.CLIENTCASECODE" 
		ELSE "P1.AGENTCASECODE" 
		END+" is null	-- Ensure the proposed Case is not already being used.
	"+ CASE WHEN(@bCaseIdFlag=1) 
		THEN "	and ( P.CASECODE <> cast(C.CASEID as varchar(15)) OR P.CASECODE is null)"
		ELSE "	and ( P.CASECODE not like C.IRN+'%' OR P.CASECODE is null)"
	   END+"
	and EXISTS
	(select * 
	 from "+

	-- If the entire portfolio is being processed then use the previously loaded
	-- temporary table of OfficialNumbers
	CASE WHEN(@pnPortfolioNo is null) THEN "#TEMPOFFICIALNUMBERS O"
					  ELSE "OFFICIALNUMBERS O"
	END+"
	 where O.CASEID=C.CASEID
	 and O.NUMBERTYPE='A'"+

	-- If the entire portfolio is being processed then match on the saved official
	-- number that already had the noise characters stripped from it
	CASE WHEN(@pnPortfolioNo is not null) THEN "
	 and Upper(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
		(O.OFFICIALNUMBER,' ',''),'&',''),'(',''),')',''),'-',''),'+',''),':',''),';',''),char(34),''),char(39),''),',',''),'.',''),'/',''),'\',''),'^',''))"
					  ELSE "
	 and O.OFFICIALNUMBER"
	END+"
	 in (P.APPLICATIONNO,P.PUBLICATIONNO,P.REGISTRATIONNO))"+
	@sFilter
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPortfolioNo	int,
					  @psOfficeCPACode	nvarchar(3)',
					  @pnPortfolioNo=@pnPortfolioNo,
					  @psOfficeCPACode=@psOfficeCPACode
end

If @pnPortfolioNo is null
and @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Update the Portfolio with a proposed IRN where only one possible candidate IRN
	-- was found.

	Set @sSQLString="
	update CPAPORTFOLIO
	set PROPOSEDIRN=T.IRN
	from CPAPORTFOLIO CPA
	join #TEMPPROPOSEDCASE T on (T.PORTFOLIONO=CPA.PORTFOLIONO)
	where LEN(T.IRN)<=15                    -- don't propose IRN if it will be truncated (report these in report mode - 14931 below)
	and not exists							-- don't propose IRN if more than one IRN found for one CPA case (report these in report mode)
	(select * from #TEMPPROPOSEDCASE T1
	 where T1.PORTFOLIONO=CPA.PORTFOLIONO
	 and T1.IRN<>T.IRN)
	and not exists							-- SQA 20018 don't propose the same IRN for more than one CPA case (do NOT report these in report mode)
	(select * from #TEMPPROPOSEDCASE T1
	 where T1.PORTFOLIONO<>CPA.PORTFOLIONO
	 and T1.IRN=T.IRN)"

	exec @ErrorCode=sp_executesql @sSQLString

	-- Commit the transaction if it has successfully completed

	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

End

If @pnPortfolioNo is not null
Begin
	If @ErrorCode=0
	Begin
		select 	0, 
			C.IRN,
			rtrim(CASE WHEN NO.FIRSTNAME is NULL THEN NO.NAME ELSE NO.NAME+','+NO.FIRSTNAME END) as Owner,
			rtrim(CASE WHEN NI.FIRSTNAME is NULL THEN NI.NAME ELSE NI.NAME+','+NI.FIRSTNAME END) as Instructor,
			C.CURRENTOFFICIALNO
		from CASES C
		join #TEMPPROPOSEDCASE T on(T.IRN=CASE WHEN(@bCaseIdFlag=1) THEN cast(C.CASEID as varchar(15)) ELSE C.IRN END)
		left join CASENAME CI	on (CI.CASEID=C.CASEID
					and CI.NAMETYPE='I'
					and CI.EXPIRYDATE is null)
		left join NAME NI	on (NI.NAMENO=CI.NAMENO)
		left join CASENAME CO	on (CO.CASEID=C.CASEID
					and CO.NAMETYPE='O'
					and CO.EXPIRYDATE is null
					and CO.SEQUENCE=(select min(CO1.SEQUENCE)
							 from  CASENAME CO1
							 where CO1.CASEID=CO.CASEID
							 and   CO1.EXPIRYDATE is null
							 and   CO1.NAMETYPE=CO.NAMETYPE))
		left join NAME NO	on (NO.NAMENO=CO.NAMENO)
		group by C.IRN,
			rtrim(CASE WHEN NO.FIRSTNAME is NULL THEN NO.NAME ELSE NO.NAME+','+NO.FIRSTNAME END),
			rtrim(CASE WHEN NI.FIRSTNAME is NULL THEN NI.NAME ELSE NI.NAME+','+NI.FIRSTNAME END),
			C.CURRENTOFFICIALNO
		order by COUNT(*) desc
	End
	Else Begin
		Select @ErrorCode
	End
End

--14931 AvdA @pnReportMode = 1 (will list multiple inprotech cases matching one cpa case)
If @pnReportMode=1
begin
	-- Report unproposed matches.
	If  @ErrorCode=0
	begin
		Set @sSQLString="
		select distinct C.IRN, T.IRN as PROPOSEDIRN, C.CASEID,
		CPA.PORTFOLIONO, CPA.IPRURN, "+CASE WHEN(@bUseClientCaseCode=1) 
					THEN "CPA.CLIENTCASECODE" 
					ELSE "CPA.AGENTCASECODE" 
					END+", 
		case when (CPA.RESPONSIBLEPARTY='A') then 'Agent responsible'
				when (CPA.RESPONSIBLEPARTY='C') then 'Client responsible'
				else 'Unclear' end as 'RESPONSIBILITY',
		case when (CPA.STATUSINDICATOR ='L') then 'Live at CPA'
				when (CPA.STATUSINDICATOR='D') then 'Dead at CPA'
				when (CPA.STATUSINDICATOR='T') then 'Transferred'
				else 'Unclear' end as 'CPASTATUS',
		CPA.TYPECODE, CPA.TYPENAME, CPA.IPCOUNTRYCODE, 
		CPA.APPLICATIONNO, CPA.REGISTRATIONNO,
		CPA.PROPRIETOR, CPA.CLIENTNO as 'CPAACCOUNT', O.DESCRIPTION as 'OFFICE', 
		case when (patindex('%:%',CPA.CLIENTREF))>=1 
		then rtrim( substring (CPA.CLIENTREF, 1, (patindex('%:%',CPA.CLIENTREF)-1)))
		else ltrim( CPA.CLIENTREF) end as 'CLIENTREF'
		from CPAPORTFOLIO CPA
		join #TEMPPROPOSEDCASE T on (T.PORTFOLIONO=CPA.PORTFOLIONO)
		left join CASES C on "+ CASE WHEN(@bCaseIdFlag=1) 
							THEN "	(cast(C.CASEID as varchar(15))=T.IRN)"
							ELSE "	(C.IRN=T.IRN)"
							END+"
		left join OFFICE O	on (O.OFFICEID = C.OFFICEID)
		where LEN(T.IRN)> 15
		or exists
		(select * from #TEMPPROPOSEDCASE T1
		 where T1.PORTFOLIONO=CPA.PORTFOLIONO
		 and T1.IRN<>T.IRN)
		order by CPA.PORTFOLIONO, T.IRN"
	
		Exec @ErrorCode=sp_executesql @sSQLString
	end
end

Return @ErrorCode
go

grant execute on dbo.cpa_ListCandidateIRN to public
go


