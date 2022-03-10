----- Testing Harnes for cs_InsertRelatedCase

SELECT * FROM RELATEDCASE WHERE CASEID = -484
--SELECT * FROM CASES WHERE CASEID = -484
SELECT * FROM CASES WHERE CASEID = 32
declare @err int
declare @nSeq int
exec @err = cs_InsertRelatedCase
	@pnUserIdentityId		= 1,
	@psCulture			= null, 
	@psCaseKey			= '-484', 
	@pnRelationshipSequence		= @nSeq  output,
	@psRelationshipKey		= 'DIV',
	@psRelatedCaseKey		= '33',
	@psRelatedCaseReference		= null,
	@psCaseFamilyReference 		= null,	
	@psCountryKey			= 'AU',
	@psOfficialNumber		= 'JHDKJ',
	@psCaseCategoryKey 		= null 

select @err
SELECT @nSeq
SELECT * FROM RELATEDCASE WHERE CASEID = -484
SELECT * FROM RELATEDCASE WHERE RELATEDCASEID = -484
