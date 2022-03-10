-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_CMSGetGHCaseDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_CMSGetGHCaseDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_CMSGetGHCaseDetail.'
	Drop procedure [dbo].[ig_CMSGetGHCaseDetail]
End
Print '**** Creating Stored Procedure dbo.ig_CMSGetGHCaseDetail...'
Print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.ig_CMSGetGHCaseDetail
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int

)
as
-- PROCEDURE :	ig_CMSGetGHCaseDetail
-- VERSION :	17
-- DESCRIPTION:	Returns case details to be used in Integration with CMS
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
--
--		The following details will be returned :
--			AllowDisb	"Y"
--			AllowTime	"Y"			
--			BillEmplUno	NAME via CASENAME where NAMETYPE ='SIG'	NAMECODE	
--			BillFreqCode	"M"		
--			ClientCode	NAME via CASENAME where NAMETYPE = 'I'	NAMECODE	Instructor
--			ClientMatName	CASETEXT where TEXTTYPE = 'TN'		SHORTTEXT/TEXT	Text type TN
--			ClientUno	NAMEAIAS				ALIAS
--			CloseDate								If case is not abandoned, Set to blank
--			CommentText	CASETEXT where TEXTTYPE = 'SP'		SHORTTEXT/TEXT	Text type SP
--			Inactive	CASES					STATUSCODE	If case is not abandoned, Set to "N"
--			JurisdicCode	CASES					TAXCODE			
--			LongMattName	CASETEXT where TEXTTYPE = 'T'		SHORTTEXT/TEXT	Text type T
--			MattCatCode	CASES					CASECATEGORY	Category, but the old categories will not match the new categories.
--			IntClasses	CASES					INTCLASSES	"No direct conversion possible.These class codes may need to change"
--			IRN		CASES					IRN
--			Title		CASES					TITLE		
--			Office		OFFICE via CASES.OFFICEID		USERCODE	Office
--			OpenDate	CASEEVENT where EVENTNO = -13		EVENTDATE	date of entry, event -13
--			RespEmplUno	NAME via CASENAME where NAMETYPE='EMP'	NAMECODE	Use the Personnel DAC to get EmplUno based on EmployeeCode
--			StatusCode	CASES					STATUSCODE	If case is not abandoned, Set to "O"
--	Custom Fields
--			ApplicationNum	OFFICIALNUMBERS where NUMBERTYPE = 'A'	OFFICIALNUMBER	Official number type A
--			SerialNum	OFFICIALNUMBERS where NUMBERTYPE = 'R'	OFFICIALNUMBER	Official number type R
--			AgentRef	CASENAME where NAMETYPE = 'I'		REFERENCENO	Instructor Reference
--			CountryCode	CASES					COUNTRYCODE	Country
--			CountryAdj	COUNTRY via CASES.COUNTRYCODE		COUNTRYADJECTIVE
--			Family		CASES					FAMILY
--			BillGrpCode	ALIAS via CASENAME where NAMETYPE = 'D' ALIAS	Name type D
--			DBAgentRef	CASENAME where NAMETYPE = 'D'		REFERENCENO	Name type D Reference
--			CaseAtt	NAME via CASENAME.CORRESPONDNAME where NAMETYPE = 'D'	FIRSTNAME+' '+NAME	Q: Should this be the Debtor attention or the case attention ?
--			OldMatNum	OFFICIALNUMBERS where NUMBERTYPE = 'G'	OFFICIALNUMBER	Number type G
--			DateApplication	CASEEVENT where EVENTNO = -4		EVENTDATE	Event -4
--			DateSent	CASEEVENT where EVENTNO = -20		EVENTDATE	Event -20
--			DateRegistered	CASEEVENT where EVENTNO = -8		EVENTDATE	Event -8
--			PurchaseOrderNo	CASES					PURCHASEORDERNO
--			LocalClasses	CASES					LOCALCLASSES	Replace all commas with a space

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2005	MF	11022	1	Procedure created
-- 22 Nov 2005	MF	11022	2	Changes to columns returned
-- 05 Dec 2005	PK	11022	3	Change BillGrpCode to return NameAlias.Alias and not NameCode
-- 08 Dec 2005	PK	11022	4	Add Contingency, ProrateTime, GenDisbFlag, FeeBillFormat
-- 24 Feb 2006	DJP	12294	5	Various corrections and additions reported from initial testing
-- 28 Mar 2006	DJP	RFC3758	6	Add StActiveMatt & eefault LongMattName to case title when blank
-- 26 Jun 2006	PK	RFC3987	7	Return Empty string for all Null string values
-- 19 Oct 2006	PK	4528	8	Require Owners NameType to be interfaced to CMS
-- 05 Dec 2006	PK	4774	9	Remove check on renewal status and allow dead cases to integrate
-- 09 Jan 2007	PK	4931	10	LongMattName truncation in CMS
-- 19 Mar 2008	vql	SQA14773 11	Make PurchaseOrderNo nvarchar(80)
-- 20 Sep 2007	DJP	RFC5847	10a	Change derivation of Registration No to allow for Patent No
--                                      Change derivation of Application No to allow for Design No
-- 11 Dec 2008	MF	17136	12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	13	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are considered for the Case.
-- 05 Jul 2013	vql	R13629	14	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 27 Feb 2014	DL	S21508	15	Change variables and temp table columns that reference namecode to 20 characters
-- 14 Nov 2018  AV  75198/DR-45358	16   Date conversion errors when creating cases and opening names in Chinese DB
-- 13 May 2020	DL	DR-58943	17	Ability to enter up to 3 characters for Number type code via client server	


