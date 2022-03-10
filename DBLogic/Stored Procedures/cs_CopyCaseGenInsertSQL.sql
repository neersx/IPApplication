-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CopyCaseGenInsertSQL
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_CopyCaseGenInsertSQL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_CopyCaseGenInsertSQL.'
	Drop procedure [dbo].[cs_CopyCaseGenInsertSQL]
End
Print '**** Creating Stored Procedure dbo.cs_CopyCaseGenInsertSQL...'
Print ''
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.cs_CopyCaseGenInsertSQL
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psProfileName			nvarchar(30),	-- Mandatory 
	@psCopyArea			nvarchar(30),	-- Mandatory 
	@psSql				nvarchar(4000)	output,
	@pnOrigCaseId			int,		-- Mandatory 
	@pnNewCaseKey			int,		-- Mandatory 
	-- The following parameters only need to be passed for CASES
	@psNewCaseIrn			nvarchar(36)	= null,
	@psCaseFamilyReference		nvarchar(20)	= null,
	@psCountryKey			nvarchar(3)	= null,
	@psPropertyTypeKey		nvarchar(2)	= null,
	@psCaseCategoryKey		nvarchar(2)	= null,
	@psSubTypeKey			nvarchar(2)	= null,
	@psBasisKey			nvarchar(4)	= null,
	@psCaseStatusKey		nvarchar(10)	= null,
	@psShortTitle   		nvarchar(508)	= null,
	@psLocalClasses			nvarchar(254)	= null,
	@psIntClasses			nvarchar(254)	= null,
	@pnNoOfClasses			int		= null,
	@pnOfficeKey                    int             = null,
	@pnDebug			int		= 0,
	@psSequenceNumbers		nvarchar(100)	= null,	-- comma-separated list of selected sequence numbers
	@psStem				nvarchar(30)	= null,
	@psProfitCentreCode		nvarchar(6)	= null,
	@psXmlCaseCopyData              ntext           = null,	
	@psCaseTypeKey			nvarchar(2)	= null
)
as
-- PROCEDURE :	cs_CopyCaseGenInsertSQL
-- VERSION :	43
-- DESCRIPTION:	Generates an SQL statement for the specified CopyArea aka Table
-- NOTES:	See cs_CopyCase.doc for details
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 23 JUL 2002	JB		1	Procedure created
-- 02 DEC 2002  SF		5	Included support for LocalClases, IntClasses and NoOfClasses (338)
-- 12 FEB 2003	SF		6	RFC05 Check for Valid Data
-- 25 FEB 2003	SF		7	RFC05 Iteration.  Incorrect valid data was not ommited.
-- 29 Oct 2004	AB	8035	8	Add collate database_default syntaxt to temp tables
-- 25 May 2005	TM	RFC2241	9	Include case category in valid basis test.
-- 25 May 2005	TM	RFC2241	10	Correct the ValidBasis logic.
-- 26 May 2005	TM	RFC2241	11	Correct the ValidBasis logic again.
-- 26 May 2005	TM	RFC2241	12	Filter on filtering on CaseType/CaseCategory 'is null' in the 
--					second test for valid basis.
-- 26 May 2005	TM	RFC2584	13	Any CopyProfile rules where StopCopy = 1 should be excluded.
-- 03 Jun 2005	TM	RFC2241	14	Use new ValidBasisex table to tests that basis is valid. 
-- 07 Jul 2005	TM	RFC2329	15	Increase the size of all case category parameters and local variables 
--					to 2 characters.
-- 19 Nov 2007	LP	RFC5704	16	Add capability to only copy a subset of case information 
-- 05 Feb 2008	LP	RFC3210	17	Copy data from parent case if not specified from parameters
-- 23 Apr 2008	LP	RFC6493	18	Copy all data if @pnSequenceNumbers is null.
-- 14 Jul 2008	LP	RFC6754	19	Add @psPropertyTypeKey, @ShortTitle and @psBasisKey to be used if specified by caller
--					Assumes that @psPropertyTypeKey and @psBasisKey are always valid 
--                                      Ensure CaseType is always set for a new Case.
-- 29 Jan 2009  LP      RFC6373 20      Add new @psXmlCaseCopyData to determine attributes to copy into the new case
-- 11 Mar 2009  LP      RFC6373 21      Fix logic to only copy data from original case if selected or REPLACEMENTDATA is NULL.
-- 10 Nov 2009	KR	RFC8627 22	Modify single quote to two quotes when concatinating string values in the select statement.
-- 05 Aug 2010	LP	RFC9625	23	Fix logic for determining the replacement values for selected attributes to copy.
-- 25 Oct 2010	KR	RFC9836 24	Added code to use the @psBasisKey passed in if not selected to copy from the original case.
-- 08 Nov 2010	LP	RFC9938	25	Added code to default status to Case Default Status site control if null.
-- 22 Feb 2011  LP      RFC9933 26      Add OfficeKey parameter to be used as CaseOfficeId
-- 23 Feb 2011 DV	R10188 	27 	Add @psStem parameter to insert STEM into CASES table
-- 21 Apr 2011  LP      R10513 	28	Only get CaseType from parent case if ReplacementData is NULL.
-- 26 May 2011  DV      R10640 	29	Add a condition so that even if the Attribute to be copied does not exists in any of the 
--					profile then also the attribute gets copied
-- 06 Jun 2011  DV      R10770 	30	Add the TAXCODE and other missing columns to be copied from the parent Case if it is selected
-- 17 Aug 2011  DV      R10296 	31	Do not copy Replacement data if the Profile name is null
-- 25 Aug 2011	LP	R10957 	32	Only copy attribute (e.g. SUBTYPE) from parent case if value has neither been specified by the user,
--					nor entered as available replacement data in the copy profile
-- 24 Oct 2011	ASH	R11460  32	Cast integer columns as nvarchar(11) data type.
-- 14 Dec 2011	LP	R11462	33	CaseType not being overridden even if Replacement Data is available.
-- 30 Dec 2011	LP	R11748	34	Fix issue where Case Status is being copied from parent case even if not selected.
--					Raised when creating national phase cases and "Case Default Status" is null.
-- 30 Dec 2011	LP	R11747	35	Fix issue where Stem is not being copied from parent when national phase case being created.
-- 21 May 2012	LP	R12311	36	Add OfficeKey parameter to be used as CaseOfficeId (RFC9933)
-- 21 May 2012	LP	R12312	37	Do not copy Replacement data if the Profile name is null (RFC10296)
-- 13 Jun 2013	AK	DR66	38	Increase the length of nvarchar to 254 of @psLocalClasses and @psIntClasses
-- 06 May 2013	MS	R33700	39	Increase the length of nvarchar to 254 of @psLocalClasses and @psIntClasses
-- 20 Jan 2016	MF	R55493	40	Cater for PROFITECENTRECODE column to be copied for CASES.
-- 03 Aug 2016	vql	R64867	41	Use unicode prefix for TITLE (DR-23391).
-- 10 Apr 2018	SW	R73768  42	Cater for max 254 characters for Case Title along with unicode prefix.
-- 10 Sep 2019	AK	DR18774	43	added selected casetype for new case.

