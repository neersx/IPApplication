-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_CMSGetGHNameDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_CMSGetGHNameDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_CMSGetGHNameDetails.'
	Drop procedure [dbo].[ig_CMSGetGHNameDetails]
End
Print '**** Creating Stored Procedure dbo.ig_CMSGetGHNameDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE  PROCEDURE dbo.ig_CMSGetGHNameDetails
(
	@pnNameKey	int		-- Mandatory
)
as
-- PROCEDURE:	ig_CMSGetGHNameDetails
-- VERSION:	12
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Name result set for CMS Interface.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2005  TM	11022	1	Procedure created
-- 22 Nov 2005	TM	RFC3261	2	Implement new columns and rename ig_CMSGetNameDetails to be 
--					ig_CMSGetGHNameDetails.
-- 22 Feb 2006  DJP     12294   3	Various corrections and additions reported from initial testing
-- 27 Jun 2006	PK	3897	4	Return null string as empty string
-- 16 Oct 2006	PK	4404	5	Some address updates are failing for names where the street field is longer than 60 characters.
-- 16 Oct 2006	PK	4528	6	Require Owners NameType to be interfaced to CMS
-- 20 Oct 2006	PK	4403	7	Some client updates are failing for names that are greater than 40 characters.
-- 25 Oct 2006	PK	4528	8	Bug fixes - Require Owners NameType to be interfaced to CMS
-- 20 Sep 2007	DJP	RFC5846	8a	Strip carriage returns from address lines
-- 09 May 2008	Dw	SQA16326 9	Extended FormalSalutation column
-- 11 Dec 2008	MF	17136	10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	11	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 11 Apr 2013	DV	R13270	12	Increase the length of nvarchar to 11 when casting or declaring integer 


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @nRowCount				int
Declare @sSQLString				nvarchar(4000)
Declare @bDataRetrievalStatus			nvarchar(1)
Declare @sNameType				nvarchar(1)
Declare @sIntegrationType			nvarchar(1)
Declare @sStreet1_1				nvarchar(550)
Declare @sAddress1_1				nvarchar(60)
Declare @sAddress1_2				nvarchar(60)
Declare @sAddress1_3				nvarchar(60)
Declare @sAddress1_4				nvarchar(60)
Declare @sStreet1_2				nvarchar(550)
Declare @sAddress2_1				nvarchar(60)
Declare @sAddress2_2				nvarchar(60)
Declare @sAddress2_3				nvarchar(60)
Declare @sAddress2_4				nvarchar(60)
Declare @nChar13				smallint


