DECLARE @RC int
DECLARE @pnUserIdentityId int
DECLARE @psCulture nvarchar(10)
DECLARE @pbCalledFromCentura bit
DECLARE @pnCaseKey int
DECLARE @pnDebugFlag tinyint
DECLARE @psTableNameQualifier nvarchar(15)

SELECT @pnUserIdentityId = 5
SELECT @psCulture = 'en'
SELECT @pbCalledFromCentura = 0
SELECT @pnCaseKey = -486
SELECT @psTableNameQualifier = NULL
Set @pnDebugFlag = 1 -- 0-None, 1-Trace, 2-Dump tables

EXEC @RC = [dbo].[de_CaseComparisonCreate] @psTableNameQualifier OUTPUT , @pnUserIdentityId
DECLARE @PrnLine nvarchar(4000)
PRINT 'Stored Procedure: IPNet.dbo.de_CaseComparisonCreate'
SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
PRINT @PrnLine
PRINT '	Output Parameter(s): '
SELECT @PrnLine = '		@psTableNameQualifier = ' + isnull( CONVERT(nvarchar, @psTableNameQualifier), '<NULL>' )
PRINT @PrnLine

If @RC = 0
Begin
	EXEC @RC = [dbo].[de_CaseComparisonLoad] @pnUserIdentityId, @pbCalledFromCentura, @psTableNameQualifier, @pnDebugFlag=@pnDebugFlag,@ptImportedCaseXML= 