Declare @nErrorNo 		int
Declare @sValidProperty 	nvarchar(1)
Declare @sValidCategory 	nvarchar(2)
Declare @sValidSubType 		nvarchar(2)
Declare @nValidStatus 		int
Declare @sValidCountry 		nvarchar(3)
Declare @sValidBasis 		nvarchar(2)
Declare @nValidRenewalStatus 	int
Declare @sCaseType 		nvarchar(1)
Declare @bByPassCopy 		bit

Declare @tblValidBasisList	table (ValidBasis nvarchar(2) collate database_default null)
Declare @nRowCount		int
Declare @bIsBasisValid		bit
Declare @sRowPattern            nvarchar(100)

Declare @tblCaseCopyAttrib table		
        (ATTRIBIDENTITY	        int IDENTITY,
         PROFILENAME		nvarchar(100) collate database_default,
 	 COPYAREA		nvarchar(60) collate database_default,
 	 COPYAREAKEY	        nvarchar(20) collate database_default,		
 	 REPLACEDATA	        nvarchar(508) collate database_default)
Declare @nAttribRowCount        int
Declare @idoc 		        int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		

Set @nErrorNo = 0
Set @nRowCount = 0
Set @bIsBasisValid = 0

-- Create a temp table from the specified attributes to be copied
Set @nAttribRowCount = 0
Set @sRowPattern = "//CaseCopyData/CopyData"

If @nErrorNo = 0
Begin		
        exec sp_xml_preparedocument	@idoc OUTPUT, @psXmlCaseCopyData
        
        Insert into @tblCaseCopyAttrib
        Select	*
        from	OPENXML (@idoc, @sRowPattern, 2)
        WITH (
              PROFILENAME	        nvarchar(100)	'ProfileName/text()',	
              COPYAREA		        nvarchar(60)	'CopyArea/text()',
              COPYAREAKEY		nvarchar(20)	'CopyAreaKey/text()',
              REPLACEDATA		nvarchar(508)	'ReplaceData/text()'
             )
        Set @nAttribRowCount = @@RowCount	

        exec sp_xml_removedocument @idoc

        Set @nErrorNo=@@Error

End
	        
