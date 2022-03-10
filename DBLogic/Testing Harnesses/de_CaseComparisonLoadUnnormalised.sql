-----------------------------------------------------------------------------------------------------------------------------
-- Creation of de_CaseComparisonLoad
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[de_CaseComparisonLoad]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.de_CaseComparisonLoad.'
	Drop procedure [dbo].[de_CaseComparisonLoad]
End
Print '**** Creating Stored Procedure dbo.de_CaseComparisonLoad...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.de_CaseComparisonLoad
(
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@psTableNameQualifier	nvarchar(15), 	-- A qualifier appended to the table names to ensure that they are unique.
-- TO DO - remove case key- it should be in the XML
	@pnCaseKey		int		= null,
	@ptImportedCaseXML	ntext,
	@pnDebugFlag		tinyint		= 0 --0=off,1=trace execution,2=dump data
)
as
-- PROCEDURE:	de_CaseComparisonLoad
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the case comparison work tables with the contents of the XML.
--
--		Note: assumes that de_CaseComparisonCreate was called first to create the work tables.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Sep 2005	JEK	RFC1324	1	Procedure created
-- 20 Sep 2005	JEK	RFC1324	2	Extend processing.
-- 22 Sep 2005	JEK	RFC1324	3	Extend processing.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sSQLString2	nvarchar(4000)
declare	@sTimeStamp	nvarchar(24)

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @idoc 			int

declare @sSenderTable		nvarchar(50)
declare @sCaseTable		nvarchar(50)
declare @sOfficialNumberTable	nvarchar(50)
declare @sRelatedCaseTable	nvarchar(50)
declare @sEventTable		nvarchar(50)
declare @sCaseNameTable		nvarchar(50)

declare @nOfficialNumbersRows	int
declare @sApplicationNumber	nvarchar(100)
declare @sPublicationNumber	nvarchar(100)
declare @sRegistrationNumber	nvarchar(100)
declare @sConfirmationNumber	nvarchar(100)
declare @sCustomerNumber	nvarchar(100)

declare @dtApplicationDate	datetime
declare @dtPublicationDate	datetime
declare @dtRegistrationDate	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @sSenderTable = 'CC_SENDER' + @psTableNameQualifier
Set @sCaseTable = 'CC_CASE' + @psTableNameQualifier
Set @sOfficialNumberTable = 'CC_OFFICIALNUMBER' + @psTableNameQualifier
Set @sRelatedCaseTable = 'CC_RELATEDCASE' + @psTableNameQualifier
Set @sEventTable = 'CC_CASEEVENT' + @psTableNameQualifier
Set @sCaseNameTable = 'CC_CASENAME' + @psTableNameQualifier

If  @pnDebugFlag>0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),113)
	RAISERROR ('%s de_CaseComparisonLoad-Commence Processing',0,1,@sTimeStamp ) with NOWAIT
End

