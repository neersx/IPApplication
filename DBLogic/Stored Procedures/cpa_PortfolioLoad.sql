-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_PortfolioLoad
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_PortfolioLoad]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_PortfolioLoad.'
	drop procedure dbo.cpa_PortfolioLoad
end
print '**** Creating procedure dbo.cpa_PortfolioLoad...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_PortfolioLoad 
		@pnRowCount		int		OUTPUT,
		@psOfficeCPACode	nvarchar(3)	=null
as
-- PROCEDURE :	cpa_PortfolioLoad
-- VERSION :	19
-- DESCRIPTION:	Loads the CPAPORTFOLIO table 
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08/04/2003	MF			Procedure Created
-- 10/04/2003	MF			Correction to allow for spaces in numeric and date fields.
-- 02/06/2003	MF	8868		SQL Error when the CPALOAD table is being truncated at completion of load due
--					to insufficient security rights.  Change to a DELETE.
-- 11 Jul 2003	MF	8971		Clear out the CPAPORTFOLIO table using a DELETE before loading a new Portfolio.
-- 05 Aug 2004	AB	8035		Add collate database_default to temp table definitions
-- 30 Mar 2005	MF	10481	6	An option now exists to allow the CASEID to be recorded in the CPA database
--					instead of the IRN which may exceed the 15 character CPA limit.  This change will
--					consider this Site Control and join on CASEID when appropriate.
-- 09 May 2005	MF	10731	7	Allow cases to be filtered by Office User Code.
-- 15 Jun 2005	MF	10731	8	Revisit. Change Office User Code to Office CPA Code.
-- 18 Jul 2005	MF	10731	9	Revisit.  Make join to CASES a left join to allow invalid Cases to also be
--					loaded so they can be corrected.
-- 30 Jul 2007	MF	15067	10	The AGENTCASECODE column may not have a value as depending upon a site control
--					setting ("CPA-Use ClientCaseCode") the value could be stored in the CLIENTCASECODE.
--					Change the code to use CLIENTCASECODE instead of AGENTCASECODE if the site control
--					is set.
-- 03 Oct 2007	MF	15423	10	Do not load rows into CPAPortfolio that represent a duplicate case entry that
--					CPA created in their system to manage different aspects of the Case.
-- 26 Jun 2008	MF	16604	12	Correction to error in code extracting SiteControl for CPA-USE CLIENTCASECODE.
--					This is a revisit of SQA15067.
-- 08 Oct 2008	MF	16984	13	When Portfolio is being loaded one office at a time, we need to ensure that the newly
--					loaded records do not get loaded with a PORTFOLIONO that already exists in the
--					CPAPORTFOLIO table.
-- 11 Dec 2008	MF	17136	14	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 08 Jan 2009	AvdA	17275	15	TM1 uses '-' for 19th C dates. Accommodate this change to the Portfolio specification.
-- 29 Apr 2009	AvdA	17649	16	Revisit 17275 to cover ALL date fields rather than likely fields only. 
-- 05 Dec 2011	AvdA	19558	17	For CASEID add country code match and at least one other match to existing casecode match.
--					Perform as separate update.
-- 28 Apr 2015	MF	46996	18	Dynamic sql being truncated because variable size too small.
-- 07 Jan 2016	MF	R53541	19	Removal of some debug code "Select @sSQLString".	

set nocount on