-- Create a temp table from which we will create the SQL statement
If @nErrorNo = 0
Begin
    Declare @tCurrArea table
    (	CHARACTERKEY	nvarchar(30) collate database_default,
	    NUMERICKEY	int,
	    REPLACEMENTDATA	nvarchar(254) collate database_default,
	    STOPCOPY	decimal(1,0)
    )
    If @nAttribRowCount > 0
    Begin
        Insert into @tCurrArea
	Select DISTINCT ISNULL(CCA.COPYAREAKEY,C.CHARACTERKEY),
		C.NUMERICKEY,
		CASE WHEN (C.STOPCOPY = 1 or CCA.PROFILENAME is null) THEN NULL ELSE ISNULL(CCA.REPLACEDATA, C.REPLACEMENTDATA) END,
		C.STOPCOPY
	From COPYPROFILE C
	join @tblCaseCopyAttrib CCA on (CCA.COPYAREA like +'%'+ @psCopyArea + '%')
	and C.COPYAREA = @psCopyArea
	and (C.CHARACTERKEY = CCA.COPYAREAKEY or cast(C.NUMERICKEY as nvarchar(20)) = CCA.COPYAREAKEY
	or not exists (SELECT 1 from COPYPROFILE CP1 where CP1.CHARACTERKEY = CCA.COPYAREAKEY))
	and (C.PROFILENAME = CCA.PROFILENAME or CCA.PROFILENAME IS NULL)
	Set @nErrorNo = @@ERROR
    End
    Else If @psSequenceNumbers is not null 
    Begin	
	Insert into @tCurrArea
		Select CHARACTERKEY,
		NUMERICKEY,
		CASE WHEN STOPCOPY = 1 THEN NULL ELSE REPLACEMENTDATA END,
		STOPCOPY
		From COPYPROFILE C
		join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
		Where PROFILENAME = @psProfileName 
		and COPYAREA = @psCopyArea
	Set @nErrorNo = @@ERROR
    End
    Else
    Begin
	Insert into @tCurrArea
		Select CHARACTERKEY,
		NUMERICKEY,
		CASE WHEN STOPCOPY = 1 THEN NULL ELSE REPLACEMENTDATA END,
		STOPCOPY
		From COPYPROFILE C
		Where PROFILENAME = @psProfileName 
		and COPYAREA = @psCopyArea
	Set @nErrorNo = @@ERROR
    End
End
If @nErrorNo = 0
Begin
	Select 	@sValidProperty = PROPERTYTYPE,
		@sValidCategory = CASECATEGORY,
		@sValidSubType = SUBTYPE,
		@nValidStatus = STATUSCODE,
		@sValidCountry = COUNTRYCODE,
		@sCaseType = CASETYPE 
	from 	CASES
	where	CASEID = 
			Case @psCopyArea 
				when 'CASES' then @pnOrigCaseId 
				else @pnNewCaseKey 
			end

	Select 	@sValidBasis = BASIS
	from	PROPERTY
	where	CASEID = @pnOrigCaseId

	Set @nErrorNo = @@error
End

-- ------------------
-- Fix Up the data
-- Both need CASEID
If @nErrorNo = 0
Begin
	If @nErrorNo = 0  -- Never a null CASEID
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'CASEID')
			update @tCurrArea 
				set REPLACEMENTDATA = @pnNewCaseKey 
					where CHARACTERKEY = 'CASEID'
		Else
			insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
				values ('CASEID', @pnNewCaseKey)
	End
	Set @nErrorNo = @@ERROR
End