-- Load imported data into temp tables
-- TO DO: This is a temporary implementation.  Needs to be replaced with either
-- a style sheet and bulk XML load, or moved to a different procedure.
-- Should that process create the whole temp table definition, or just the loaded values?
If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),113)
		RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sCaseTable ) with NOWAIT
	End
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptImportedCaseXML

	Set @sSQLString = 	
	"Insert into "+@sCaseTable+" (EX_CASEKEY, IMP_CASEREFERENCE, IMP_SHORTTITLE,"+CHAR(10)+
	"				IMP_CASESTATUSDESCRIPTION, IMP_CASESTATUSDATE,"+CHAR(10)+
	"				IMP_IPODELAYDAYS,IMP_APPLICANTDELAYDAYS,IMP_TOTALADJUSTMENTDAYS)"+CHAR(10)
	Set @sSQLString2 =
	"Select @pnCaseKey, CaseReference, ShortTitle, CaseStatus, CaseStatusDate,"+CHAR(10)+
	"	IpoDelayDays,ApplicantDelayDays,TotalAdjustmentDays"+CHAR(10)+
	"from	OPENXML (@idoc, '//case-set/case/case-information',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseReference		nvarchar(30)	'receiver-case-reference/text()',"+CHAR(10)+
	"	      ShortTitle		nvarchar(254)	'short-title/text()',"+CHAR(10)+
	"	      CaseStatus		nvarchar(100)	'case-status/description/text()',"+CHAR(10)+
	"	      CaseStatusDate		datetime	'case-status/date/text()',"+CHAR(10)+
	"	      IpoDelayDays		int		'term-adjustment/ipo-delay-days/text()',"+CHAR(10)+
	"	      ApplicantDelayDays	int		'term-adjustment/applicant-delay-days/text()',"+CHAR(10)+
	"	      TotalAdjustmentDays	int		'term-adjustment/total-adjustment-days/text()'"+CHAR(10)+
    	"	     )"

	Set @sSQLString = @sSQLString+@sSQLString2

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @pnCaseKey			int',
				  @idoc				= @idoc,
				  @pnCaseKey			= @pnCaseKey

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),113)
		RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sOfficialNumberTable ) with NOWAIT
	End

	-- Explicit Official Numbers
	If @nErrorCode = 0
	Begin
		Set @sSQLString =
		"Select @sApplicationNumber = ApplicationNumber,"+CHAR(10)+
		"	@dtApplicationDate = ApplicationDate,"+CHAR(10)+
		"	@sPublicationNumber = PublicationNumber,"+CHAR(10)+
		"	@dtPublicationDate = PublicationDate,"+CHAR(10)+
		"	@sRegistrationNumber = RegistrationNumber,"+CHAR(10)+
		"	@dtRegistrationDate = RegistrationDate,"+CHAR(10)+	
		"	@sConfirmationNumber = ConfirmationNumber,"+CHAR(10)+
		"	@sCustomerNumber = CustomerNumber"+CHAR(10)+
		"from	OPENXML (@idoc, '//case-set/case/case-information',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      ApplicationNumber		nvarchar(100)	'application-reference/document-id/doc-number/text()',"+CHAR(10)+
		"	      ApplicationDate		datetime	'application-reference/document-id/date/text()',"+CHAR(10)+
		"	      PublicationNumber		nvarchar(100)	'publication-reference/document-id/doc-number/text()',"+CHAR(10)+
		"	      PublicationDate		datetime	'publication-reference/document-id/date/text()',"+CHAR(10)+
		"	      RegistrationNumber	nvarchar(100)	'grant-reference/document-id/doc-number/text()',"+CHAR(10)+
		"	      RegistrationDate		datetime	'grant-reference/document-id/date/text()',"+CHAR(10)+
		"	      ConfirmationNumber	nvarchar(100)	'confirmation-number/text()',"+CHAR(10)+
		"	      CustomerNumber		nvarchar(100)	'customer-number/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int,
					  @sApplicationNumber		nvarchar(100)	output,
					  @dtApplicationDate		datetime	output,
					  @sPublicationNumber		nvarchar(100)	output,
					  @dtPublicationDate		datetime	output,
					  @sRegistrationNumber		nvarchar(100)	output,
					  @dtRegistrationDate		datetime	output,
					  @sConfirmationNumber		nvarchar(100)	output,
					  @sCustomerNumber		nvarchar(100)	output',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey,
					  @sApplicationNumber		= @sApplicationNumber	output,
					  @dtApplicationDate		= @dtApplicationDate	output,
					  @sPublicationNumber		= @sPublicationNumber	output,
					  @dtPublicationDate		= @dtPublicationDate	output,
					  @sRegistrationNumber		= @sRegistrationNumber	output,
					  @dtRegistrationDate		= @dtRegistrationDate	output,
					  @sConfirmationNumber		= @sConfirmationNumber	output,
					  @sCustomerNumber		= @sCustomerNumber	output

		Set @nOfficialNumbersRows = 0

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			insert into "+@sOfficialNumberTable+" (EX_CASEKEY, IMP_NUMBERTYPECODE, IMP_NUMBERTYPEENCODING, IMP_OFFICIALNUMBER,IMP_EVENTDATE)
			select 	@pnCaseKey, @sNumberType, 'CPAINPRO',@sNumber, @dtDate
			where 	@sNumber is not null
			or	@dtDate is not null"

			exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int,
				  @sNumberType			nvarchar(3),
				  @sNumber			nvarchar(30),
				  @dtDate			datetime',
				  @pnCaseKey			= @pnCaseKey,
				  @sNumberType			= 'A',
				  @sNumber			= @sApplicationNumber,
				  @dtDate			= @dtApplicationDate

			Set @nErrorCode = @@ERROR
		End

		If @nErrorCode = 0
		Begin
			exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int,
				  @sNumberType			nvarchar(3),
				  @sNumber			nvarchar(30),
				  @dtDate			datetime',
				  @pnCaseKey			= @pnCaseKey,
				  @sNumberType			= 'P',
				  @sNumber			= @sPublicationNumber,
				  @dtDate			= @dtPublicationDate

			Set @nErrorCode = @@ERROR

		End

		If @nErrorCode = 0
		Begin
			exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int,
				  @sNumberType			nvarchar(3),
				  @sNumber			nvarchar(30),
				  @dtDate			datetime',
				  @pnCaseKey			= @pnCaseKey,
				  @sNumberType			= 'R',
				  @sNumber			= @sRegistrationNumber,
				  @dtDate			= @dtRegistrationDate

			Set @nErrorCode = @@ERROR
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			insert into "+@sOfficialNumberTable+" (EX_CASEKEY, IMP_NUMBERTYPEDESCRIPTION, IMP_NUMBERTYPEENCODING, IMP_OFFICIALNUMBER,IMP_EVENTDATE)
			select 	@pnCaseKey, @sNumberType, 'CPAINPRO',@sNumber, @dtDate
			where 	@sNumber is not null
			or	@dtDate is not null"

			exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int,
				  @sNumberType			nvarchar(100),
				  @sNumber			nvarchar(30),
				  @dtDate			datetime',
				  @pnCaseKey			= @pnCaseKey,
				  @sNumberType			= 'Confirmation Number',
				  @sNumber			= @sConfirmationNumber,
				  @dtDate			= null

		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			insert into "+@sOfficialNumberTable+" (EX_CASEKEY, IMP_NUMBERTYPEDESCRIPTION, IMP_NUMBERTYPEENCODING, IMP_OFFICIALNUMBER,IMP_EVENTDATE)
			select 	@pnCaseKey, @sNumberType, 'CPAINPRO',@sNumber, @dtDate
			where 	@sNumber is not null
			or	@dtDate is not null"

			exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int,
				  @sNumberType			nvarchar(100),
				  @sNumber			nvarchar(30),
				  @dtDate			datetime',
				  @pnCaseKey			= @pnCaseKey,
				  @sNumberType			= 'Customer Number',
				  @sNumber			= @sCustomerNumber,
				  @dtDate			= null
		End

	End

	-- General Official Numbers
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 	
		"Insert into "+@sOfficialNumberTable+" (EX_CASEKEY, IMP_NUMBERTYPEDESCRIPTION, IMP_OFFICIALNUMBER)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select @pnCaseKey, NumberTypeDescription, OfficialNumber"+CHAR(10)+
		"from	OPENXML (@idoc, '//case-set/case/case-information/reference-number-set/reference-number',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      NumberTypeDescription	nvarchar(100)	'number-description/text()',"+CHAR(10)+
		"	      OfficialNumber		nvarchar(100)	'number/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey
	End

	-- Priority claims
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),113)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s - priority claims',0,1,@sTimeStamp,@sRelatedCaseTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sRelatedCaseTable+" (EX_CASEKEY, IMP_OFFICIALNUMBER, IMP_EVENTDATE, IMP_COUNTRYCODE, IMP_COUNTRYNAME, IMP_RELATIONSHIPCODE, IMP_RELATIONSHIPENCODING)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select @pnCaseKey, OfficialNumber, EventDate, CountryCode, CountryName, 'BAS', 'CPAINPRO'"+CHAR(10)+
		"from	OPENXML (@idoc, '//case-set/case/case-information/priority-claim-set/priority-claim/document-id',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      OfficialNumber		nvarchar(100)	'doc-number/text()',"+CHAR(10)+
		"	      EventDate			datetime	'date/text()',"+CHAR(10)+
		"	      CountryCode		nvarchar(30)	'country-code/text()',"+CHAR(10)+
		"	      CountryName		nvarchar(100)	'country-name/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey
	End

	-- Parent cases
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),113)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s - parents',0,1,@sTimeStamp,@sRelatedCaseTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sRelatedCaseTable+" 
			(EX_CASEKEY, IMP_RELATIONSHIPDESCRIPTION, IMP_OFFICIALNUMBER, 
			IMP_EVENTDATE, IMP_COUNTRYCODE, IMP_COUNTRYNAME, IMP_PARENTSTATUS, IMP_REGISTRATIONNUMBER)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select @pnCaseKey, RelationshipDescription, OfficialNumber,"+CHAR(10)+
		"	EventDate, CountryCode, CountryName, ParentStatus, RegistrationNumber"+CHAR(10)+
		"from	OPENXML (@idoc, '//case-set/case/case-information/parent-set/parent-relation/parent-doc',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      RelationshipDescription	nvarchar(100)	'../relationship-description/text()',"+CHAR(10)+
		"	      OfficialNumber		nvarchar(100)	'document-id/doc-number/text()',"+CHAR(10)+
		"	      EventDate			datetime	'document-id/date/text()',"+CHAR(10)+
		"	      CountryCode		nvarchar(30)	'document-id/country-code/text()',"+CHAR(10)+
		"	      CountryName		nvarchar(100)	'document-id/country-name/text()',"+CHAR(10)+
		"	      ParentStatus		nvarchar(100)	'parent-status/text()',"+CHAR(10)+
		"	      RegistrationNumber	nvarchar(100)	'parent-grant-document/document-id/doc-number/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey
	End

	-- Events
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),113)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sEventTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sEventTable+" (EX_CASEKEY, IMP_EVENTDESCRIPTION, IMP_EVENTDATE)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select @pnCaseKey, EventDescription, EventDate"+CHAR(10)+
		"from	OPENXML (@idoc, '//case-set/case/occurred-event-set/occurred-event',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      EventDescription		nvarchar(254)	'event-description/text()',"+CHAR(10)+
		"	      EventDate			datetime	'date/text()'"+CHAR(10)+
	    	"	     )
		ORDER BY EventDescription"
	
		Set @sSQLString = @sSQLString+@sSQLString2
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey
	End

	-- Sender
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),113)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sSenderTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sSenderTable+" (IMP_SYSTEMCODE)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select SystemCode"+CHAR(10)+
		"from	OPENXML (@idoc, '//sender-details',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      SystemCode		nvarchar(20)	'source-system/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					  @idoc				= @idoc
	End

	-- CaseName - Inventor
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),113)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sCaseNameTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sCaseNameTable+" (EX_CASEKEY,IMP_CASESEQUENCE,IMP_NAMETYPECODE,IMP_NAMETYPEENCODING,
			IMP_NAME,IMP_FIRSTNAME,IMP_ISINDIVIDUAL,
			IMP_STREET,IMP_CITY,IMP_STATECODE,IMP_STATENAME,IMP_POSTCODE,
			IMP_COUNTRYCODE,IMP_COUNTRYNAME,IMP_PHONE,IMP_FAX,IMP_EMAIL)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select @pnCaseKey,1, 'J', 'CPAINPRO', isnull(Name, LastName), FirstName, case when FirstName is not null then 1 else 0 end, "+CHAR(10)+
		"	Street, City, StateCode, State, Postcode, CountryCode, Country, Phone, Fax, Email"+CHAR(10)+
		"from	OPENXML (@idoc, '//case-set/case/case-information/party-set/inventor-set/inventor/addressbook',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      Name			nvarchar(500)	'name/name/text()',"+CHAR(10)+
		"	      LastName			nvarchar(500)	'name/last-name/text()',"+CHAR(10)+
		"	      FirstName			nvarchar(254)	'name/first-name/text()',"+CHAR(10)+
		"	      Street			nvarchar(500)	'address/street/text()',"+CHAR(10)+
		"	      City			nvarchar(30)	'address/city/text()',"+CHAR(10)+
		"	      StateCode			nvarchar(30)	'address/state-code/text()',"+CHAR(10)+
		"	      State			nvarchar(40)	'address/state/text()',"+CHAR(10)+
		"	      Postcode			nvarchar(10)	'address/postcode/text()',"+CHAR(10)+
		"	      CountryCode		nvarchar(50)	'address/country-code/text()',"+CHAR(10)+
		"	      Country			nvarchar(100)	'address/country/text()',"+CHAR(10)+
		"	      Phone			nvarchar(50)	'phone/text()',"+CHAR(10)+
		"	      Fax			nvarchar(50)	'fax/text()',"+CHAR(10)+
		"	      Email			nvarchar(50)	'email/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey
	End

	-- CaseName - Examiner
	If @nErrorCode = 0
	Begin

		Set @sSQLString = 	
		"Insert into "+@sCaseNameTable+" (EX_CASEKEY,IMP_CASESEQUENCE,IMP_NAMETYPECODE,IMP_NAMETYPEENCODING,
			IMP_NAME,IMP_FIRSTNAME,IMP_ISINDIVIDUAL)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select @pnCaseKey,1, 'EX', 'CPAINPRO', isnull(Name, LastName), FirstName, case when FirstName is not null then 1 else 0 end"+CHAR(10)+
		"from	OPENXML (@idoc, '//case-set/case/case-information/party-set/examiner-name',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      Name			nvarchar(500)	'name/text()',"+CHAR(10)+
		"	      LastName			nvarchar(500)	'last-name/text()',"+CHAR(10)+
		"	      FirstName			nvarchar(254)	'first-name/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey
	End

	-- Classifications: - this code only handles 1 classification
	If @nErrorCode = 0
	Begin

		Set @sSQLString = 	
		"update "+@sCaseTable+" set IMP_LOCALCLASSES = case when Subclass is null then Class else Class+'.'+Subclass end"+CHAR(10)
	
		Set @sSQLString2 =
		"from	OPENXML (@idoc, '//case-set/case/case-information/classification-set/classification',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      Class			nvarchar(10)	'class/text()',"+CHAR(10)+
		"	      Subclass			nvarchar(10)	'subclass/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @pnCaseKey			int',
					  @idoc				= @idoc,
					  @pnCaseKey			= @pnCaseKey
	End

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

End

-- Dump tables for debugging
If  @nErrorCode = 0
and @pnDebugFlag>1
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),113)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sSenderTable+':'
	Set @sSQLString = "select * from "+@sSenderTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),113)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sCaseTable+':'
	Set @sSQLString = "select * from "+@sCaseTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),113)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sOfficialNumberTable+':'
	Set @sSQLString = "select * from "+@sOfficialNumberTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),113)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sRelatedCaseTable+':'
	Set @sSQLString = "select * from "+@sRelatedCaseTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),113)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sEventTable+':'
	Set @sSQLString = "select * from "+@sEventTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),113)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sCaseNameTable+':'
	Set @sSQLString = "select * from "+@sCaseNameTable
	exec sp_executesql @sSQLString

End

Return @nErrorCode
GO

Grant execute on dbo.de_CaseComparisonLoad to public
GO