-- Need a temporary table to allocate a unique sequence number.


 CREATE TABLE #TEMPCPAPORTFOLIO (
        PORTFOLIONO          int 		identity(1,1),
        DATEOFPORTFOLIOLST   datetime		NULL,
        CLIENTNO             int		NULL,
        CLIENTCURRENCY       nvarchar(3)	collate database_default NULL,
        IPCOUNTRYCODE        nvarchar(2)	collate database_default NULL,
        TYPECODE             nvarchar(2)	collate database_default NULL,
        TYPENAME             nvarchar(16)	collate database_default NULL,
        IPRENEWALNO          nvarchar(15)	collate database_default NULL,
        IPRURN               nvarchar(7)	collate database_default NULL,
        PARENTNO             nvarchar(15)	collate database_default NULL,
        PATENTPCTNO          nvarchar(15)	collate database_default NULL,
        FIRSTPRIORITYNO      nvarchar(15)	collate database_default NULL,
        APPLICATIONNO        nvarchar(15)	collate database_default NULL,
        PUBLICATIONNO        nvarchar(15)	collate database_default NULL,
        REGISTRATIONNO       nvarchar(15)	collate database_default NULL,
        NEXTRENEWALDATE      datetime		NULL,
        BASEDATE             datetime		NULL,
        EXPIRYDATE           datetime		NULL,
        PARENTDATE           datetime		NULL,
        PCTFILINGDATE        datetime		NULL,
        FIRSTPRIORITYDATE    datetime		NULL,
        APPLICATIONDATE      datetime		NULL,
        PUBLICATIONDATE      datetime		NULL,
        GRANTDATE            datetime		NULL,
        PROPRIETOR           nvarchar(100)	collate database_default NULL,
        CLIENTREF            nvarchar(35)	collate database_default NULL,
        CLIENTCASECODE       nvarchar(15)	collate database_default NULL,
        DIVISIONCODE         nvarchar(6)	collate database_default NULL,
        DIVISIONNAME         nvarchar(35)	collate database_default NULL,
        ANNUITY              int		NULL,
        TRADEMARKREF         nvarchar(15)	collate database_default NULL,
        AGENTCASECODE        nvarchar(15)	collate database_default NULL,
        RESPONSIBLEPARTY     nvarchar(1)	collate database_default NULL,
        LASTAMENDDATE        datetime		NULL,
        STATUSINDICATOR      nchar(1)		collate database_default NULL
 )
 
 CREATE INDEX XIE1TEMPCPAPORTFOLIO ON #TEMPCPAPORTFOLIO
 (
        AGENTCASECODE
 )
 
 CREATE INDEX XIE2TEMPCPAPORTFOLIO ON #TEMPCPAPORTFOLIO
 (
        CLIENTCASECODE
 )

declare	@ErrorCode		int
declare	@TranCountStart		int
declare @nLastPortfolioNo	int
declare	@sSQLString		nvarchar(max)
declare @sFilter		nvarchar(1000)
declare @sOfficeJoin		nvarchar(1000)

declare @bCaseIdFlag		bit
declare @bUseClientCaseCode	bit
declare @nApplicationEventNo	integer
declare @nRegistrationEventNo	integer
declare @sApplicationNumberType	 nvarchar(20)
declare @sRegistrationNumberType nvarchar(20)

Set	@ErrorCode	=0
Set	@TranCountStart	=0

-- Get the SiteControl to see if the CASEID is being used as an alternative to
-- the IRN as a unique identifier of the Case.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@bCaseIdFlag		=S.COLBOOLEAN,
			@bUseClientCaseCode	=S1.COLBOOLEAN, 
			@nApplicationEventNo	=S2.COLINTEGER,
			@nRegistrationEventNo	=S3.COLINTEGER,
			@sApplicationNumberType = dbo.fn_WrapQuotes(isnull(S4.COLCHARACTER,'A'),0,0), -- Intentionally not including 6 here.
			@sRegistrationNumberType = dbo.fn_WrapQuotes(isnull(S5.COLCHARACTER,'R'),0,0) -- Intentionally not including 9 here.
	from SITECONTROL S
	left join SITECONTROL S1 on (S1.CONTROLID='CPA-Use ClientCaseCode')
	left join SITECONTROL S2  on (S2.CONTROLID ='CPA Date-Filing')
	left join SITECONTROL S3 on (S3.CONTROLID='CPA Date-Registratn')
	left join SITECONTROL S4 on (S4.CONTROLID='CPA Number-Application')
	left join SITECONTROL S5 on (S5.CONTROLID='CPA Number-Registration')
	where S.CONTROLID='CPA Use CaseId as Case Code'"

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@bCaseIdFlag		bit			OUTPUT,
				  @bUseClientCaseCode	bit			OUTPUT,
				  @nApplicationEventNo	int 		OUTPUT,
				  @nRegistrationEventNo	int 		OUTPUT,
				  @sApplicationNumberType	nvarchar(20) 		OUTPUT,
				  @sRegistrationNumberType	nvarchar(20) 		OUTPUT',
				  @bCaseIdFlag       =@bCaseIdFlag		OUTPUT,
				  @bUseClientCaseCode=@bUseClientCaseCode	OUTPUT,
				  @nApplicationEventNo =@nApplicationEventNo	OUTPUT,
				  @nRegistrationEventNo=@nRegistrationEventNo OUTPUT,
				  @sApplicationNumberType =@sApplicationNumberType	OUTPUT,
				  @sRegistrationNumberType=@sRegistrationNumberType	OUTPUT