-- CASES needs lots more
If @psCopyArea = 'CASES'
Begin

	If @nErrorNo = 0  -- Never a null IRN
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'IRN')
		Begin
			Update @tCurrArea 
			set REPLACEMENTDATA = @psNewCaseIrn 
			where CHARACTERKEY = 'IRN'
	        End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('IRN', @psNewCaseIrn)
		End
	End
	Set @nErrorNo = @@ERROR
	
	If @nErrorNo = 0  -- Never a null CASETYPE
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'CASETYPE')
		Begin
			Update @tCurrArea 
			set REPLACEMENTDATA = @sCaseType 
			where CHARACTERKEY = 'CASETYPE'
			and REPLACEMENTDATA IS NULL
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('CASETYPE', @sCaseType)
		End
	End
	Set @nErrorNo = @@ERROR

	If @nErrorNo = 0 and @psCaseFamilyReference is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'FAMILY')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psCaseFamilyReference 
			where CHARACTERKEY = 'FAMILY'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('FAMILY', @psCaseFamilyReference)		
		End
	End
	Else
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'FAMILY')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = (SELECT FAMILY FROM CASES WHERE CASEID = @pnOrigCaseId) 
			where CHARACTERKEY = 'FAMILY'
			and REPLACEMENTDATA is NULL
		End
	End	
	Set @nErrorNo = @@ERROR

	If @nErrorNo = 0 and @psStem is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'STEM')		
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psStem 
			where CHARACTERKEY = 'STEM'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('STEM', @psStem)
	        End
	End
	Else
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'STEM')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = (SELECT STEM FROM CASES WHERE CASEID = @pnOrigCaseId) 
			where CHARACTERKEY = 'STEM'
			and REPLACEMENTDATA is NULL
		End
	End	
	Set @nErrorNo = @@ERROR

		If @nErrorNo = 0 and @psCaseTypeKey is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'CASETYPE')		
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psCaseTypeKey 
			where CHARACTERKEY = 'CASETYPE'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('CASETYPE', @psCaseTypeKey)
	        End
	End
	Else
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'CASETYPE')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = (SELECT CASETYPE FROM CASES WHERE CASEID = @pnOrigCaseId) 
			where CHARACTERKEY = 'CASETYPE'
			and REPLACEMENTDATA IS NULL
		End
		Else    -- Must have a COUNTRYCODE
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			SELECT 'CASETYPE', CASETYPE
			FROM CASES 
			WHERE CASEID = @pnOrigCaseId
	        End
	End	
	Set @nErrorNo = @@ERROR

       	If @nErrorNo = 0 and @psCountryKey is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'COUNTRYCODE')		
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psCountryKey 
			where CHARACTERKEY = 'COUNTRYCODE'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('COUNTRYCODE', @psCountryKey)
	        End
	End
	Else
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'COUNTRYCODE')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = (SELECT COUNTRYCODE FROM CASES WHERE CASEID = @pnOrigCaseId) 
			where CHARACTERKEY = 'COUNTRYCODE'
			and REPLACEMENTDATA IS NULL
		End
		Else    -- Must have a COUNTRYCODE
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			SELECT 'COUNTRYCODE', COUNTRYCODE
			FROM CASES 
			WHERE CASEID = @pnOrigCaseId
	        End
	End	
	Set @nErrorNo = @@ERROR
	
	If @nErrorNo = 0 and @psPropertyTypeKey is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'PROPERTYTYPE')		
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psPropertyTypeKey 
			where CHARACTERKEY = 'PROPERTYTYPE'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('PROPERTYTYPE', @psPropertyTypeKey)
		End
	End
	Else
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'PROPERTYTYPE')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = (SELECT PROPERTYTYPE FROM CASES WHERE CASEID = @pnOrigCaseId) 
			where CHARACTERKEY = 'PROPERTYTYPE'
			and REPLACEMENTDATA IS NULL
		End		
		Else    -- Must have a PROPERTYTYPE
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			SELECT 'PROPERTYTYPE',PROPERTYTYPE FROM CASES WHERE CASEID = @pnOrigCaseId
		End
	End	
	Set @nErrorNo = @@ERROR

	If @nErrorNo = 0 and @psCaseCategoryKey is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'CASECATEGORY')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psCaseCategoryKey 
			where CHARACTERKEY = 'CASECATEGORY'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('CASECATEGORY', @psCaseCategoryKey)
		End
	End
	Else
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'CASECATEGORY')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = (SELECT CASECATEGORY FROM CASES where CASEID = @pnOrigCaseId) 
			where CHARACTERKEY = 'CASECATEGORY'
			and REPLACEMENTDATA IS NULL
		End
	End
	Set @nErrorNo = @@ERROR

	If @nErrorNo = 0 and @psSubTypeKey is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'SUBTYPE')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psSubTypeKey 
			where CHARACTERKEY = 'SUBTYPE'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('SUBTYPE', @psSubTypeKey)
	        End
	End
	Else
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'SUBTYPE')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = (SELECT SUBTYPE FROM CASES where CASEID = @pnOrigCaseId) 
			where CHARACTERKEY = 'SUBTYPE'
			and REPLACEMENTDATA IS NULL
		End
	End
	Set @nErrorNo = @@ERROR

        If @nErrorNo = 0 and @psCaseStatusKey is not null
        Begin
	        If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'STATUSCODE')
	        Begin
		        Update @tCurrArea set REPLACEMENTDATA = CAST(@psCaseStatusKey as int) 
			where CHARACTERKEY = 'STATUSCODE'
		End
	        Else
	        Begin
		        Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('STATUSCODE', Cast(@psCaseStatusKey as int))
		End
        End
        Else
        Begin
		-- Get the status code from the parent case if specified by the user
                If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'STATUSCODE')
                Begin
		        Update @tCurrArea set REPLACEMENTDATA = (SELECT STATUSCODE FROM CASES WHERE CASEID = @pnOrigCaseId)
			where CHARACTERKEY = 'STATUSCODE'	        
			and REPLACEMENTDATA IS NULL	        
		End
		Else
		-- Get the status code from the Case Default Status site control
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			Select 'STATUSCODE', S.COLINTEGER
			from SITECONTROL S
			where S.CONTROLID = 'Case Default Status'
			and S.COLINTEGER IS NOT NULL
		End
        End
	Set @nErrorNo = @@ERROR
	
	If @nErrorNo = 0 and @psLocalClasses is not null
	Begin
		If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'LOCALCLASSES')
		Begin
			Update @tCurrArea set REPLACEMENTDATA = @psLocalClasses 
			where CHARACTERKEY = 'LOCALCLASSES'
		End
		Else
		Begin
			Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('LOCALCLASSES', @psLocalClasses)
		End
	End
	Else
        Begin
               If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'LOCALCLASSES')
               Begin
	                Update @tCurrArea set REPLACEMENTDATA = (SELECT LOCALCLASSES FROM CASES WHERE CASEID = @pnOrigCaseId) 
	                where CHARACTERKEY = 'LOCALCLASSES'
	                and REPLACEMENTDATA IS NULL
	       End
        End
	Set @nErrorNo = @@ERROR
	
	If @nErrorNo = 0 and @psIntClasses is not null
        Begin
	        If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'INTCLASSES')
	        Begin
		        Update @tCurrArea set REPLACEMENTDATA = @psIntClasses 
			where CHARACTERKEY = 'INTCLASSES'
		End
	        Else
	        Begin
		        Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('INTCLASSES', @psIntClasses)
		End
        End
        Else
        Begin
               If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'INTCLASSES')
               Begin
	                Update @tCurrArea set REPLACEMENTDATA = (SELECT INTCLASSES FROM CASES WHERE CASEID = @pnOrigCaseId) 
	                where CHARACTERKEY = 'INTCLASSES'
	                and REPLACEMENTDATA IS NULL
	       End
        End
	Set @nErrorNo = @@ERROR

	If @nErrorNo = 0 and @pnNoOfClasses is not null
        Begin
	        If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'NOOFCLASSES')
	        Begin
		        Update @tCurrArea set REPLACEMENTDATA = @pnNoOfClasses 
			where CHARACTERKEY = 'NOOFCLASSES'
		End
	        Else
	        Begin
		        Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('NOOFCLASSES', @pnNoOfClasses)
		End
        End
        Else
        Begin
                If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'NOOFCLASSES')
                Begin
		        Update @tCurrArea set REPLACEMENTDATA = (SELECT NOOFCLASSES FROM CASES WHERE CASEID = @pnOrigCaseId)
			where CHARACTERKEY = 'NOOFCLASSES'
			and REPLACEMENTDATA IS NULL
	        End
        End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and @psShortTitle is null
        Begin
                If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'TITLE')
                Begin
                        Update @tCurrArea set REPLACEMENTDATA = (SELECT TITLE FROM CASES WHERE CASEID = @pnOrigCaseId)
	                where CHARACTERKEY = 'TITLE'
	                and REPLACEMENTDATA IS NULL
	        End
        End
        Else
        Begin
                If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'TITLE')
                Begin
	                Update @tCurrArea set REPLACEMENTDATA = @psShortTitle 
		        where CHARACTERKEY = 'TITLE'
		End
                Else
                Begin
	                Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
		        values ('TITLE', @psShortTitle)
		End
        End
        Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'FILECOVER')
        Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT FILECOVER FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'FILECOVER'
		and REPLACEMENTDATA IS NULL
        End
	Set @nErrorNo = @@ERROR
						
        If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'LOCALCLIENTFLAG')
        Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT LOCALCLIENTFLAG FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'LOCALCLIENTFLAG'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR
			
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'NOINSERIES')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT NOINSERIES FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'NOINSERIES'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
			
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'PURCHASEORDERNO')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT PURCHASEORDERNO FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'PURCHASEORDERNO'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
			
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'TYPEOFMARK')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT TYPEOFMARK FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'TYPEOFMARK'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'TAXCODE')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT TAXCODE FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'TAXCODE'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'SERVPERFORMEDIN')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT SERVPERFORMEDIN FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'SERVPERFORMEDIN'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'ENTITYSIZE')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT ENTITYSIZE FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'ENTITYSIZE'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'PREDECESSORID')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT PREDECESSORID FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'PREDECESSORID'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'STATETAXCODE')
	Begin
		Update @tCurrArea set REPLACEMENTDATA = (SELECT STATETAXCODE FROM CASES WHERE CASEID = @pnOrigCaseId)
		where CHARACTERKEY = 'STATETAXCODE'
		and REPLACEMENTDATA IS NULL
	End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and @pnOfficeKey is not null
        Begin
	        If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'OFFICEID')
	        Begin
		        Update @tCurrArea set REPLACEMENTDATA = @pnOfficeKey 
			where CHARACTERKEY = 'OFFICEID'
		End
	        Else
	        Begin
		        Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('OFFICEID', @pnOfficeKey)
		End
        End
        Else
        Begin
                If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'OFFICEID')
                Begin
		        Update @tCurrArea set REPLACEMENTDATA = (SELECT OFFICEID FROM CASES WHERE CASEID = @pnOrigCaseId)
			where CHARACTERKEY = 'OFFICEID'
			and REPLACEMENTDATA IS NULL
	        End
	End
	Set @nErrorNo = @@ERROR	
	
	If @nErrorNo = 0 and @psProfitCentreCode is not null
        Begin
	        If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'PROFITCENTRECODE')
	        Begin
		        Update @tCurrArea set REPLACEMENTDATA = @psProfitCentreCode 
			where CHARACTERKEY = 'PROFITCENTRECODE'
		End
	        Else
	        Begin
		        Insert into @tCurrArea (CHARACTERKEY, REPLACEMENTDATA) 
			values ('PROFITCENTRECODE', @psProfitCentreCode)
		End
        End
        Else
        Begin
                If exists(SELECT * FROM @tCurrArea where CHARACTERKEY = 'PROFITCENTRECODE')
                Begin
		        Update @tCurrArea set REPLACEMENTDATA = (SELECT PROFITCENTRECODE FROM CASES WHERE CASEID = @pnOrigCaseId)
			where CHARACTERKEY = 'PROFITCENTRECODE'
			and REPLACEMENTDATA IS NULL
	        End
	End
	Set @nErrorNo = @@ERROR		