set nocount on
set concat_null_yields_null off

-- Store the Case details for each Case so they can easily be extracted as XML once
-- all data has been retrieved.
Create table #TEMPCASEDETAILS (
			AllowBill		nvarchar(1)	collate database_default NOT NULL,
			AllowDisb		nvarchar(1)	collate database_default NOT NULL,
			AllowTime		nvarchar(1)	collate database_default NOT NULL,
			BasCurrFrom		nvarchar(2)	collate database_default NOT NULL,
			BasDisbCurr		nvarchar(2)	collate database_default NOT NULL,
			StdCurrFrom		nvarchar(2)	collate database_default NOT NULL,
			StdDisbCurr		nvarchar(2)	collate database_default NOT NULL,
			TobCurrFrom		nvarchar(2)	collate database_default NOT NULL,
			TobDisbCurr		nvarchar(2)	collate database_default NOT NULL,
			BillEmplUno		nvarchar(20)	collate database_default NULL,
			BillFreqCode		nvarchar(1)	collate database_default NOT NULL,
			BillGrpUno		nvarchar(10)	collate database_default NULL,
			ClientCode		nvarchar(20)	collate database_default NULL,
			ClientUno		nvarchar(30)	collate database_default NULL,
			CloseDate		datetime	null,
			CurrencyCode		nvarchar(3)	collate database_default NULL,
			Inactive		nvarchar(1)	collate database_default NULL,
			JurisdicCode		nvarchar(3)	collate database_default NULL,
			MattCatCode		nvarchar(2)	collate database_default NULL,	
			IntClasses		nvarchar(254)	collate database_default NULL,	
			IRN			nvarchar(30)	collate database_default NULL,	
			Title			nvarchar(40)	collate database_default NULL,	
			MatterUno		nvarchar(30)	collate database_default NULL,
			NextFreqDate		datetime	NULL,
			Office			nvarchar(80)	collate database_default NULL,	
			OpenDate		datetime	NULL,
			OpenEmplUno		nvarchar(20)	collate database_default NULL,
			RespEmplUno		nvarchar(20)	collate database_default NULL,
			StActiveMatt		nvarchar(1)	collate database_default NULL,
			StatusCode		nvarchar(1)	collate database_default NULL,
			ApplicationNum		nvarchar(36)	collate database_default NULL,	
			SerialNum		nvarchar(36)	collate database_default NULL,	
			AgentRef		nvarchar(80)	collate database_default NULL,	
			CountryCode		nvarchar(3)	collate database_default NULL,	
			CountryAdj		nvarchar(30)	collate database_default NULL,	
			Family			nvarchar(20)	collate database_default NULL,	
			BillGrpCode		nvarchar(10)	collate database_default NULL,
			DBAgentRef		nvarchar(80)	collate database_default NULL,
			CaseAtt			nvarchar(254)	collate database_default NULL,
			OldMatNum		nvarchar(36)	collate database_default NULL,	
			DateApplication		datetime	NULL,
			DateSent		datetime	NULL,
			DateRegistered		datetime	NULL,
			PurchaseOrderNo		nvarchar(80)	collate database_default NULL,
			CaseType		nvarchar(1)	collate database_default NULL,
			PropertyType		nvarchar(1)	collate database_default NULL,
			SubType			nvarchar(2)	collate database_default NULL,
			Basis			nvarchar(2)	collate database_default NULL,
			LocalClasses		nvarchar(80)	collate database_default NULL,
		)

