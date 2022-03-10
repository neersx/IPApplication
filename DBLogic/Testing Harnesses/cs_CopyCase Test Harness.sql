--------------------------------------------------------------------------------
------------------------ cs_CopyCase TEST HARNESS ------------------------------
-- INSERT INTO CASEIMAGE VALUES (-484, -498, 1201, 0, 'Rondon & shoe')

Declare @sOrigCaseKey nvarchar(10)
Set @sOrigCaseKey = '-476'
Declare @nErr int
Declare @psNewCaseKey nvarchar(10)
Declare @nPolicingNumber nvarchar(36)

exec @nErr = cs_CopyCase @pnUserIdentityId = 19,
	@psCulture = 'en-AU',
	@psCaseKey = @sOrigCaseKey,
	@psProfileName = 'PCT National Phase',
	@psNewCaseKey = @psNewCaseKey output,
	@psCaseFamilyReference = 'JEK',
	@psCountryKey = 'AU',
	@psCountryName = NULL,
	@psCaseCategoryKey = 'N',
	@psCaseCategoryDescription = NULL,
	@psSubTypeKey = 'N',
	@psSubTypeDescription = NULL,
	@psCaseStatusKey = '-201',
	@psCaseStatusDescription = NULL,
	@psApplicationNumber = 'A1234',
	@pdtApplicationDate = '1-JAN-1999',
	@pbDebug = 1

SELECT @psNewCaseKey

Select 'ORIG CASES', * from CASES where CASEID = CAST(@sOrigCaseKey as int)
Select 'NEW CASES', * from CASES where CASEID = CAST(@psNewCaseKey as int)

Select 'ORIG PROPERTY', * from PROPERTY where CASEID = CAST(@sOrigCaseKey as int)
Select 'NEW PROPERTY', * from PROPERTY where CASEID = CAST(@psNewCaseKey as int)

Select 'ORIG CASEWORDS', * from CASEWORDS where CASEID = CAST(@sOrigCaseKey as int)
Select 'NEW CASEWORDS', * from CASEWORDS where CASEID = CAST(@psNewCaseKey as int)

Select 'ORIG TABLEATTRIBUTES', * from TABLEATTRIBUTES where GENERICKEY = @sOrigCaseKey
Select 'NEW TABLEATTRIBUTES', * from TABLEATTRIBUTES where GENERICKEY = @psNewCaseKey

SELECT 'ORIG CASETEXT', * FROM CASETEXT WHERE CASEID = CAST(@sOrigCaseKey as int)
SELECT 'NEW CASETEXT', * FROM CASETEXT WHERE CASEID = CAST(@psNewCaseKey as int)

SELECT 'ORIG CASENAME', * FROM CASENAME WHERE CASEID = CAST(@sOrigCaseKey as int)
SELECT 'NEW CASENAME', * FROM CASENAME WHERE CASEID = CAST(@psNewCaseKey as int)

SELECT 'ORIG OFFICIALNUMBERS', * FROM OFFICIALNUMBERS WHERE CASEID = CAST(@sOrigCaseKey as int)
SELECT 'NEW OFFICIALNUMBERS', * FROM OFFICIALNUMBERS WHERE CASEID = CAST(@psNewCaseKey as int)

SELECT 'ORIG CASEEVENT', * FROM CASEEVENT WHERE CASEID = CAST(@sOrigCaseKey as int)
SELECT 'NEW CASEEVENT', * FROM CASEEVENT WHERE CASEID = CAST(@psNewCaseKey as int)

SELECT 'ORIG RELATEDCASE', * FROM RELATEDCASE WHERE CASEID = CAST(@sOrigCaseKey as int)
SELECT 'NEW RELATEDCASE', * FROM RELATEDCASE WHERE CASEID = CAST(@psNewCaseKey as int)

SELECT 'ORIG REVERSE RELATEDCASE', * FROM RELATEDCASE WHERE RELATEDCASEID = CAST(@sOrigCaseKey as int)
SELECT 'NEW REVERSE RELATEDCASE', * FROM RELATEDCASE WHERE RELATEDCASEID = CAST(@psNewCaseKey as int)

SELECT 'ORIG CASEIMAGE', * FROM CASEIMAGE WHERE CASEID = CAST(@sOrigCaseKey as int)
SELECT 'NEW CASEIMAGE', * FROM CASEIMAGE WHERE CASEID = CAST(@psNewCaseKey as int)

-- Check the new IRN and STEM
SELECT * FROM CASES WHERE CASEID = CAST(@psNewCaseKey as int)

Print 'Orig: '   + @sOrigCaseKey
Print 'New: '	+ @psNewCaseKey

SELECT @nErr

-- OLD TESTS --

/*Exec dbo.cs_CopyCase
	@pnUserIdentityId		= 1,
	@psCulture			= null,
	@psCaseKey			= @sOrigCaseKey,
	@psProfileName			= 'Everthing',
	@psNewCaseKey			=  @psNewCaseKey output,	
	@psCaseFamilyReference		= 'FamRef',
	@psCountryKey			= 'AU',
	@psCountryName			= null,
	@psCaseCategoryKey		= 'N',
	@psCaseCategoryDescription	= null,
	@psSubTypeKey			= null,
	@psSubTypeDescription		= null,
	@psCaseStatusKey		= null,
	@psCaseStatusDescription	= null,
	@psApplicationNumber		= '123',
	@pdtApplicationDate		= null,
	-- Not sure if you want this!
	@pnPolicingSeqNo		= @nPolicingNumber output,
	@pbDebug			= 1
*/