End

If @bUseClientCaseCode=1
Begin
	-- SQA 10731
	-- Filter on Office
	If @psOfficeCPACode is not null
	Begin
		Set @sFilter=char(10)+"Where O.CPACODE=@psOfficeCPACode"
	
		Set @sOfficeJoin=char(10)+" join CASES CS on (CPA.CLIENTCASECODE="+CASE WHEN(@bCaseIdFlag=1) THEN "cast(CS.CASEID as varchar(15)))" ELSE "CS.IRN)" END+
					char(10)+" join COUNTRY C on (C.COUNTRYCODE = CS.COUNTRYCODE"+
					char(10)+"	 and coalesce(C.ALTERNATECODE,C.COUNTRYCODE) = CPA.IPCOUNTRYCODE)" +
					char(10)+" join OFFICE O on (O.OFFICEID=CS.OFFICEID)"
	End
	--Else Begin -- 19558 clause no longer required
	--	Set @sOfficeJoin=char(10)+"	left join CASES CS on (CPA.CLIENTCASECODE="+CASE WHEN(@bCaseIdFlag=1) THEN "cast(CS.CASEID as varchar(15)))" ELSE "CS.IRN)" END
	--End
End
Else Begin
	-- SQA 10731
	-- Filter on Office
	If @psOfficeCPACode is not null
	Begin
		Set @sFilter=char(10)+"Where O.CPACODE=@psOfficeCPACode"
	
		Set @sOfficeJoin=char(10)+" join CASES CS on (CPA.AGENTCASECODE="+CASE WHEN(@bCaseIdFlag=1) THEN "cast(CS.CASEID as varchar(15)))" ELSE "CS.IRN)" END+
				 		char(10)+" join COUNTRY C on (C.COUNTRYCODE = CS.COUNTRYCODE"+
						char(10)+"	 and coalesce(C.ALTERNATECODE,C.COUNTRYCODE) = CPA.IPCOUNTRYCODE)" +
						char(10)+" join OFFICE O on (O.OFFICEID=CS.OFFICEID)"
	End
	--Else Begin -- 19558 clause no longer required
	--	Set @sOfficeJoin=char(10)+"	left join CASES CS on (CPA.AGENTCASECODE="+CASE WHEN(@bCaseIdFlag=1) THEN "cast(CS.CASEID as varchar(15)))" ELSE "CS.IRN)" END
	--End
End

-- Check that there is data in the CPALOAD table otherwise terminate
-- with error code -1

If (select count(*) from CPALOAD) = 0
Begin
	Set @ErrorCode=-1
	Set @pnRowCount=0
End

If @ErrorCode=0
Begin
	Exec("
	insert into #TEMPCPAPORTFOLIO(
		DATEOFPORTFOLIOLST,CLIENTNO,CLIENTCURRENCY,IPCOUNTRYCODE,TYPECODE,TYPENAME,IPRENEWALNO,IPRURN,PARENTNO,
		PATENTPCTNO,FIRSTPRIORITYNO,APPLICATIONNO,PUBLICATIONNO,REGISTRATIONNO,NEXTRENEWALDATE,BASEDATE,
		EXPIRYDATE,PARENTDATE,PCTFILINGDATE,FIRSTPRIORITYDATE,APPLICATIONDATE,PUBLICATIONDATE,GRANTDATE,
		PROPRIETOR,CLIENTREF,CLIENTCASECODE,DIVISIONCODE,DIVISIONNAME,ANNUITY,TRADEMARKREF,AGENTCASECODE,
		RESPONSIBLEPARTY,LASTAMENDDATE,STATUSINDICATOR)
	select
	Case When(         substring(DATASTRING,  1,7) <>'0000000' 
	     and isnumeric(substring(DATASTRING,  1,7))=1 )
	   then convert(datetime, convert(varchar(12), substring(DATASTRING,  1,7) + 19000000))	--DATEOFPORTFOLIOLST
	End,
	Case When (substring(DATASTRING,  8,7) not in (' '))
	   then convert(int,                           substring(DATASTRING,  8,7))		--CLIENTNO
	End,
		                           rtrim(ltrim(substring(DATASTRING, 15,3))),		--CLIENTCURRENCY
                                           rtrim(ltrim(substring(DATASTRING, 18,2))),		--IPCOUNTRYCODE
                                           rtrim(ltrim(substring(DATASTRING, 20,2))),
                                           rtrim(ltrim(substring(DATASTRING, 22,16))),		--TYPENAME
                                           rtrim(ltrim(substring(DATASTRING, 38,15))),		--IPRENEWALNO
                                           rtrim(ltrim(substring(DATASTRING, 53,7))),		--IPRURN
                                           rtrim(ltrim(substring(DATASTRING, 60,15))),		--PARENTNO
                                           rtrim(ltrim(substring(DATASTRING, 75,15))),		--PATENTPCTNO
                                           rtrim(ltrim(substring(DATASTRING, 90,15))),		--FIRSTPRIORITYNO
                                           rtrim(ltrim(substring(DATASTRING,105,15))),		--APPLICATIONNO
                                           rtrim(ltrim(substring(DATASTRING,120,15))),		--PUBLICATIONNO
                                           rtrim(ltrim(substring(DATASTRING,135,15))),		--REGISTRATIONNO