Declare		@ErrorCode	int
Declare		@nRowCount	int

Declare	@sSQLString	nvarchar(max)
Declare	@sAliasType1	nvarchar(2)
Declare	@sNumberType1	nvarchar(3)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Get the Site Control that holds the Alias Type for the CMS Client No.
If @ErrorCode=0
Begin
	Set @sSQLString="
	select @sAliasType1=substring(S1.COLCHARACTER,1,2),
		@sNumberType1=substring(S2.COLCHARACTER,1,3)						
	from SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='CMS Unique Matter Number Type')
	where S1.CONTROLID='CMS Unique Client Alias Type'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sAliasType1	nvarchar(2)	OUTPUT,
				  @sNumberType1	nvarchar(3)	OUTPUT',
				  @sAliasType1=@sAliasType1	OUTPUT,
				  @sNumberType1=@sNumberType1	OUTPUT
End

-- Now get the Case details.  Bring them back into a temporary table as there
-- are too many tables to join for a single Select.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCASEDETAILS(
			AllowBill,
			AllowDisb,
			AllowTime,
			BasCurrFrom,
			BasDisbCurr,
			StdCurrFrom,
			StdDisbCurr,
			TobCurrFrom,
			TobDisbCurr,
			BillEmplUno,
			BillFreqCode,
			BillGrpUno,
			ClientCode,
			ClientUno,
			CloseDate,
			CurrencyCode,
			Inactive,
			JurisdicCode,
			MattCatCode,
			IntClasses,
			IRN,
			Title,
			RespEmplUno,
			StActiveMatt,
			StatusCode,
			AgentRef,
			CountryCode,
			Family,
			BillGrpCode,
			DBAgentRef,
			CaseAtt,
			PurchaseOrderNo,
			CaseType,
			PropertyType,
			SubType,
			Basis,
			LocalClasses)
	Select 	top 1
		'Y',				-- AllowBill
		'Y',				-- AllowDisb
		'Y',				-- AllowTime
		'MA',				-- BasCurrFrom
		'MA',				-- BasDisbCurr
		'MA',				-- StdCurrFrom
		'MA',				-- StdDisbCurr
		'MA',				-- TobCurrFrom
		'MA',				-- TobDisbCurr
		isnull(N.NAMECODE,EMP.NAMECODE),-- BillEmplUno
		'M',				-- BillFreqCode
		NAD.ALIAS,			-- BillGrpUno
		NI.NAMECODE,			-- ClientCode
		isnull(NAI.ALIAS,''),		-- ClientUno
		CASE WHEN S.LIVEFLAG=0
		   THEN convert(nvarchar,getdate(),112)
		END,				-- CloseDate
		isnull(IPD.CURRENCY,''),	-- CurrencyCode
		CASE WHEN S.LIVEFLAG=0
		   THEN 'Y'
		   ELSE 'N'
		END,				-- Inactive
		isnull(C.TAXCODE,''),		-- JurisdicCode
		isnull(C.CASECATEGORY,''),	-- MattCatCode
		NULL,				-- IntClasses
		isnull(C.IRN,''),		-- IRN
		SUBSTRING (C.TITLE,1,40),	-- Title
		--SUBSTRING(isnull(isnull(case when CT.LONGFLAG=1 
		--		then CT.TEXT 
		--		else CT.SHORTTEXT 
		--		end,C.TITLE),''),1,40) ,-- Title
		EMP.NAMECODE,			-- RespEmplUno
		'N',				-- StActiveMatt
		CASE WHEN isnull(S.LIVEFLAG,1)=1
		  THEN 'O'
		  ELSE 'C'
		END,				-- StatusCode
		isnull(CNI.REFERENCENO,''),	-- AgentRef
		isnull(C.COUNTRYCODE,''),	-- CountryCode
		isnull(C.FAMILY,''),		-- Family
		isnull(NAD.ALIAS,''),		-- BillGrpCode
		isnull(CND.REFERENCENO,''),	-- DBAgentRef
		isnull(CASE WHEN(ATT.FIRSTNAME is not null) 
			THEN ATT.FIRSTNAME+' '+ATT.NAME
			ELSE ATT.NAME
		END,''),			-- CaseAtt
		isnull(C.PURCHASEORDERNO,''),	-- PurchaseOrderNo
		isnull(C.CASETYPE,''),		-- CaseType
		isnull(C.PROPERTYTYPE,''),	-- PropertyType
		isnull(C.SUBTYPE,''),		-- SubType
		isnull(P.BASIS,''),		-- Basis
		replace(isnull(C.LOCALCLASSES,''),',',' ')	-- LocalClasses (replace all commas with spaces)
	From CASES C
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	left join PROPERTY P	on (P.CASEID=C.CASEID)
	left join STATUS R	on (R.STATUSCODE=P.RENEWALSTATUS)

	left join CASENAME CN	on (CN.CASEID=C.CASEID
				and CN.NAMETYPE='SIG'
				and CN.EXPIRYDATE is null)
	left join NAME N	on (N.NAMENO=CN.NAMENO)

	left join CASENAME CNI	on (CNI.CASEID=C.CASEID
				and CNI.NAMETYPE='I'
				and CNI.EXPIRYDATE is null)
	left join NAME NI	on (NI.NAMENO=CNI.NAMENO)
	left join NAMEALIAS NAI	on (NAI.NAMENO	=NI.NAMENO
				and NAI.ALIASTYPE=@sAliasType1
						-- SQA18703
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and NAI.ALIAS    =(select substring(max(CASE WHEN(NAI1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(NAI1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									NAI1.ALIAS),3,30)
						  from NAMEALIAS NAI1
						  where NAI1.NAMENO=NAI.NAMENO
						  and NAI1.ALIASTYPE=NAI.ALIASTYPE
						  and(NAI1.COUNTRYCODE =C.COUNTRYCODE  OR NAI1.COUNTRYCODE  is null)
						  and(NAI1.PROPERTYTYPE=C.PROPERTYTYPE OR NAI1.PROPERTYTYPE is null)))

	left join CASENAME CNE	on (CNE.CASEID=C.CASEID
				and CNE.NAMETYPE='EMP'
				and CNE.EXPIRYDATE is null)
	left join NAME EMP	on (EMP.NAMENO=CNE.NAMENO)

	left join CASENAME CND	on (CND.CASEID=C.CASEID
				and CND.NAMETYPE='D'
				and CND.EXPIRYDATE is null)
	left join NAME ND	on (ND.NAMENO=CND.NAMENO)
	left join IPNAME IPD	on (ND.NAMENO = IPD.NAMENO)
	left join NAMEALIAS NAD	on (NAD.NAMENO	 =ND.NAMENO
				and NAD.ALIASTYPE=@sAliasType1
						-- SQA18703
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and NAD.ALIAS    =(select substring(max(CASE WHEN(NAD1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(NAD1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									NAD1.ALIAS),3,30)
						  from NAMEALIAS NAD1
						  where NAD1.NAMENO=NAD.NAMENO
						  and NAD1.ALIASTYPE=NAD.ALIASTYPE
						  and(NAD1.COUNTRYCODE =C.COUNTRYCODE  OR NAD1.COUNTRYCODE  is null)
						  and(NAD1.PROPERTYTYPE=C.PROPERTYTYPE OR NAD1.PROPERTYTYPE is null)))
	left join NAME ATT	on (ATT.NAMENO=isnull(CND.CORRESPONDNAME, ND.MAINCONTACT))
	left join CASETEXT CT	on (CT.CASEID = C.CASEID
				and CT.TEXTTYPE = 'T')

	Where C.CASEID=@pnCaseKey"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int,
				  @sAliasType1	nvarchar(2)',
				  @pnCaseKey=@pnCaseKey,
				  @sAliasType1=@sAliasType1
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPCASEDETAILS
	Set	NextFreqDate	=CE13.EVENTDATE,
		Office		=isnull(O.USERCODE,''),
		OpenDate	=CE13.EVENTDATE,
		OpenEmplUno	=isnull(USR.NAMECODE,''),
		MatterUno	=isnull(ONX.OFFICIALNUMBER,''),
-- DJP 20-Sep-2007 first check for Design No and Patent No
		ApplicationNum	=isnull(OND.OFFICIALNUMBER,isnull(ONA.OFFICIALNUMBER,'')),
		SerialNum	=isnull(ONP.OFFICIALNUMBER,isnull(ONR.OFFICIALNUMBER,'')),
		CountryAdj	=isnull(CT.COUNTRYADJECTIVE,''),
		OldMatNum	=isnull(ONG.OFFICIALNUMBER,''),
		DateApplication	=CE4.EVENTDATE,
		DateSent	=CE20.EVENTDATE,
		DateRegistered	=CE8.EVENTDATE
	From #TEMPCASEDETAILS T
	cross join CASES C
	left  join OFFICE O		on (O.OFFICEID=C.OFFICEID)
	left  join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left  join CASEEVENT CE4	on (CE4.CASEID=C.CASEID
					and CE4.EVENTNO=-4
					and CE4.CYCLE=1)
	left  join CASEEVENT CE8	on (CE8.CASEID=C.CASEID
					and CE8.EVENTNO=-8
					and CE8.CYCLE=1)
	left  join CASEEVENT CE13	on (CE13.CASEID=C.CASEID
					and CE13.EVENTNO=-13
					and CE13.CYCLE=1)
	left  join CASEEVENT CE20	on (CE20.CASEID=C.CASEID
					and CE20.EVENTNO=-20
					and CE20.CYCLE=1)
	left  join OFFICIALNUMBERS ONX	on (ONX.CASEID=C.CASEID
					and ONX.NUMBERTYPE=@sNumberType1)
	left  join OFFICIALNUMBERS ONA	on (ONA.CASEID=C.CASEID
					and ONA.NUMBERTYPE='A'
					and ONA.ISCURRENT=1)
	left  join OFFICIALNUMBERS ONR	on (ONR.CASEID=C.CASEID
					and ONR.NUMBERTYPE='R'
					and ONR.ISCURRENT=1)
	left  join OFFICIALNUMBERS OND	on (OND.CASEID=C.CASEID
					and OND.NUMBERTYPE='D'
					and OND.ISCURRENT=1)
	left  join OFFICIALNUMBERS ONP	on (ONP.CASEID=C.CASEID
					and ONP.NUMBERTYPE='Z'
					and ONP.ISCURRENT=1)
	left  join OFFICIALNUMBERS ONG	on (ONG.CASEID=C.CASEID
					and ONG.NUMBERTYPE='G'
					and ONG.ISCURRENT=1)
	left join CASES_iLOG CL		on (CL.CASEID = C.CASEID	
					and CL.LOGACTION = 'I')		
	left join USERIDENTITY U	on (U.LOGINID = SUBSTRING(CL.LOGUSERID,charindex('\',CL.LOGUSERID)+1 ,50)) 
	left join NAME USR		on (USR.NAMENO = U.NAMENO)	

	Where C.CASEID=@pnCaseKey"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int,
				  @sNumberType1	nvarchar(3)',
				  @pnCaseKey=@pnCaseKey,
				  @sNumberType1=@sNumberType1
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	T.AllowBill,
		T.AllowDisb,
		T.AllowTime,
		T.BasCurrFrom,
		T.BasDisbCurr,
		T.StdCurrFrom,
		T.StdDisbCurr,
		T.TobCurrFrom,
		T.TobDisbCurr,
		T.BillEmplUno,
		T.BillFreqCode,
		T.ClientCode,
		CASE WHEN(CT1.LONGFLAG=1) THEN ISNULL(CT1.TEXT,'') ELSE ISNULL(CT1.SHORTTEXT,'') END as [ClientMatName],
		T.ClientUno,
		T.CloseDate,
		T.CurrencyCode,
		CASE WHEN(CT2.LONGFLAG=1) THEN ISNULL(CT2.TEXT,'') ELSE ISNULL(CT2.SHORTTEXT,'') END as [CommentText],
		T.Inactive,
		T.JurisdicCode,
		SUBSTRING(CASE 	WHEN(CT3.LONGFLAG=1) THEN 
				CASE 	WHEN CAST(CT3.TEXT as nvarchar(250)) = C.TITLE THEN C.TITLE+Char(9) 
					ELSE ISNULL(CT3.TEXT,'') 
					END 
			ELSE 	CASE 	WHEN CAST(CT3.SHORTTEXT as nvarchar(250))= C.TITLE THEN C.TITLE+Char(9)
					ELSE ISNULL(CT3.SHORTTEXT,C.TITLE+Char(9)) 
					END 
			END,1,250) as [LongMattName],
		T.MattCatCode,
		T.IntClasses,
		T.IRN,
		T.Title,
		T.MatterUno,
		T.NextFreqDate,
		T.Office,
		T.OpenDate,
		T.OpenEmplUno,
		T.RespEmplUno,
		T.StActiveMatt,
		T.StatusCode,
		T.ApplicationNum,
		T.SerialNum,
		T.AgentRef,
		T.CountryCode,
		T.CountryAdj,
		T.Family,
		T.BillGrpCode,
		T.DBAgentRef,
		T.CaseAtt,
		T.OldMatNum,
		T.DateApplication,
		T.DateSent,
		T.DateRegistered,
		T.PurchaseOrderNo,
		Case When(isnull(CT3.TEXT,CT3.SHORTTEXT) is null) 
						Then 'I' --M
		     When(T.IRN is null)	Then 'I' --M
		     When(T.Title is null)	Then 'I' --M
		     When(T.StatusCode is null)	Then 'I' --M
		     				Else 'I'
		End 				as [DataRetrievalStatus],
		'N' as [Contingency],
		'N' as [ProrateTime],
		'N' as [GenDisbFlag],
		'1' as [FeeBillFormat],
		T.CaseType,
		T.PropertyType,
		T.SubType,
		T.Basis,
		T.LocalClasses
	From #TEMPCASEDETAILS T
	Cross Join CASES C
	left  Join CASETEXT CT1	on (CT1.CASEID=C.CASEID
				and CT1.TEXTTYPE='TN'
				and CT1.MODIFIEDDATE=(	select max(isnull(CT1A.MODIFIEDDATE, '19000101'))
							from CASETEXT CT1A
							where CT1A.CASEID=CT1.CASEID
							and CT1A.TEXTTYPE=CT1.TEXTTYPE ))
	left  Join CASETEXT CT2	on (CT2.CASEID=C.CASEID
				and CT2.TEXTTYPE='SP'
				and CT2.MODIFIEDDATE=(	select max(isnull(CT2A.MODIFIEDDATE, '19000101'))
							from CASETEXT CT2A
							where CT2A.CASEID=CT2.CASEID
							and CT2A.TEXTTYPE=CT2.TEXTTYPE ))
	left  Join CASETEXT CT3	on (CT3.CASEID=C.CASEID
				and CT3.TEXTTYPE='T'
				and CT3.MODIFIEDDATE=(	select max(isnull(CT3A.MODIFIEDDATE, '19000101'))
							from CASETEXT CT3A
							where CT3A.CASEID=CT3.CASEID
							and CT3A.TEXTTYPE=CT3.TEXTTYPE ))
	Where C.CASEID=@pnCaseKey"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey	int',
				  @pnCaseKey=@pnCaseKey
End

return @ErrorCode
go

grant execute on dbo.ig_CMSGetGHCaseDetail to public
go
