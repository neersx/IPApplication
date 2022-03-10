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
	@psNamespace		nvarchar(254)	= null, -- XML Namespace
	@ptImportedCaseXML	ntext,
	@pnDebugFlag		tinyint		= 0 --0=off,1=trace execution,2=dump data
)
as
-- PROCEDURE:	de_CaseComparisonLoad
-- VERSION:	10
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
-- 06 Oct 2005	TM	RFC3005	4	Adjust the logic to understand the normalised XML.
-- 10 Oct 2005	TM	RFC3120	5	Add new SequenceNumber attribute to the Related Cases.
-- 17 Aug 2006	JEK	RFC4241	6	Add international classes.
-- 01 Jun 2007	LP	RFC5103	7	Do not insert duplicate events from imported XML.
-- 13 Dec 2011	JC	RFC6271	8	Add Namespace as parameter
-- 07 Apr 2016  MS      R52206  9       Added quotename before using table variables to avoid sql injection
-- 14 Nov 2018  AV  75198/DR-45358	10   Date conversion errors when creating cases and opening names in Chinese DB

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

-- Initialise variables
Set @nErrorCode = 0
Set @sSenderTable = quotename('CC_SENDER' + @psTableNameQualifier, '')
Set @sCaseTable = quotename('CC_CASE' + @psTableNameQualifier, '')
Set @sOfficialNumberTable = quotename('CC_OFFICIALNUMBER' + @psTableNameQualifier, '')
Set @sRelatedCaseTable = quotename('CC_RELATEDCASE' + @psTableNameQualifier, '')
Set @sEventTable = quotename('CC_CASEEVENT' + @psTableNameQualifier, '')
Set @sCaseNameTable = quotename('CC_CASENAME' + @psTableNameQualifier, '')

If  @pnDebugFlag>0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s de_CaseComparisonLoad-Commence Processing',0,1,@sTimeStamp ) with NOWAIT
End