'<cpa:CaseExchangeNormalised schemaVersion="1.0" xmlns:cpa="http://www.cpasoftwaresolutions.com/Schemas/DataExchange"><cpa:SenderDetails><cpa:SourceSystem>USPTO/PAIR</cpa:SourceSystem></cpa:SenderDetails><cpa:ImportedCaseSet><cpa:ImportedCase><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:CaseReference>27866/36004A</cpa:CaseReference><cpa:ShortTitle>Cyclic-AMP-specific phosphodiesterase inhibitors</cpa:ShortTitle><cpa:PropertyTypeDescription></cpa:PropertyTypeDescription><cpa:CaseStatusDescription>Patented Case</cpa:CaseStatusDescription><cpa:CaseStatusDate>2001-10-18</cpa:CaseStatusDate><cpa:LocalClasses>514.370</cpa:LocalClasses><cpa:IntClasses>42,024</cpa:IntClasses><cpa:CaseKey>-486</cpa:CaseKey></cpa:ImportedCase></cpa:ImportedCaseSet><cpa:OfficialNumberSet><cpa:OfficialNumber><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:NumberTypeCode encoding="CPAINPRO">A</cpa:NumberTypeCode><cpa:OfficialNumber>09/723,091</cpa:OfficialNumber><cpa:NumberTypeDescription>Application Number</cpa:NumberTypeDescription><cpa:EventDate>2000-11-27</cpa:EventDate></cpa:OfficialNumber><cpa:OfficialNumber><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:NumberTypeCode encoding="CPAINPRO">R</cpa:NumberTypeCode><cpa:OfficialNumber>6,313,156</cpa:OfficialNumber><cpa:NumberTypeDescription>Patent Number</cpa:NumberTypeDescription><cpa:EventDate>2001-11-06</cpa:EventDate></cpa:OfficialNumber><cpa:OfficialNumber><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:NumberTypeDescription>Confirmation Number</cpa:NumberTypeDescription><cpa:OfficialNumber>4265</cpa:OfficialNumber></cpa:OfficialNumber><cpa:OfficialNumber><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:NumberTypeDescription>Group Art Unit</cpa:NumberTypeDescription><cpa:OfficialNumber>1626</cpa:OfficialNumber></cpa:OfficialNumber></cpa:OfficialNumberSet><cpa:CaseTextSet></cpa:CaseTextSet><cpa:TermAdjustmentSet><cpa:TermAdjustment><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:IpoDelayDays>0</cpa:IpoDelayDays><cpa:ApplicantDelayDays>0</cpa:ApplicantDelayDays><cpa:TotalAdjustmentDays>0</cpa:TotalAdjustmentDays></cpa:TermAdjustment></cpa:TermAdjustmentSet><cpa:RelatedCaseSet><cpa:RelatedCase SequenceNumber="2"><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:RelationshipDescription>This application Claims Priority from Provisional Application</cpa:RelationshipDescription><cpa:RelatedCaseStatus>Expired</cpa:RelatedCaseStatus><cpa:OfficialNumber>60/171,950</cpa:OfficialNumber><cpa:CountryName></cpa:CountryName><cpa:EventDate>1999-12-23</cpa:EventDate><cpa:RegistrationNumber></cpa:RegistrationNumber></cpa:RelatedCase></cpa:RelatedCaseSet><cpa:CaseNameSet><cpa:CaseName><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:NameTypeCode encoding="CPAINPRO">EX</cpa:NameTypeCode><cpa:NameTypeDescription>Examiner Name</cpa:NameTypeDescription><cpa:Name>STOCKTON</cpa:Name><cpa:FirstName>LAURA LYNNE</cpa:FirstName><cpa:IsIndividual>1</cpa:IsIndividual></cpa:CaseName><cpa:CaseName><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:NameTypeCode encoding="CPAINPRO">J</cpa:NameTypeCode><cpa:NameTypeDescription>First Named Inventor</cpa:NameTypeDescription><cpa:Name>Fowler</cpa:Name><cpa:FirstName>Kerry</cpa:FirstName><cpa:IsIndividual>1</cpa:IsIndividual><cpa:City>Seattle</cpa:City><cpa:StateCode>WA</cpa:StateCode><cpa:CountryCode></cpa:CountryCode></cpa:CaseName></cpa:CaseNameSet><cpa:CaseEventSet><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Post Issue Communication - Certificate of Correction</cpa:EventDescription><cpa:EventDate>2002-12-19</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Statement Filed Indicating a Loss of Entitlement to Small Entity Status</cpa:EventDescription><cpa:EventDate>2002-03-28</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Workflow - File Sent to Contractor</cpa:EventDescription><cpa:EventDate>2001-07-09</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Recordation of Patent Grant Mailed</cpa:EventDescription><cpa:EventDate>2001-11-06</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Issue Notification Mailed</cpa:EventDescription><cpa:EventDate>2001-10-18</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Patent Issue Date Used in PTA Calculation</cpa:EventDescription><cpa:EventDate>2001-11-06</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Issue Fee Payment Verified</cpa:EventDescription><cpa:EventDate>2001-08-30</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Application Is Considered Ready for Issue</cpa:EventDescription><cpa:EventDate>2001-09-20</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Case Docketed to Examiner in GAU</cpa:EventDescription><cpa:EventDate>2001-06-28</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Mail Notice of Allowance</cpa:EventDescription><cpa:EventDate>2001-06-28</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Notice of Allowance Data Verification Completed</cpa:EventDescription><cpa:EventDate>2001-06-28</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Preliminary Amendment</cpa:EventDescription><cpa:EventDate>2001-06-27</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Information Disclosure Statement (IDS) Filed</cpa:EventDescription><cpa:EventDate>2001-06-18</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Case Docketed to Examiner in GAU</cpa:EventDescription><cpa:EventDate>2001-04-06</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Application Dispatched from OIPE</cpa:EventDescription><cpa:EventDate>2001-03-29</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Correspondence Address Change</cpa:EventDescription><cpa:EventDate>2001-03-27</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>IFW Scan &amp; PACR Auto Security Review</cpa:EventDescription><cpa:EventDate>2000-12-28</cpa:EventDate></cpa:CaseEvent><cpa:CaseEvent><cpa:ImportedCaseID>1</cpa:ImportedCaseID><cpa:EventDescription>Initial Exam Team nn</cpa:EventDescription><cpa:EventDate>2000-11-27</cpa:EventDate></cpa:CaseEvent></cpa:CaseEventSet></cpa:CaseExchangeNormalised>'
	PRINT 'Stored Procedure: IPNet.dbo.de_CaseComparisonLoad'
	SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
	PRINT @PrnLine
End

If @RC = 0
Begin
	EXEC @RC = [de_CaseComparison] @pnUserIdentityId, @pbCalledFromCentura, @psTableNameQualifier, @pnDebugFlag
	PRINT 'Stored Procedure: dbo.de_CaseComparison'
	SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
	PRINT @PrnLine
End


If @RC = 0
Begin
	DECLARE @psMode char(1)
	SELECT @psCulture = N'en'
	SELECT @pbCalledFromCentura = 0
	SELECT @psMode = NULL
	EXEC @RC = [de_ListCaseComparisonData] @pnUserIdentityId, @psCulture, @pbCalledFromCentura, @psTableNameQualifier, @pnCaseKey, @psMode
	PRINT 'Stored Procedure: SPRUSONS_DEV.dbo.de_ListCaseComparisonData'
	SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
	PRINT @PrnLine
End

If @RC = 0
Begin
	EXEC @RC = [dbo].[de_CaseComparisonRemove] @pnUserIdentityId, @psTableNameQualifier 
	PRINT 'Stored Procedure: IPNet.dbo.de_CaseComparisonRemove'
	SELECT @PrnLine = '	Return Code = ' + CONVERT(nvarchar, @RC)
	PRINT @PrnLine
End