-- SQA 17275/17649 handle 19th C for ALL dates
-- Portfolio date format Xyymmdd where X may be '1' for century 20, '0':19, '-':18

	case when( substring(DATASTRING,150,7) <>'0000000'
			and isnumeric(substring(DATASTRING,150,7))=1) 
	then	case when (substring(DATASTRING,150,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,151,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,150,7) + 19000000))--NEXTRENEWALDATE
			end	
	end,
	case when( substring(DATASTRING,157,7) <>'0000000'
			and isnumeric(substring(DATASTRING,157,7))=1) 
	then	case when (substring(DATASTRING,157,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,158,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,157,7) + 19000000))--BASEDATE
			end	
	end,
	case when( substring(DATASTRING,164,7) <>'0000000'
			and isnumeric(substring(DATASTRING,164,7))=1) 
	then	case when (substring(DATASTRING,164,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,165,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,164,7) + 19000000))--EXPIRYDATE
			end	
	end,
	case when( substring(DATASTRING,171,7) <>'0000000'
			and isnumeric(substring(DATASTRING,171,7))=1) 
	then	case when (substring(DATASTRING,171,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,172,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,171,7) + 19000000)) --Parent Application Date / Parent Registration Date
			end	
	end,
	case when( substring(DATASTRING,178,7) <>'0000000'
			and isnumeric(substring(DATASTRING,178,7))=1) 
	then	case when (substring(DATASTRING,178,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,179,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,178,7) + 19000000)) --PCT Filing Date /Registration Date
			end	
	end,
	case when( substring(DATASTRING,185,7) <>'0000000'
			and isnumeric(substring(DATASTRING,185,7))=1) 
	then	case when (substring(DATASTRING,185,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,186,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,185,7) + 19000000))--FIRSTPRIORITYDATE
			end	
	end,
	case when( substring(DATASTRING,192,7) <>'0000000'
			and isnumeric(substring(DATASTRING,192,7))=1) 
	then	case when (substring(DATASTRING,192,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,193,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,192,7) + 19000000))--APPLICATIONDATE
			end	
	end,
	case when( substring(DATASTRING,199,7) <>'0000000'
			and isnumeric(substring(DATASTRING,199,7))=1) 
	then	case when (substring(DATASTRING,199,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,200,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,199,7) + 19000000)) 	--Patent/Design Publication Date
			end	
	end,
	case when( substring(DATASTRING,206,7) <>'0000000'
			and isnumeric(substring(DATASTRING,206,7))=1) 
	then	case when (substring(DATASTRING,206,7) < 0) 
			then convert(datetime, convert(varchar(12), substring(DATASTRING,207,6) + 18000000))
			else convert(datetime, convert(varchar(12), substring(DATASTRING,206,7) + 19000000)) --Grant Date/Next Renewal Date
			end	
	end,
                                           rtrim(ltrim(substring(DATASTRING,213,100))),		--PROPRIETOR
                                           rtrim(ltrim(substring(DATASTRING,313,35))),		--CLIENTREF
                                           rtrim(ltrim(substring(DATASTRING,348,15))),		--CLIENTCASECODE
                                           rtrim(ltrim(substring(DATASTRING,363,6))),		--DIVISIONCODE
                                           rtrim(ltrim(substring(DATASTRING,369,35))),		--DIVISIONNAME
	Case When(substring(DATASTRING,404,2) not in (' '))
	   then convert(int,                           substring(DATASTRING,404,2))		--ANNUITY
	End,
                                           rtrim(ltrim(substring(DATASTRING,406,15))),		--TRADEMARKREF
                                           rtrim(ltrim(substring(DATASTRING,421,15))),		--AGENTCASECODE
                --                                     substring(DATASTRING,436,5),  		--Unused
                                           rtrim(ltrim(substring(DATASTRING,441,1))),		--RESPONSIBLEPARTY
	Case When(         substring(DATASTRING,442,7) <>'0000000' 
	     and isnumeric(substring(DATASTRING,442,7))=1 )
	   then convert(datetime, convert(varchar(12), substring(DATASTRING,442,7) + 19000000))	--LASTAMENDDATE
	End,
                                                       substring(DATASTRING,449,1)		--STATUSINDICATOR
	from CPALOAD")

	set @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	-- Delete the Portfolio records loaded into the temporary table that represent
	-- a second Case record that CPA have loaded to manage different aspects of
	-- the Case.
	-- Note : The following statement was provided by CPA 
	Set @sSQLString="
		delete
		from #TEMPCPAPORTFOLIO
		where (	
		--Trademark 2nd entries
			( IPCOUNTRYCODE = 'KH' and (TYPECODE = 'AF' or TYPECODE = 'A6'))
		or 	( IPCOUNTRYCODE = 'KY' and (TYPECODE = 'AN'))
		or	( IPCOUNTRYCODE = 'ET' and (TYPECODE = 'CN'))
		or 	( IPCOUNTRYCODE = 'HT' and (TYPECODE = 'AF'))
		or 	( IPCOUNTRYCODE = 'HN' and (TYPECODE = 'AN' or TYPECODE = 'RT'))
		--or 	( IPCOUNTRYCODE = 'WO' and (TYPECODE = 'IN' or TYPECODE = 'IM' or TYPECODE = 'IC')) 
		or 	( IPCOUNTRYCODE = 'MZ' and (TYPECODE = 'DI' or TYPECODE = 'DU'))
		or 	( IPCOUNTRYCODE = 'PH' and (TYPECODE = 'AF' or TYPECODE = 'A6' or TYPECODE = 'A1'))
		or 	( IPCOUNTRYCODE = 'PT' and (TYPECODE = 'DI' or TYPECODE = 'DU'))
		or 	( IPCOUNTRYCODE = 'SV' and (TYPECODE = 'TX'))
		or 	( IPCOUNTRYCODE = 'ES' and (TYPECODE = 'OU' or TYPECODE = 'OV'))
		or 	( IPCOUNTRYCODE = 'US' and (TYPECODE = 'AF' or TYPECODE = 'A6' or TYPECODE = 'AA' or TYPECODE = 'AB'))
		or 	( IPCOUNTRYCODE = 'HN' and (TYPECODE = 'A2'))
		or 	( IPCOUNTRYCODE = 'PH' and (TYPECODE = 'A1'))
		or 	( IPCOUNTRYCODE = 'AL' and (TYPECODE = 'T1' or TYPECODE = 'T2'))
		or 	( IPCOUNTRYCODE = 'MO' and (TYPECODE = 'DI'))
		or 	( IPCOUNTRYCODE = 'MX' and (TYPECODE = 'DI'))
		or 	( IPCOUNTRYCODE = 'PA' and (TYPECODE = 'T1' or TYPECODE = 'T4' or TYPECODE = 'T5' or TYPECODE = 'T7' or TYPECODE = 'TF'))
		or 	( IPCOUNTRYCODE = 'PR' and (TYPECODE = 'AF')
		-- Patent and Design 2nd entries
		or	( IPCOUNTRYCODE = 'AU' and (TYPECODE = 'DE'))
		or 	( IPCOUNTRYCODE = 'BR' and (TYPECODE = 'NW' or TYPECODE = 'NJ' or TYPECODE = 'NO' or TYPECODE = 'NL'))
		or 	( IPCOUNTRYCODE = 'EC' and (TYPECODE = 'NO'))
		or 	( IPCOUNTRYCODE = 'ET' and (TYPECODE = 'NW' or TYPECODE = 'SW'))
		or 	( IPCOUNTRYCODE = 'GH' and (TYPECODE = 'NW' or TYPECODE = 'SW'))
		or 	( IPCOUNTRYCODE = 'GB' and (TYPECODE = 'GL' or TYPECODE = 'GF'))
		or 	( IPCOUNTRYCODE = 'IR' and (TYPECODE = 'NO' or TYPECODE = 'NW'))
		or 	( IPCOUNTRYCODE = 'JO' and (TYPECODE = 'NW'))
		or 	( IPCOUNTRYCODE = 'LB' and (TYPECODE = 'NW'))
		or 	( IPCOUNTRYCODE = 'MY' and (TYPECODE = 'A3'))
		or 	( IPCOUNTRYCODE = 'MA' and (TYPECODE = 'NW' or TYPECODE = 'SW'))
		or 	( IPCOUNTRYCODE = 'NZ' and (TYPECODE = 'GL'))
		or 	( IPCOUNTRYCODE = 'SY' and (TYPECODE = 'NW'))
		or 	( IPCOUNTRYCODE = 'TN' and (TYPECODE = 'SW' or TYPECODE = 'NO' or TYPECODE = 'NW' or TYPECODE = 'S3' ))
		or 	( IPCOUNTRYCODE = 'UY' and (TYPECODE = 'RF'))
		or 	( IPCOUNTRYCODE = 'VE' and (TYPECODE = 'NW'))
		))"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @ErrorCode=0
begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Clear out all rows from CPAPORTFOLIO as per the filter

	Set @sSQLString="
	Delete CPAPORTFOLIO
	from CPAPORTFOLIO CPA"+
	@sOfficeJoin+
	@sFilter

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOfficeCPACode	nvarchar(3)',
					  @psOfficeCPACode=@psOfficeCPACode
					  
-- Get the highest existing PORTFOLIONO 
	-- remaining after the Delete.
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Select @nLastPortfolioNo=isnull(max(PORTFOLIONO),0)
		from CPAPORTFOLIO"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nLastPortfolioNo		int	output',
					  @nLastPortfolioNo=@nLastPortfolioNo	output
	End

	-- Now Load the CPAPORTFOLIO table

	If @ErrorCode=0
	Begin
		set @sSQLString="
		insert into CPAPORTFOLIO(PORTFOLIONO,
		DATEOFPORTFOLIOLST,CLIENTNO,CLIENTCURRENCY,IPCOUNTRYCODE,TYPECODE,TYPENAME,IPRENEWALNO,IPRURN,PARENTNO,
		PATENTPCTNO,FIRSTPRIORITYNO,APPLICATIONNO,PUBLICATIONNO,REGISTRATIONNO,NEXTRENEWALDATE,BASEDATE,
		EXPIRYDATE,PARENTDATE,PCTFILINGDATE,FIRSTPRIORITYDATE,APPLICATIONDATE,PUBLICATIONDATE,GRANTDATE,
		PROPRIETOR,CLIENTREF,CLIENTCASECODE,DIVISIONCODE,DIVISIONNAME,ANNUITY,TRADEMARKREF,AGENTCASECODE,
		RESPONSIBLEPARTY,LASTAMENDDATE,STATUSINDICATOR)--, CASEID) -- 19558 perform as separate update
		select PORTFOLIONO+@nLastPortfolioNo,
		DATEOFPORTFOLIOLST,CLIENTNO,CLIENTCURRENCY,IPCOUNTRYCODE,TYPECODE,TYPENAME,IPRENEWALNO,IPRURN,PARENTNO,
		PATENTPCTNO,FIRSTPRIORITYNO,APPLICATIONNO,PUBLICATIONNO,REGISTRATIONNO,NEXTRENEWALDATE,BASEDATE,
		EXPIRYDATE,PARENTDATE,PCTFILINGDATE,FIRSTPRIORITYDATE,APPLICATIONDATE,PUBLICATIONDATE,GRANTDATE,
		PROPRIETOR,CLIENTREF,CLIENTCASECODE,DIVISIONCODE,DIVISIONNAME,ANNUITY,TRADEMARKREF,AGENTCASECODE,
		RESPONSIBLEPARTY,LASTAMENDDATE,STATUSINDICATOR --, CS.CASEID
		from #TEMPCPAPORTFOLIO CPA"+
		@sOfficeJoin+
		@sFilter

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOfficeCPACode	nvarchar(3),
					  @nLastPortfolioNo	int',
					  @psOfficeCPACode=@psOfficeCPACode,
					  @nLastPortfolioNo=@nLastPortfolioNo

		Set @pnRowCount=@@Rowcount
	End

	-- 19558 Now Update the CASEID where the casecode matches the CPA CASECODE (include COUNTRYCODE check and at least one official no.
	If @ErrorCode=0
	Begin
		set @sSQLString="
		Update CPAPORTFOLIO
		Set CASEID = CS.CASEID
		from CPAPORTFOLIO CPA
		join CASES CS on ("+CASE WHEN (@bUseClientCaseCode=1) THEN "CPA.CLIENTCASECODE=" ELSE "CPA.AGENTCASECODE=" END+CASE WHEN(@bCaseIdFlag=1) THEN "cast(CS.CASEID as varchar(15)))" ELSE "CS.IRN)" END + "
		join COUNTRY C on (C.COUNTRYCODE = CS.COUNTRYCODE  -- eliminates those where the country code does not match
					 and coalesce(C.ALTERNATECODE,C.COUNTRYCODE) = CPA.IPCOUNTRYCODE)
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
		-- collect the Inprotech ApplicationDate
		left join CASEEVENT CE8		on (CE8.CASEID=CS.CASEID
						and CE8.CYCLE =1
						and CE8.EVENTNO=@nApplicationEventNo)
		-- collect the Inprotech RegistrationDate
		left join CASEEVENT CE11	on (CE11.CASEID=CS.CASEID
						and CE11.CYCLE =1
						and CE11.EVENTNO=@nRegistrationEventNo)
		-- and eliminate any where the official numbers or dates don't roughly match at least
		where
		((nullif(ltrim(rtrim(replace(replace(replace(replace(upper(ONA.OFFICIALNUMBER),' ',''),'.',''),'-',''),',',''))),'' )
		 = nullif(ltrim(rtrim(replace(replace(replace(replace(upper(CPA.APPLICATIONNO),' ',''),'.',''),'-',''),',',''))),'' ))
		or
		 (nullif(ltrim(rtrim(replace(replace(replace(replace(upper(ONR.OFFICIALNUMBER),' ',''),'.',''),'-',''),',',''))),'' )
		 = nullif(ltrim(rtrim(replace(replace(replace(replace(upper(CPA.REGISTRATIONNO),' ',''),'.',''),'-',''),',',''))),'' ))
		or
		(nullif(ltrim(rtrim(replace(replace(replace(replace(upper(ONR.OFFICIALNUMBER),' ',''),'.',''),'-',''),',',''))),'' )
		 = nullif(ltrim(rtrim(replace(replace(replace(replace(upper(CPA.APPLICATIONNO),' ',''),'.',''),'-',''),',',''))),'' ))
		or
		 (nullif(ltrim(rtrim(replace(replace(replace(replace(upper(ONA.OFFICIALNUMBER),' ',''),'.',''),'-',''),',',''))),'' )
		 = nullif(ltrim(rtrim(replace(replace(replace(replace(upper(CPA.REGISTRATIONNO),' ',''),'.',''),'-',''),',',''))),'' ))
		or
		 (CPA.APPLICATIONDATE = CE8.EVENTDATE)
		or
		 ((case when CS.PROPERTYTYPE = 'T' then CPA.PCTFILINGDATE else CPA.GRANTDATE end)	 = CE11.EVENTDATE))"

		Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@nApplicationEventNo	int 		OUTPUT,
				  @nRegistrationEventNo	int 		OUTPUT,
				  @sApplicationNumberType	nvarchar(20) 		OUTPUT,
				  @sRegistrationNumberType	nvarchar(20) 		OUTPUT',
				  @nApplicationEventNo =@nApplicationEventNo	OUTPUT,
				  @nRegistrationEventNo=@nRegistrationEventNo OUTPUT,
				  @sApplicationNumberType =@sApplicationNumberType	OUTPUT,
				  @sRegistrationNumberType=@sRegistrationNumberType	OUTPUT
		Set @pnRowCount=@@Rowcount
	End

	-- If the CPA Portfolio has loaded cleanly then truncate the contents of the 	
	-- CPALOAD table.

	If @ErrorCode=0
	Begin
		set @sSQLString="Delete from CPALOAD"

		exec @ErrorCode=sp_executesql @sSQLString
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

grant execute on dbo.cpa_PortfolioLoad to public
go