-- Load imported data into temp tables
If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sCaseTable ) with NOWAIT
	End
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML

	if @psNamespace is NULL
	Begin
		Set @psNamespace = 'http://www.cpasoftwaresolutions.com/Schemas/DataExchange'
	End		
	Set @psNamespace = '<CaseExchangeNormalised xmlns:cpa = "' + quotename(@psNamespace, '') + '"/>'
        exec sp_xml_preparedocument	@idoc OUTPUT, @ptImportedCaseXML, @psNamespace

	Set @sSQLString = 	
	"Insert into "+@sCaseTable+" (EX_CASEKEY, IMP_CASESEQUENCE, IMP_CASEREFERENCE, IMP_SHORTTITLE,"+CHAR(10)+
	"				IMP_CASESTATUSDESCRIPTION, IMP_CASESTATUSDATE, IMP_LOCALCLASSES, IMP_INTCLASSES)"+CHAR(10)

	Set @sSQLString2 =
	"Select CaseKey, ImportedCaseID, CaseReference, ShortTitle, CaseStatus, CaseStatusDate, LocalClasses, IntClasses"+CHAR(10)+
	"from	OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:ImportedCaseSet/cpa:ImportedCase',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseKey			int		'cpa:CaseKey/text()',"+CHAR(10)+
	"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
	"	      CaseReference		nvarchar(30)	'cpa:CaseReference/text()',"+CHAR(10)+
	"	      ShortTitle		nvarchar(254)	'cpa:ShortTitle/text()',"+CHAR(10)+
	"	      CaseStatus		nvarchar(100)	'cpa:CaseStatusDescription/text()',"+CHAR(10)+
	"	      CaseStatusDate		datetime	'cpa:CaseStatusDate/text()',"+CHAR(10)+
	"	      LocalClasses		nvarchar(254)	'cpa:LocalClasses/text()',"+CHAR(10)+
	"	      IntClasses		nvarchar(254)	'cpa:IntClasses/text()'"+CHAR(10)+
	"	     )"

	Set @sSQLString = @sSQLString+@sSQLString2

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int',
				  @idoc				= @idoc

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sOfficialNumberTable ) with NOWAIT
	End	

	-- Term Adjustment
	If @nErrorCode = 0
	Begin	
		Set @sSQLString = 	
		"Update "+@sCaseTable+CHAR(10)+
		"   set	IMP_IPODELAYDAYS = T1.IpoDelayDays,"+CHAR(10)+
		"	IMP_APPLICANTDELAYDAYS = T1.ApplicantDelayDays,"+CHAR(10)+
		"	IMP_TOTALADJUSTMENTDAYS = T1.TotalAdjustmentDays"+CHAR(10)

		Set @sSQLString2 =
		"from	OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:TermAdjustmentSet/cpa:TermAdjustment',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      IpoDelayDays		int		'cpa:IpoDelayDays/text()',"+CHAR(10)+
		"	      ApplicantDelayDays	int		'cpa:ApplicantDelayDays/text()',"+CHAR(10)+
		"	      TotalAdjustmentDays	int		'cpa:TotalAdjustmentDays/text()'"+CHAR(10)+
	    	"	     ) T1"+CHAR(10)+
		"join "+@sCaseTable+" T2 "+CHAR(10)+" on (T2.IMP_CASESEQUENCE = T1.ImportedCaseID)"
	
		Set @sSQLString = @sSQLString+@sSQLString2
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					  @idoc				= @idoc
	End
	
	-- Official Numbers
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 	
		"Insert into "+@sOfficialNumberTable+" (EX_CASEKEY, IMP_CASESEQUENCE, IMP_NUMBERTYPECODE,"+CHAR(10)+
		"					IMP_NUMBERTYPEDESCRIPTION, IMP_NUMBERTYPEENCODING,"+CHAR(10)+
		"					IMP_OFFICIALNUMBER, IMP_EVENTDATE)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select T2.CaseKey, T1.ImportedCaseID, T1.NumberTypeCode, T1.NumberTypeDescription, T1.Encoding,"+CHAR(10)+
		"       T1.OfficialNumber, T1.EventDate"+CHAR(10)+
		"from	OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:OfficialNumberSet/cpa:OfficialNumber',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+		
		"	      NumberTypeCode		nvarchar(50)	'cpa:NumberTypeCode/text()',"+CHAR(10)+
		"	      NumberTypeDescription	nvarchar(100)	'cpa:NumberTypeDescription/text()',"+CHAR(10)+
		"	      Encoding			nvarchar(50)	'cpa:NumberTypeCode/@encoding/text()',"+CHAR(10)+
		"	      OfficialNumber		nvarchar(100)	'cpa:OfficialNumber/text()',"+CHAR(10)+
		"	      EventDate			datetime	'cpa:EventDate/text()'"+CHAR(10)+
	    	"	     ) T1"+CHAR(10)+
		"join    OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:ImportedCaseSet/cpa:ImportedCase',2)"+CHAR(10)+
		"	 WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      CaseKey			int		'cpa:CaseKey/text()'"+CHAR(10)+
	    	"	     ) T2 on (T2.ImportedCaseID = T1.ImportedCaseID)"
	
		Set @sSQLString = @sSQLString+@sSQLString2

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					  @idoc				= @idoc
	End

	-- Parent cases
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s - parents',0,1,@sTimeStamp,@sRelatedCaseTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sRelatedCaseTable+"    (EX_CASEKEY, IMP_SEQUENCENUMBER, IMP_CASESEQUENCE, IMP_RELATIONSHIPCODE,"+CHAR(10)+
		"					IMP_RELATIONSHIPDESCRIPTION, IMP_RELATIONSHIPENCODING,"+CHAR(10)+
		"					IMP_COUNTRYCODE, IMP_COUNTRYNAME, IMP_OFFICIALNUMBER,"+CHAR(10)+
		"					IMP_EVENTDATE, IMP_PARENTSTATUS, IMP_REGISTRATIONNUMBER)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select T2.CaseKey, T1.SequenceNumber, T1.ImportedCaseID, T1.RelationshipCode, T1.RelationshipDescription,"+CHAR(10)+
		"	T1.Encoding, T1.CountryCode, T1.CountryName, T1.OfficialNumber, T1.EventDate, T1.RelatedCaseStatus,"+CHAR(10)+
		"	T1.RegistrationNumber"+CHAR(10)+
		"from	OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:RelatedCaseSet/cpa:RelatedCase',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      SequenceNumber		int		'@SequenceNumber',"+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      RelationshipCode		nvarchar(50)	'cpa:RelationshipCode/text()',"+CHAR(10)+
		"	      RelationshipDescription	nvarchar(100)	'cpa:RelationshipDescription/text()',"+CHAR(10)+
		"	      Encoding			nvarchar(50)	'cpa:RelationshipCode/@encoding/text()',"+CHAR(10)+
		"	      CountryCode		nvarchar(50)	'cpa:CountryCode/text()',"+CHAR(10)+
		"	      CountryName		nvarchar(100)	'cpa:CountryName/text()',"+CHAR(10)+
		"	      OfficialNumber		nvarchar(100)	'cpa:OfficialNumber/text()',"+CHAR(10)+
		"	      EventDate			datetime	'cpa:EventDate/text()',"+CHAR(10)+
		"	      RelatedCaseStatus		nvarchar(100)	'cpa:RelatedCaseStatus/text()',"+CHAR(10)+
		"	      RegistrationNumber	nvarchar(100)	'cpa:RegistrationNumber/text()'"+CHAR(10)+		
	    	"	     ) T1"+CHAR(10)+
		"join    OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:ImportedCaseSet/cpa:ImportedCase',2)"+CHAR(10)+
		"	 WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      CaseKey			int		'cpa:CaseKey/text()'"+CHAR(10)+
	    	"	     ) T2 on (T2.ImportedCaseID = T1.ImportedCaseID)"
	
		Set @sSQLString = @sSQLString+@sSQLString2

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					  @idoc				= @idoc
	End	

	-- Events
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sEventTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sEventTable+" (EX_CASEKEY, IMP_CASESEQUENCE, IMP_EVENTDESCRIPTION, IMP_EVENTDATE)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select DISTINCT T2.CaseKey, T1.ImportedCaseID, T1.EventDescription, T1.EventDate"+CHAR(10)+
		"from	OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:CaseEventSet/cpa:CaseEvent',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      EventDescription		nvarchar(254)	'cpa:EventDescription/text()',"+CHAR(10)+
		"	      EventDate			datetime	'cpa:EventDate/text()'"+CHAR(10)+
	    	"	     ) T1"+CHAR(10)+
		"join    OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:ImportedCaseSet/cpa:ImportedCase',2)"+CHAR(10)+
		"	 WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      CaseKey			int		'cpa:CaseKey/text()'"+CHAR(10)+
	    	"	     ) T2 on (T2.ImportedCaseID = T1.ImportedCaseID)"+CHAR(10)+
		"ORDER BY EventDescription, EventDate, T1.ImportedCaseID, T2.CaseKey"
	
		Set @sSQLString = @sSQLString+@sSQLString2
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					  @idoc				= @idoc
	End

	-- Sender
	If @nErrorCode=0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sSenderTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sSenderTable+" (IMP_SYSTEMCODE)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select SourceSystem"+CHAR(10)+
		"from	OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:SenderDetails',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      SourceSystem		nvarchar(20)	'cpa:SourceSystem/text()'"+CHAR(10)+
	    	"	     )"
	
		Set @sSQLString = @sSQLString+@sSQLString2

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					  @idoc				= @idoc
	End

	-- CaseName 
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparisonLoad-Load %s',0,1,@sTimeStamp,@sCaseNameTable ) with NOWAIT
		End

		Set @sSQLString = 	
		"Insert into "+@sCaseNameTable+"(EX_CASEKEY,IMP_CASESEQUENCE, IMP_NAMETYPECODE,"+CHAR(10)+
		"				IMP_NAMETYPEDESCRIPTION, IMP_NAMETYPEENCODING,"+CHAR(10)+
		"				IMP_NAME, IMP_FIRSTNAME, IMP_ISINDIVIDUAL,"+CHAR(10)+
		"				IMP_STREET, IMP_CITY, IMP_STATECODE, IMP_STATENAME,"+CHAR(10)+
		" 				IMP_POSTCODE, IMP_COUNTRYCODE, IMP_COUNTRYNAME, IMP_PHONE,"+CHAR(10)+
		"				IMP_FAX, IMP_EMAIL)"+CHAR(10)
	
		Set @sSQLString2 =
		"Select T2.CaseKey, T1.ImportedCaseID, T1.NameTypeCode, T1.NameTypeDescription, T1.Encoding, T1.Name,"+CHAR(10)+
		"	T1.FirstName, T1.IsIndividual, T1.Street, T1.City, T1.StateCode, T1.StateName, T1.Postcode,"+CHAR(10)+
		"	T1.CountryCode, T1.CountryName, T1.Phone, T1.Fax, T1.Email"+CHAR(10)+
		"from	OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:CaseNameSet/cpa:CaseName',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      NameTypeCode		nvarchar(3)	'cpa:NameTypeCode/text()',"+CHAR(10)+
		"	      NameTypeDescription	nvarchar(100)	'cpa:NameTypeDescription/text()',"+CHAR(10)+
		"	      Encoding			nvarchar(50)	'cpa:NameTypeCode/@encoding/text()',"+CHAR(10)+
		"	      Name			nvarchar(500)	'cpa:Name/text()',"+CHAR(10)+
		"	      FirstName			nvarchar(254)	'cpa:FirstName/text()',"+CHAR(10)+
		"	      IsIndividual		bit		'cpa:IsIndividual/text()',"+char(10)+
		"	      Street			nvarchar(500)	'cpa:Street/text()',"+CHAR(10)+
		"	      City			nvarchar(30)	'cpa:City/text()',"+CHAR(10)+
		"	      StateCode			nvarchar(30)	'cpa:StateCode/text()',"+CHAR(10)+
		"	      StateName			nvarchar(30)	'cpa:StateName/text()',"+CHAR(10)+
		"	      Postcode			nvarchar(10)	'cpa:Postcode/text()',"+CHAR(10)+
		"	      CountryCode		nvarchar(50)	'cpa:CountryCode/text()',"+CHAR(10)+
		"	      CountryName		nvarchar(100)	'cpa:CountryName/text()',"+CHAR(10)+
		"	      Phone			nvarchar(50)	'cpa:Phone/text()',"+CHAR(10)+
		"	      Fax			nvarchar(50)	'cpa:Fax/text()',"+CHAR(10)+
		"	      Email			nvarchar(50)	'cpa:Email/text()'"+CHAR(10)+
	    	"	     ) T1"+CHAR(10)+
		"join    OPENXML (@idoc, '//cpa:CaseExchangeNormalised/cpa:ImportedCaseSet/cpa:ImportedCase',2)"+CHAR(10)+
		"	 WITH ("+CHAR(10)+
		"	      ImportedCaseID		int		'cpa:ImportedCaseID/text()',"+CHAR(10)+
		"	      CaseKey			int		'cpa:CaseKey/text()'"+CHAR(10)+
	    	"	     ) T2 on (T2.ImportedCaseID = T1.ImportedCaseID)"
	
		Set @sSQLString = @sSQLString+@sSQLString2

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int',
					  @idoc				= @idoc
	End	

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

End

-- Dump tables for debugging
If  @nErrorCode = 0
and @pnDebugFlag>1
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sSenderTable+':'
	Set @sSQLString = "select * from "+@sSenderTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sCaseTable+':'
	Set @sSQLString = "select * from "+@sCaseTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sOfficialNumberTable+':'
	Set @sSQLString = "select * from "+@sOfficialNumberTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sRelatedCaseTable+':'
	Set @sSQLString = "select * from "+@sRelatedCaseTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sEventTable+':'
	Set @sSQLString = "select * from "+@sEventTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparisonLoad-'+'Contents of '+@sCaseNameTable+':'
	Set @sSQLString = "select * from "+@sCaseNameTable
	exec sp_executesql @sSQLString

End

Return @nErrorCode
GO

Grant execute on dbo.de_CaseComparisonLoad to public
GO