End -- @psCopyArea = 'CASES'

-- Entire block added by SF see version 6 information above.
If @nErrorNo = 0
Begin
	-- Check for Validity of Data to be copied 
	-- ValidProperty, ValidCategory, ValidSubType, ValidBasis, ValidStatus

	Declare @nCaseKey int
	Declare @sValidKey nvarchar(254)

	-- Replace data if the case hasn't been created.
	If @psCopyArea = 'CASES'
	Begin
		-- If the copyarea is cases, the case hasn't been created, so replacement value is important.

		Select 	@sValidCountry = isnull(REPLACEMENTDATA, case when  STOPCOPY=1 then null else @sValidCountry end)
		from 	@tCurrArea
		where 	CHARACTERKEY = 'COUNTRYCODE'

		Select 	@sValidProperty = isnull(REPLACEMENTDATA, case when STOPCOPY=1 then null else @sValidProperty end)
		from 	@tCurrArea
		where 	CHARACTERKEY = 'PROPERTYTYPE'
	
		Select 	@sValidCategory = isnull(REPLACEMENTDATA, case when STOPCOPY=1 then null else @sValidCategory end)
		from 	@tCurrArea
		where 	CHARACTERKEY = 'CASECATEGORY'

		Select 	@sValidSubType = isnull(REPLACEMENTDATA, case when STOPCOPY=1 then null else @sValidSubType end)
		from 	@tCurrArea
		where 	CHARACTERKEY = 'SUBTYPE'

		Select 	@sValidBasis = isnull(REPLACEMENTDATA, case when STOPCOPY=1 then null else @sValidBasis end)
		from 	@tCurrArea
		where 	CHARACTERKEY = 'BASIS'

		Select 	@nValidStatus = isnull(REPLACEMENTDATA, case when STOPCOPY=1 then null else @nValidStatus end)
		from 	@tCurrArea
		where 	CHARACTERKEY = 'STATUSCODE'
	
		Select 	@sCaseType = isnull(REPLACEMENTDATA, case when STOPCOPY=1 then null else @sCaseType end)
		from 	@tCurrArea
		where 	CHARACTERKEY = 'CASETYPE'

		Set @nErrorNo = @@error
	End

	-- Any CopyProfile rules where StopCopy = 1 should be excluded:
	delete from @tCurrArea
	where STOPCOPY = 1
	and REPLACEMENTDATA is null

	Set @bByPassCopy = 0

	-- assert @sValidCountry is not null
	-- Perform validation on PropertyType - to see if the child case can use this propertytype
	If @nErrorNo = 0 
	and Exists (Select * from @tCurrArea where CHARACTERKEY = 'PROPERTYTYPE')
	and @psPropertyTypeKey is null
	Begin
		-- you only check the validity if it is in the copy profile.

		If @sValidProperty is not null 
		and not exists(Select * 
			from VALIDPROPERTY VP
			where 	VP.PROPERTYTYPE = @sValidProperty
			and 	COUNTRYCODE = (select min(VP1.COUNTRYCODE)
							from VALIDPROPERTY VP1
							where VP1.COUNTRYCODE in (@sValidCountry, 'ZZZ')))
		Begin
			Set @sValidProperty = null
			Set @bByPassCopy = 1

			delete from @tCurrArea 
			where CHARACTERKEY = 'PROPERTYTYPE'  -- do not copy

			Set @nErrorNo = @@error
		End
	End

	-- Perform validation on CaseCategory - to see if the child case can use this CaseCategory
	If @nErrorNo = 0 
	and Exists (Select * from @tCurrArea where CHARACTERKEY = 'CASECATEGORY')
	and @psCaseCategoryKey is null
	Begin
		-- you only check the validity if it is in the copy profile.
		If @bByPassCopy = 1
		Begin
			delete from @tCurrArea 
			where CHARACTERKEY = 'CASECATEGORY'  -- do not copy

			Set @nErrorNo = @@error		
		End

		If @sValidCategory is not null 
		and @bByPassCopy = 0
		and not exists(Select * 
			from 	VALIDCATEGORY VC
			where 	VC.CASETYPE = @sCaseType
			AND 	VC.PROPERTYTYPE = @sValidProperty
			AND 	VC.CASECATEGORY = @sValidCategory
			AND 	VC.COUNTRYCODE = (select min(VC1.COUNTRYCODE)
							from VALIDCATEGORY VC1
							where VC1.CASETYPE     = @sCaseType
							AND   VC1.PROPERTYTYPE = @sValidProperty
							AND   VC1.COUNTRYCODE in (@sValidCountry,'ZZZ')))
		Begin
			Set @bByPassCopy = 1
			Set @sValidCategory = null

			delete from @tCurrArea 
			where CHARACTERKEY = 'CASECATEGORY'  -- do not copy

			Set @nErrorNo = @@error
		End
	End

	-- Perform validation on SubType - to see if the child case can use this SubType
	If @nErrorNo = 0 
	and Exists (Select * from @tCurrArea where CHARACTERKEY = 'SUBTYPE')
	and @psSubTypeKey is null
	Begin
		-- you only check the validity if it is in the copy profile.
		If @bByPassCopy = 1
		Begin
			delete from @tCurrArea 
			where CHARACTERKEY = 'SUBTYPE'  -- do not copy

			Set @nErrorNo = @@error		
		End

		If @sValidSubType is not null 
		and @bByPassCopy = 0
		and not exists(Select * 
			from 	VALIDSUBTYPE VST
			where 	VST.SUBTYPE = @sValidSubType
		 	AND 	VST.PROPERTYTYPE = @sValidProperty
				AND VST.COUNTRYCODE = (select min(COUNTRYCODE)
		     					from VALIDSUBTYPE VST1
						     	where 	VST1.PROPERTYTYPE = @sValidProperty
							AND 	VST1.CASETYPE     = @sCaseType
						 	AND 	VST1.CASECATEGORY = @sValidCategory
							AND 	VST1.COUNTRYCODE in (@sValidCountry, 'ZZZ'))
		 	AND VST.CASETYPE = @sCaseType
			AND VST.CASECATEGORY = @sValidCategory)
		Begin
			Set @bByPassCopy = 1
			Set @sValidSubType = null

			delete from @tCurrArea 
			where CHARACTERKEY = 'SUBTYPE'  -- do not copy

			Set @nErrorNo = @@error
		End
	End
        
	-- Perform validation on Basis - to see if the child case can use this Basis
	If @nErrorNo = 0 
	and Exists (Select * from @tCurrArea where CHARACTERKEY = 'BASIS')
	and @psBasisKey is null
	Begin
		-- you only check the validity if it is in the copy profile.
		If @sValidProperty is not null
		Begin	
			-- Are there any rows for Property, Country/(exclusive OR) Default Country('ZZZ'),
			-- CaseType and Category in the ValidBasis table?
			Insert into @tblValidBasisList (ValidBasis)
			Select  VB.BASIS 
			from 	VALIDBASISEX VB
			where 	VB.PROPERTYTYPE = @sValidProperty
			AND	(VB.CASETYPE = @sCaseType)
			AND 	(VB.CASECATEGORY = @sValidCategory)
				AND VB.COUNTRYCODE = (	select min(COUNTRYCODE)
							from VALIDBASISEX VB1
						     	where 	VB1.PROPERTYTYPE = @sValidProperty	
							AND    (VB1.CASETYPE = @sCaseType)
							AND    (VB1.CASECATEGORY = @sValidCategory)
							AND 	VB1.COUNTRYCODE in (@sValidCountry, 'ZZZ'))
		
			Select  @nRowCount = @@RowCount,
				@nErrorNo = @@error
		
			If @nErrorNo = 0
			and @nRowCount > 0
			Begin
				-- Is the @sValidBasis is in the list of appropriate valid values?
				Select @bIsBasisValid = 1
				from   @tblValidBasisList
				where  ValidBasis = @sValidBasis		
			End
			-- Are there any rows for Property and Country/(exclusive OR) Default Country('ZZZ')
			-- in the ValidBasis table?
			Else  
			If  @nErrorNo = 0 
			and @nRowCount = 0
			Begin
				Insert into @tblValidBasisList (ValidBasis)
				Select  VB.BASIS  
				from 	VALIDBASIS VB
				where 	VB.PROPERTYTYPE = @sValidProperty
				AND VB.COUNTRYCODE = (	select min(COUNTRYCODE)
							from VALIDBASIS VB1
							where 	VB1.PROPERTYTYPE = @sValidProperty
							AND 	VB1.COUNTRYCODE in (@sValidCountry, 'ZZZ'))
			
				Select  @nRowCount = @@RowCount,
					@nErrorNo = @@error		
		
				If @nErrorNo = 0
				and @nRowCount > 0
				Begin
					-- Is the @sValidBasis is in the list of appropriate valid values?
					Select @bIsBasisValid = 1
					from   @tblValidBasisList
					where  ValidBasis = @sValidBasis		
				End	
			End	
		End

		If @sValidProperty is null
		or (@sValidBasis is not null and
		@bIsBasisValid = 0)
		Begin
			Set @bByPassCopy = 1
			Set @sValidBasis = null

			delete from @tCurrArea 
			where CHARACTERKEY = 'BASIS'  -- do not copy

			Set @nErrorNo = @@error
		End
	End
	Else If @nErrorNo = 0 
	and Exists (Select * from @tCurrArea where CHARACTERKEY = 'BASIS')
	and @psBasisKey is not null
	Begin
	        Update @tCurrArea set REPLACEMENTDATA = @psBasisKey
		where CHARACTERKEY = 'BASIS'
		
	        Set @nErrorNo = @@error
	End
	
	Else If @nErrorNo = 0 
	and not Exists (Select * from @tCurrArea where CHARACTERKEY = 'BASIS')
	and @psBasisKey is not null
	Begin
	        insert into @tCurrArea( REPLACEMENTDATA,CHARACTERKEY)  values (@psBasisKey, 'BASIS')
		
	        Set @nErrorNo = @@error
	End

	-- Perform validation on StatusCode - to see if the child case can use this StatusCODE
	If @nErrorNo = 0 
	and Exists (Select * from @tCurrArea where CHARACTERKEY = 'STATUSCODE')
	Begin
		-- you only check the validity if it is in the copy profile.
		If @sCaseType is null
		or @sValidProperty is null
		or (@nValidStatus is not null 
		and not exists(Select * 
			from 	VALIDSTATUS VS
			where 	VS.STATUSCODE = @nValidStatus
		 	AND 	VS.PROPERTYTYPE = @sValidProperty
			AND 	VS.COUNTRYCODE = (select min(COUNTRYCODE)
		     					from VALIDSTATUS VS1
						     	where 	VS1.PROPERTYTYPE = @sValidProperty
						 	AND 	VS1.CASETYPE 	 = @sCaseType
							AND 	VS1.COUNTRYCODE in (@sValidCountry, 'ZZZ'))
		 	AND 	VS.CASETYPE = @sCaseType))
		Begin
			delete from @tCurrArea 
			where CHARACTERKEY = 'STATUSCODE'  -- do not copy

			Set @nErrorNo = @@error
		End
	End