Declare @tblName table (Nationality		nvarchar(60)	collate database_default null,
			FirstName		nvarchar(50)	collate database_default null,
			LastName		nvarchar(30)	collate database_default null,
			Sex			nvarchar(1)	collate database_default null,
			Inactive		nvarchar(8)	collate database_default null,
			Name			nvarchar(254)	collate database_default null,
			ClientName		nvarchar(40)	collate database_default null,
			SearchKey1		nvarchar(20)	collate database_default null,
			NameType		nvarchar(1)	collate database_default null,
			FormalSalutation 	nvarchar(50)	collate database_default null,
			Title			nvarchar(20)	collate database_default null,
			BillEmplUno		nvarchar(10)	collate database_default null,
			ClientCode		nvarchar(10)	collate database_default null,
			ClientUno		nvarchar(30)	collate database_default null,
			NameUno			nvarchar(30)	collate database_default null,	 
			ClntTypeCode		nvarchar(80)	collate database_default null,	 
			CurrencyCode		nvarchar(3)	collate database_default null,	
			Dept			nvarchar(3)	collate database_default null,	
			DisbClass		nvarchar(1)	collate database_default null,
			DisbJurOvride		nvarchar(1)	collate database_default null,
			UsedAsFlag		smallint				 null,
			HasSubs			nvarchar(1)	collate database_default null,
			NotesText		ntext		collate database_default null,
			Office			nvarchar(80)	collate database_default null,
			OpenDate		datetime,
			OpenEmplUno		nvarchar(10)	collate database_default null,	
			ParentClntUno		nvarchar(30)	collate database_default null,	
			Prof			nvarchar(3)	collate database_default null,
			RespEmplUno		nvarchar(10)	collate database_default null,
			StatusCode		nvarchar(1)	collate database_default null,
			TimeClass		nvarchar(1)	collate database_default null,
			TimeInc			nvarchar(1)	collate database_default null,
			TimeJurOvride		nvarchar(1)	collate database_default null,
			AddrTypeCode1		nvarchar(4)	collate database_default null,	
			Street1_1		nvarchar(550)	collate database_default null,
			City1			nvarchar(30)	collate database_default null,	
			CountryCode1		nvarchar(3)	collate database_default null,	
			Fax1			nvarchar(400)	collate database_default null,	
			PhoneExtNum1		nvarchar(5)	collate database_default null,	
			Phone1			nvarchar(400)	collate database_default null,	
			PostCode1		nvarchar(10)	collate database_default null,	
			StateCode1		nvarchar(20)	collate database_default null,	
			DefaultAddress		nvarchar(1)	collate database_default null,
			AddrTypeCode2		nvarchar(4)	collate database_default null,	
			Street1_2		nvarchar(550)	collate database_default null,
			City2			nvarchar(30)	collate database_default null,	
			CountryCode2		nvarchar(3)	collate database_default null,	
			Fax2			nvarchar(400)	collate database_default null,	
			PhoneExtNum2		nvarchar(5)	collate database_default null,	
			Phone2			nvarchar(400)	collate database_default null,	
			PostCode2		nvarchar(10)	collate database_default null,	
			StateCode2		nvarchar(20)	collate database_default null,	
			BillingInstText		ntext		collate database_default null,
			DataRetrievalStatus	nvarchar(1)	collate database_default null,
			IntegrationType		nvarchar(1)	collate database_default null)


-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0
Set @bDataRetrievalStatus = 'N'

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select		@bDataRetrievalStatus = 'I', -- If the name currenty processed is a client, set 'DataRetrievalStatus' column to 'I'. 
			@sNameType = CASE WHEN n.USEDASFLAG&1=1 THEN 'P' ELSE 'O' END,
			@sIntegrationType = CASE WHEN n.USEDASFLAG&4=4 THEN 'C' ELSE CASE WHEN (USEDASFLAG in (0,1) and ta.PARENTTABLE is not null) THEN 'N' ELSE 'U' END END
	from		NAME n
	left join	TABLEATTRIBUTES ta
			on upper(ta.PARENTTABLE) = 'NAME'
			and TABLECODE = 10057 -- Owner
			and TABLETYPE = 30 -- Name Type
			and GENERICKEY = n.NAMENO
	where		NAMENO = @pnNameKey
	and		(n.USEDASFLAG&4=4 or (USEDASFLAG in (0,1) and ta.PARENTTABLE is not null))"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@bDataRetrievalStatus	nvarchar(1)		OUTPUT,
				  @sNameType		nvarchar(1)		OUTPUT,
				  @sIntegrationType	nvarchar(1)		OUTPUT,
				  @pnNameKey		int',
				  @bDataRetrievalStatus	= @bDataRetrievalStatus	OUTPUT,
				  @sNameType		= @sNameType		OUTPUT,
				  @sIntegrationType	= @sIntegrationType	OUTPUT,
				  @pnNameKey		= @pnNameKey
End

-- Populating Name result set
If @nErrorCode = 0
and @bDataRetrievalStatus = 'I'
Begin
	Insert into @tblName 
	(Nationality, FirstName, LastName, Sex, Inactive, Name, ClientName, SearchKey1, NameType, FormalSalutation, Title, 
	BillEmplUno, ClientCode, ClientUno, NameUno, ClntTypeCode, CurrencyCode, Dept, DisbClass, DisbJurOvride, HasSubs, 
	NotesText,Office, OpenDate, OpenEmplUno, ParentClntUno, Prof, RespEmplUno, StatusCode, 
	TimeClass, TimeInc, TimeJurOvride, AddrTypeCode1, Street1_1, City1, CountryCode1, Fax1, PhoneExtNum1, Phone1, 
	PostCode1, StateCode1, DefaultAddress, AddrTypeCode2, Street1_2, City2, CountryCode2, Fax2, PhoneExtNum2, Phone2, 
	PostCode2, StateCode2, BillingInstText, DataRetrievalStatus,IntegrationType)	
	Select	top 1
	isnull(N.NATIONALITY,''), 
	CASE WHEN @sNameType = 'P' THEN left(N.FIRSTNAME,20) ELSE '' END,
	CASE WHEN @sNameType = 'P' THEN left(N.NAME,30) ELSE '' END,
	isnull(I.SEX,''),
	CASE WHEN N.DATECEASED is not null THEN 'Y' ELSE 'N' END,
	left(CASE WHEN @sNameType = 'P' THEN isnull(N.NAME,'')+CASE WHEN isnull(N.NAME,'') != '' and isnull(N.FIRSTNAME,'') != '' THEN ', ' ELSE '' END + isnull(N.FIRSTNAME,'') ELSE N.NAME END,120), -- Name
	left(CASE WHEN @sNameType = 'P' THEN isnull(N.NAME,'')+CASE WHEN isnull(N.NAME,'') != '' and isnull(N.FIRSTNAME,'') != '' THEN ', ' ELSE '' END + isnull(N.FIRSTNAME,'') ELSE N.NAME END,40), -- ClientName
	isnull(N.SEARCHKEY1,''),
	@sNameType,
	isnull(I.FORMALSALUTATION,''),
	N.TITLE,
	EN.NAMECODE, 
	N.NAMECODE,
	CAL.ALIAS,
	NAL.ALIAS,
	CAT.USERCODE,
	isnull(IP.CURRENCY,''),
	'DEF',
	'B',
	'N',
	'Y', 	
	ISNULL(NT.TEXT,''),
	isnull(O.DESCRIPTION,''),
	NL.LOGDATETIMESTAMP,
	USR.NAMECODE,
	PCAL.ALIAS,
	'DEF',
	EN.NAMECODE,
	CASE WHEN N.DATECEASED is not null THEN 'C' ELSE 'O' END, 
	'B',
	'S',
	'N',
	'MAIN',
	isnull(PA1.STREET1,''),
	isnull(PA1.CITY,''),
	isnull(PA1.COUNTRYCODE,''),
	isnull(dbo.fn_FormatTelecom(F1.TELECOMTYPE, F1.ISD, F1.AREACODE, F1.TELECOMNUMBER, F1.EXTENSION),''),
	isnull(T1.EXTENSION,''),
	isnull(dbo.fn_FormatTelecom(T1.TELECOMTYPE, T1.ISD, T1.AREACODE, T1.TELECOMNUMBER, NULL),''),
	isnull(PA1.POSTCODE,''),
	isnull(PA1.STATE,''),
	'Y',
	case when @sIntegrationType='C' then 'COLL' else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then PA1.STREET1 else PA2.STREET1 end,'') else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then PA1.CITY else PA2.CITY end,'') else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then PA1.COUNTRYCODE else PA2.COUNTRYCODE end,'') else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then dbo.fn_FormatTelecom(F1.TELECOMTYPE, F1.ISD, F1.AREACODE, F1.TELECOMNUMBER, NULL) else dbo.fn_FormatTelecom(F2.TELECOMTYPE, F2.ISD, F2.AREACODE, F2.TELECOMNUMBER, NULL) end,'') else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then T1.EXTENSION else T2.EXTENSION end,'') else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then dbo.fn_FormatTelecom(T1.TELECOMTYPE, T1.ISD, T1.AREACODE, T1.TELECOMNUMBER, NULL) else dbo.fn_FormatTelecom(T2.TELECOMTYPE, T2.ISD, T2.AREACODE, T2.TELECOMNUMBER, NULL) end,'') else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then PA1.POSTCODE else PA2.POSTCODE end,'') else null end,
	case when @sIntegrationType='C' then isnull(case when PA2.COUNTRYCODE is null then PA1.STATE else PA2.STATE end,'') else null end,
	isnull(NTB.TEXT,''),
	'I',
	@sIntegrationType
	from NAME N 	
	left join INDIVIDUAL I		on (I.NAMENO = N.NAMENO)
	left join IPNAME IP		on (IP.NAMENO = N.NAMENO)
	-- For Category
	left join TABLECODES CAT	on (CAT.TABLECODE = IP.CATEGORY AND CAT.TABLETYPE = 6)	left join NAMETEXT NT		on (NT.NAMENO = N.NAMENO	
					and NT.TEXTTYPE = 'X')
	left Join TABLEATTRIBUTES TA	on (TA.GENERICKEY = cast(N.NAMENO as nvarchar(11))
	                               	and TA.PARENTTABLE = 'NAME'
	                               	and TA.TABLETYPE = 5004)
   	left Join TABLECODES O		on (O.TABLECODE = TA.TABLECODE)	 
	left join ASSOCIATEDNAME EMP	on (EMP.NAMENO = N.NAMENO
					and EMP.RELATIONSHIP = 'RES')  
	left join NAME EN		on (EN.NAMENO = EMP.RELATEDNAME) 	
	-- Main Postal Address details 
	left join ADDRESS PA1 		on (PA1.ADDRESSCODE = N.POSTALADDRESS)	
	left join COUNTRY PC1		on (PC1.COUNTRYCODE = PA1.COUNTRYCODE)	
	left Join STATE PS1		on (PS1.COUNTRYCODE = PA1.COUNTRYCODE	
	 	           	 	and PS1.STATE = PA1.STATE)		
	left join TELECOMMUNICATION F1	on (F1.TELECODE = N.FAX)		
	left join TELECOMMUNICATION T1 	on (T1.TELECODE = N.MAINPHONE)		
	-- Billing Postal Address details 
	left join ASSOCIATEDNAME BIL	on (BIL.NAMENO = N.NAMENO	
					and BIL.RELATIONSHIP = 'STM') 	
	left join NAME BN 		on (BN.NAMENO = BIL.RELATEDNAME) 
	left join ADDRESS PA2 		on (PA2.ADDRESSCODE = BN.POSTALADDRESS) 
	left join COUNTRY PC2		on (PC2.COUNTRYCODE = PA2.COUNTRYCODE)	
	left Join STATE PS2		on (PS2.COUNTRYCODE = PA2.COUNTRYCODE	
	 	           	 	and PS2.STATE = PA2.STATE)		
	left join TELECOMMUNICATION F2	on (F2.TELECODE = BN.FAX)		
	left join TELECOMMUNICATION T2 	on (T2.TELECODE = BN.MAINPHONE)		
	left join NAMETEXT NTB		on (NTB.NAMENO = N.NAMENO
					and NTB.TEXTTYPE = '_B')
	left join SITECONTROL SC1	on (SC1.CONTROLID = 'CMS Unique Name Alias Type')
	left join SITECONTROL SC2	on (SC2.CONTROLID = 'CMS Unique Client Alias Type')
	left join NAMEALIAS NAL		on (NAL.NAMENO = N.NAMENO
					and NAL.ALIASTYPE = SC1.COLCHARACTER
					and NAL.COUNTRYCODE  is null
					and NAL.PROPERTYTYPE is null)
	left join NAMEALIAS CAL		on (CAL.NAMENO = N.NAMENO
					and CAL.ALIASTYPE = SC2.COLCHARACTER
					and CAL.COUNTRYCODE  is null
					and CAL.PROPERTYTYPE is null)
	left join ORGANISATION ORG	on (ORG.NAMENO = N.NAMENO)	
	left join NAMEALIAS PCAL	on (PCAL.NAMENO = ORG.PARENT	
					and PCAL.ALIASTYPE = SC2.COLCHARACTER
					and PCAL.COUNTRYCODE  is null
					and PCAL.PROPERTYTYPE is null)	
	left join NAME_iLOG NL		on (NL.NAMENO = N.NAMENO	
					and NL.LOGACTION = 'I')		
	left join USERIDENTITY U	on (U.LOGINID = SUBSTRING(NL.LOGUSERID,charindex('\',NL.LOGUSERID)+1 ,50)) 
	left join NAME USR		on (USR.NAMENO = U.NAMENO)	
	where N.NAMENO = @pnNameKey

	Select  @nErrorCode = @@Error,
		@nRowCount = @@RowCount

	If @nErrorCode = 0
	and @nRowCount = 0
	Begin
		Raiserror ('There are no rows in the result set.',16,1)		
		Set @nErrorCode = @@Error
	End
	Else	
	If @nErrorCode = 0
	and @nRowCount > 1
	Begin
		Raiserror ('There is more than 1 row in the result set.',16,1)	
		Set @nErrorCode = @@Error
	End
End

-- Is manadatory data missing?
/*If @nErrorCode = 0
Begin
	Select 	@bDataRetrievalStatus = 'M'
	from 	@tblName
	where  (FirstName 	is null and @sNameType = 'P')
	or    	Name 		is null 
	or      SearchKey1 	is null
	or 	NameType 	is null
	or  	BillEmplUno	is null
	or	ClientCode	is null
	or	RespEmplUno	is null
	or	StatusCode	is null
	or	AddrTypeCode	is null
End*/

If  @nErrorCode = 0
and @bDataRetrievalStatus = 'I'
Begin
	Select	@sStreet1_1 = Street1_1, @sStreet1_2 = Street1_2
	from	@tblName

	Select @nChar13 = case when charindex(char(13),left(@sStreet1_1,60))>0 then 1 else 0 end
	Select @sAddress1_1 = isnull(left(dbo.fn_SplitTextOnCarriageReturn(@sStreet1_1,1),60),'')
	Select @sStreet1_1 = isnull(right(@sStreet1_1, len(@sStreet1_1) - len(@sAddress1_1) - @nChar13),'')
	Select @nChar13 = case when charindex(char(13),left(@sStreet1_1,60))>0 then 1 else 0 end
	Select @sAddress1_2 = isnull(left(dbo.fn_SplitTextOnCarriageReturn(@sStreet1_1,1),60),'')
	Select @sStreet1_1 = isnull(right(@sStreet1_1, len(@sStreet1_1) - len(@sAddress1_2) - @nChar13),'')
	Select @nChar13 = case when charindex(char(13),left(@sStreet1_1,60))>0 then 1 else 0 end
	Select @sAddress1_3 = isnull(left(dbo.fn_SplitTextOnCarriageReturn(@sStreet1_1,1),60),'')
	Select @sStreet1_1 = isnull(right(@sStreet1_1, len(@sStreet1_1) - len(@sAddress1_3) - @nChar13),'')
	Select @sAddress1_4 = isnull(left(@sStreet1_1,60),'')

-- DJP 20-Sep-07 added following lines to strip unwanted carriage returns from address components
	select @sAddress1_1 = replace(replace (@sAddress1_1,char(13)+char(10),''),char(10),'')
	select @sAddress1_2 = replace(replace (@sAddress1_2,char(13)+char(10),''),char(10),'')
	select @sAddress1_3 = replace(replace (@sAddress1_3,char(13)+char(10),''),char(10),'')
	select @sAddress1_4 = replace(replace (@sAddress1_4,char(13)+char(10),''),char(10),'')

	Select @nChar13 = case when charindex(char(13),left(@sStreet1_2,60))>0 then 1 else 0 end
	Select @sAddress2_1 = isnull(left(dbo.fn_SplitTextOnCarriageReturn(@sStreet1_2,1),60),'')
	Select @sStreet1_2 = isnull(right(@sStreet1_2, len(@sStreet1_2) - len(@sAddress2_1) - @nChar13),'')
	Select @nChar13 = case when charindex(char(13),left(@sStreet1_2,60))>0 then 1 else 0 end
	Select @sAddress2_2 = isnull(left(dbo.fn_SplitTextOnCarriageReturn(@sStreet1_2,1),60),'')
	Select @sStreet1_2 = isnull(right(@sStreet1_2, len(@sStreet1_2) - len(@sAddress2_2) - @nChar13),'')
	Select @nChar13 = case when charindex(char(13),left(@sStreet1_2,60))>0 then 1 else 0 end
	Select @sAddress2_3 = isnull(left(dbo.fn_SplitTextOnCarriageReturn(@sStreet1_2,1),60),'')
	Select @sStreet1_2 = isnull(right(@sStreet1_2, len(@sStreet1_2) - len(@sAddress2_3) - @nChar13),'')
	Select @sAddress2_4 = isnull(left(@sStreet1_2,60),'')

-- DJP 20-Sep-07 added following lines to strip unwanted carriage returns from address components
	select @sAddress2_1 = replace(replace (@sAddress2_1,char(13)+char(10),''),char(10),'')
	select @sAddress2_2 = replace(replace (@sAddress2_2,char(13)+char(10),''),char(10),'')
	select @sAddress2_3 = replace(replace (@sAddress2_3,char(13)+char(10),''),char(10),'')
	select @sAddress2_4 = replace(replace (@sAddress2_4,char(13)+char(10),''),char(10),'')

End

If  @nErrorCode = 0
and @bDataRetrievalStatus = 'I'
Begin
	-- Return normal result set 
	Select	Nationality 		as 'Nationality',
		FirstName		as 'FirstName',
		LastName		as 'LastName',
		Sex			as 'Sex',
		Inactive		as 'Inactive',
		Name			as 'Name',
		ClientName		as 'ClientName',
		SearchKey1		as 'SearchKey1',
		NameType		as 'NameType',
		FormalSalutation 	as 'FormalSalutation',
		Title			as 'Title',
		BillEmplUno		as 'BillEmplUno',
		ClientCode		as 'ClientCode',
		ClientUno		as 'ClientUno',	
		NameUno			as 'NameUno',	
		ClntTypeCode		as 'ClntTypeCode',
		CurrencyCode		as 'CurrencyCode',	
		Dept			as 'Dept',
		DisbClass		as 'DisbClass',
		DisbJurOvride		as 'DisbJurOvride',
		UsedAsFlag		as 'UsedAsFlag',
		HasSubs			as 'HasSubs',
		NotesText		as 'NotesText',
		Office			as 'Office',
		OpenDate		as 'OpenDate',
		OpenEmplUno		as 'OpenEmplUno',	
		ParentClntUno		as 'ParentClntUno',	
		Prof			as 'Prof',
		RespEmplUno		as 'RespEmplUno',
		StatusCode		as 'StatusCode',
		TimeClass		as 'TimeClass',
		TimeInc			as 'TimeInc',
		TimeJurOvride		as 'TimeJurOvride',
		AddrTypeCode1		as 'AddrTypeCode1',	
		@sAddress1_1		as 'Address1_1',
		@sAddress1_2		as 'Address1_2',
		@sAddress1_3		as 'Address1_3',
		@sAddress1_4		as 'Address1_4',
		City1			as 'City1',		
		CountryCode1		as 'CountryCode1',	
		Fax1			as 'Fax1',		
		PhoneExtNum1		as 'PhoneExtNum1',		
		Phone1			as 'Phone1',			
		PostCode1		as 'PostCode1',		
		StateCode1		as 'StateCode1',	
		DefaultAddress		as 'DefaultAddress',
		AddrTypeCode2		as 'AddrTypeCode2',	
		@sAddress2_1		as 'Address2_1',
		@sAddress2_2		as 'Address2_2',
		@sAddress2_3		as 'Address2_3',
		@sAddress2_4		as 'Address2_4',
		City2			as 'City2',		
		CountryCode2		as 'CountryCode2',	
		Fax2			as 'Fax2',		
		PhoneExtNum2		as 'PhoneExtNum2',		
		Phone2			as 'Phone2',			
		PostCode2		as 'PostCode2',		
		StateCode2		as 'StateCode2',	
		BillingInstText		as 'BillingInstText',				
		'I'			as 'DataRetrievalStatus',
		IntegrationType		as 'IntegrationType'
	from @tblName
End
Else 
-- Mandatory data missing or 
-- current name is not a client
If @nErrorCode = 0
and @bDataRetrievalStatus in ('M', 'N')
Begin
	Select	NULL		as 'Nationality',
		NULL		as 'FirstName',
		NULL		as 'LastName',
		NULL		as 'Sex',
		NULL		as 'Inactive',					
		NULL		as 'Name',
		NULL		as 'ClientName',
		NULL		as 'SearchKey1',
		NULL		as 'NameType',
		NULL		as 'FormalSalutation',
		NULL		as 'Title',
		NULL		as 'BillEmplUno',
		NULL		as 'ClientUno',	
		NULL		as 'NameUno',	
		NULL		as 'ClientCode',
		NULL		as 'ClntTypeCode',
		NULL		as 'CurrencyCode',	
		NULL		as 'Dept',
		NULL		as 'DisbClass',
		NULL		as 'DisbJurOvride',
		NULL		as 'UsedAsFlag',
		NULL		as 'HasSubs',
		NULL		as 'NotesText',
		NULL		as 'Office',
		NULL		as 'OpenDate',
		NULL		as 'OpenEmplUno',	
		NULL		as 'ParentClntUno',	
		NULL		as 'Prof',
		NULL		as 'RespEmplUno',
		NULL		as 'StatusCode',
		NULL		as 'TimeClass',
		NULL		as 'TimeInc',
		NULL		as 'TimeJurOvride',
		NULL		as 'AddrTypeCode1',	
		NULL		as 'Address1_1',
		NULL		as 'Address1_2',
		NULL		as 'Address1_3',
		NULL		as 'Address1_4',
		NULL		as 'City1',		
		NULL		as 'CountryCode1',	
		NULL		as 'Fax1',		
		NULL		as 'PhoneExtNum1',		
		NULL		as 'Phone1',			
		NULL		as 'PostCode1',		
		NULL		as 'StateCode1',	
		NULL		as 'DefaultAddress',
		NULL		as 'AddrTypeCode2',	
		NULL		as 'Address2_1',
		NULL		as 'Address2_2',
		NULL		as 'Address2_3',
		NULL		as 'Address2_4',
		NULL		as 'City2',		
		NULL		as 'CountryCode2',	
		NULL		as 'Fax2',		
		NULL		as 'PhoneExtNum2',		
		NULL		as 'Phone2',			
		NULL		as 'PostCode2',		
		NULL		as 'StateCode2',	
		NULL		as 'BillingInstText',	
		@bDataRetrievalStatus
				as 'DataRetrievalStatus'	
End


Return @nErrorCode
GO

Grant execute on dbo.ig_CMSGetGHNameDetails to public
GO