End

If @nErrorNo = 0
Begin
	Declare @sCurrKey nvarchar(254)
	Declare @bProcess bit
	Set @bProcess = 0

	-- Construct the SQL statement for this COPYARE
	Set @psSql = 'Insert into ' + @psCopyArea + ' ('
	
	---------------------------
	-- Get the list of columns
	Set @sCurrKey = ''
	While @nErrorNo = 0 and exists 
		(Select * from @tCurrArea
			where CHARACTERKEY > @sCurrKey)
	Begin
		Select @sCurrKey = MIN(CHARACTERKEY) 
			from @tCurrArea
			where CHARACTERKEY > @sCurrKey

		If @@ROWCOUNT = 0
			Set @nErrorNo = -1
		Else
			Set @psSql = @psSql + @sCurrKey + ','

	End
	-- knock off the last comma and continue statement
	Set @psSql = left(@psSql, len(@psSql) - 1) + ') Select '

	--------------------------------------
	-- Get the list of replacement values
	Declare @sData nvarchar(257)
	Set @sCurrKey = ''	-- Reset it
	While @nErrorNo = 0 and exists 
		(Select * from @tCurrArea
			where CHARACTERKEY > @sCurrKey)
		Begin
		Select TOP 1 @sCurrKey = CHARACTERKEY,
			@sData = REPLACEMENTDATA
			from @tCurrArea
			where CHARACTERKEY > @sCurrKey
			order by CHARACTERKEY ASC

		-- We know that it will return a row (see above)
		If @sData is null
			Set @sData = 'ORIG.' + @sCurrKey
		Else
			Set @sData = "N'" + Replace(@sData, char(39), char(39)+char(39) ) + "'"

		Set @psSql = @psSql + @sData + ','
	End

	--------------------------------
	-- knock off the last command and finish the SQL statement
	If @nErrorNo = 0
	Begin
		Set @psSql = left(@psSql, len(@psSql) - 1) + ' 
			from ' + @psCopyArea + ' ORIG 
			where ORIG.CASEID = ' + Cast(@pnOrigCaseId as nvarchar(11))
	End
End

If @pnDebug = 1
	Select @psSql		-- Left in for debugging

Return @nErrorNo
go

grant execute on dbo.cs_CopyCaseGenInsertSQL  to public
go