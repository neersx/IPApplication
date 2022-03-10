-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_CopyCaseSupervisor
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].csw_CopyCaseSupervisor') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_CopyCaseSupervisor.'
	drop procedure [dbo].csw_CopyCaseSupervisor
end
print '**** Creating Stored Procedure dbo.csw_CopyCaseSupervisor...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_CopyCaseSupervisor
(
	@psNewCaseKeys			nvarchar(4000)	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psCaseKey			nvarchar(11)	= null,
	@psProfileName			nvarchar(50)	= null,
	@psSequenceNumbers		nvarchar(100)	= null, -- obsoleted by @psXmlCaseCopyData
	@psCaseFamilyReference		nvarchar(20)	= null,
	@psCountryKey			nvarchar(3)	= null,
	@psCountryName			nvarchar(60)	= null,
	@psPropertyTypeKey		nvarchar(2)	= null,
	@psCaseCategoryKey		nvarchar(2)	= null,
	@psCaseCategoryDescription	nvarchar(50)	= null,
	@psSubTypeKey			nvarchar(2)	= null,
	@psSubTypeDescription		nvarchar(50)	= null,
	@psBasisKey			nvarchar(4)	= null,
	@psCaseStatusKey		nvarchar(10)	= null,
	@psCaseStatusDescription	nvarchar(50)	= null,
	@psApplicationNumber		nvarchar(36)	= null,
	@pdtApplicationDate		datetime 	= null,
	@pnPolicingBatchNo		int		= null,
	@psCaseReference		nvarchar(30)	= '<Generate Reference>',
	@psRelationshipKey		nvarchar(10)	= null,
	@psShortTitle   		nvarchar(508)	= null,
	@pnOfficeKey                    int             = null,
	@pnInstructorKey                int             = null,
	@pnOwnerKey                     int             = null,
	@pnStaffKey                     int             = null,
	@psStem				nvarchar(30)	= null,
	@psDesignatedClasses		nvarchar(254)	= null,
	@pbIsFromDesignation            bit             = 0,
	@psXmlCaseCopyData              nvarchar(max)	= null,
	@pbUseClassesOverride		bit		= 0,
	@psLocalClasses			nvarchar(254)	= null,
	@psIntClasses			nvarchar(254)	= null,
	@psProgramId			nvarchar(8)	= null,
	@psCaseTypeKey			nvarchar(2)	= null
)
as
-- PROCEDURE:	csw_CopyCaseSupervisor
-- VERSION:	21
-- SCOPE:	Clerical Workbench
-- DESCRIPTION:	Copy an existing case, optionally providing specific attribute values to use on the new case(s).
--              The process will normally result in a single new case.  
--              However, if a multi-class case is being copied to a country that permits only single class applications, 
--              a new case is created for each class.
-- COPYRIGHT:	Copyright 2017 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19-NOV-2007  LP	RFC5704 1	Procedure created
-- 06 Feb 2008	LP	RFC3210 2	Add new RelationshipKey parameter
-- 03 Jul 2008	LP	RFC6754	3	Add new PropertyTypeKey, ShortTitle and BasisKey parameters
-- 29 Jan 2009  LP	RFC6373 4	Add new XmlCaseCopyData parameter
--                                      Use XmlCaseCopyData parameter to generate insert script for new case
-- 22 Feb 2011  LP	RFC9933 5	Add OfficeKey parameter
-- 23 Feb 2011	DV	RFC10188 6	Add a new @psStem parameter.
-- 04 Mar 2011  MS      RFC100469 7     Add new parameters @pnInstructorKey, @pnOwnerKey and @pnStaffKey
-- 13 Feb 2011	LP	RFC11772 8	Pass @psXmlCaseCopyData to single-class application stored proc call
--					Derive selected attributes from @psXmlCaseCopyData rather than @psSequenceNumbers.
-- 23 Feb 2012	LP	RFC11726 9	Update corresponding TRANSACTIONINFO records with new CASEIDs.

-- 21 May 2012	LP	R12311	10	Add OfficeKey parameter.
-- 13 Jun 2013	AK	R13408	11	Add @psDesignatedClasses parameter.
-- 31 Oct 2013	MS	R13708	12	Replace ", " with "," for @psDesignatedClasses
-- 06 Nov 2013	AT	R28091	13	Consider Multi-Classes allowed property of Valid Category.
-- 08 Apr 2014	vql	R33211	14	Allow int and local classes to be user defined.
-- 05 May 2014  MS      R33700  15      Handle classes for single class case when Case Ref is entered manually
-- 03 Dec 2014	MF	R42129	16	Problem occurring when LOCALCLASSES data contains an empty string rather than NULL.
-- 07 Jul 2015  SS	R49350  17	Added a check to count NoOfClasses only if localClasses / intlClasses is not NULL.
-- 24 Aug 2016	MF	62043	18	Change TEXT to nvarchar(max).
-- 18 Oct 2017	LP	R40875	19	Use current logical program when deriving the action to open for the new case.
-- 10 Sep 2019	AK	DR18774	20	added selected casetype for new case.
-- 10 Sep 2019	BS	DR-28789 21	Trimmed leading and trailing blank spaces in IRN when creating new case.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @bCreateSingleCase bit

Declare @idoc                   int
Declare @sRowPattern            nvarchar(100)
Declare @tblCaseCopyAttrib table		(ATTRIBIDENTITY	        int IDENTITY,
					         PROFILENAME		nvarchar(100) collate database_default,
					 	 COPYAREA		nvarchar(60) collate database_default,
		      		 	 	 COPYAREAKEY	        nvarchar(20) collate database_default,		
		      		 	 	 REPLACEDATA	        nvarchar(508) collate database_default)

Set @nErrorCode = 0
Set @bCreateSingleCase = 1

If LEN(ltrim(@psDesignatedClasses))=0
	set @psDesignatedClasses=NULL

If @psDesignatedClasses is not null
Begin
	Set @psDesignatedClasses = REPLACE(@psDesignatedClasses, ', ', ',')
End

Set @sRowPattern = "//CaseCopyData/CopyData"
If @nErrorCode = 0
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
        exec sp_xml_removedocument @idoc

        Set @nErrorCode=@@Error
End

If @psCaseReference = null or
	@psCaseReference = ''
Begin
	Set @psCaseReference = '<Generate Reference>'
End
Else
Begin    
	Set @psCaseReference = LTRIM(RTRIM(@psCaseReference))
END

If @nErrorCode = 0
and (exists(Select * 
		From @tblCaseCopyAttrib TAB 
		where 	COPYAREA like '%_CASES'
		and	COPYAREAKEY in ('NOOFCLASSES', 'LOCALCLASSES')))
-- do not do multi class application if @pbUseClassesOverride flag is ON or @pbIsFromDesignation is ON
-- the classes logic already performed in front end
and (@pbIsFromDesignation = 0 and @pbUseClassesOverride = 0)
Begin
	-- Classes are to be copied.
	Declare @sCountryKey nvarchar(3)
	Declare @sCaseTypeKey nvarchar(3)
	Declare @sPropertyType nvarchar(1)
	Declare @sCaseCategory nvarchar(2)

	Set @sCountryKey = null
	
	set @sCaseTypeKey = @psCaseTypeKey

	If @sCaseTypeKey is null
	Begin
		-- Get casetype of the new case	
		Select	@sCaseTypeKey = isnull(TAB.REPLACEDATA, C.CASETYPE)
		from 	CASES C
		join @tblCaseCopyAttrib TAB on (TAB.COPYAREA like '%_CASES') 
		where 	C.CASEID = @psCaseKey
		and 	TAB.COPYAREAKEY = 'CASETYPE'	
	End

	-- Get country of the new case	
	Set @sCountryKey = @psCountryKey

	If @sCountryKey is null	
	Begin
		Select	@sCountryKey = isnull( TAB.REPLACEDATA, C.COUNTRYCODE)
		from 	CASES C
		join @tblCaseCopyAttrib TAB on (TAB.COPYAREA like '%_CASES') 
		where 	C.CASEID = @psCaseKey
		and 	TAB.COPYAREAKEY = 'COUNTRYCODE'	

		if @sCountryKey is null 
		Begin
			Set @sCountryKey = @psCountryKey	
		End
	End
	
	-- Get the PropertyType of the new case
	Set @sPropertyType = @psPropertyTypeKey
	if @sPropertyType is null
	Begin
		Select	@sPropertyType = isnull( TAB.REPLACEDATA, C.PROPERTYTYPE)
		from 	CASES C
		join @tblCaseCopyAttrib TAB on (TAB.COPYAREA like '%_CASES') 
		where 	C.CASEID = @psCaseKey
		and 	TAB.COPYAREAKEY = 'PROPERTYTYPE'	
	End
	
	-- Get the case category of the new case
	Set @sCaseCategory = @psCaseCategoryKey
	if @sCaseCategory is null
	Begin
		Select	@sCaseCategory = isnull(TAB.REPLACEDATA, C.CASECATEGORY)
		from 	CASES C
		join @tblCaseCopyAttrib TAB on (TAB.COPYAREA like '%_CASES') 
		where 	C.CASEID = @psCaseKey
		and 	TAB.COPYAREAKEY = 'CASECATEGORY'	
	End
			
	-- does it allow multi class application?
	if @sCaseTypeKey='A'
	and dbo.fn_IsMultiClassAllowed(@sCountryKey, @sPropertyType, @sCaseTypeKey, @sCaseCategory) = 0
	Begin
		Declare @nRowCount int
		Declare @sNewCaseKey nvarchar(4000)
		Declare @sLocalClasses nvarchar(254)
		Declare @tLocalClasses table (	IDENT		int identity(1,1),
						LOCALCLASS 	nvarchar(5) collate database_default)

		Set @psNewCaseKeys = ''
		Set @sNewCaseKey = null
	
		Select 	@sLocalClasses = isnull( ltrim(TAB.REPLACEDATA),ltrim(C.LOCALCLASSES))
			from 	CASES C
			join	@tblCaseCopyAttrib TAB on (TAB.COPYAREA like '%_CASES')
			where 	C.CASEID = @psCaseKey
			and 	TAB.COPYAREAKEY = 'LOCALCLASSES'
				
		-- RFC42129 Cater for empty string as well as nulls
		If len(@sLocalClasses) > 0
		Begin
			-- Yes, so, for each local class to be copied, create a new case.
			Set @bCreateSingleCase = 0

			Insert into @tLocalClasses (LOCALCLASS)
				Select 	Parameter 
				from	dbo.fn_Tokenise(@sLocalClasses,',') order by Parameter asc
	
			Select @nRowCount = @@ROWCOUNT, @nErrorCode = @@ERROR
	
			If @nRowCount > 0 and @nErrorCode = 0
			Begin
				Declare @nCounter int
				Declare @sLocalClass nvarchar(5)
				
				Set @nCounter = 1
				While @nCounter <= @nRowCount and @nErrorCode = 0
				Begin
					
					Select 	@sLocalClass = LOCALCLASS
						from @tLocalClasses
						where IDENT = @nCounter
		
					Exec @nErrorCode = cs_CopyCase
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@psCaseKey = @psCaseKey,
						@psProfileName = @psProfileName,
						@psNewCaseKey = @sNewCaseKey OUTPUT,
						@psCaseFamilyReference = @psCaseFamilyReference,
						@psCountryKey = @psCountryKey,
						@psCountryName = @psCountryName,
						@psPropertyTypeKey = @psPropertyTypeKey,
						@psCaseCategoryKey = @psCaseCategoryKey,
						@psCaseCategoryDescription = @psCaseCategoryDescription,
						@psSubTypeKey = @psSubTypeKey,
						@psSubTypeDescription = @psSubTypeDescription,
						@psBasisKey = @psBasisKey,
						@psCaseStatusKey = @psCaseStatusKey,
						@psCaseStatusDescription = @psCaseStatusDescription,
						@psApplicationNumber = @psApplicationNumber,
						@pdtApplicationDate = @pdtApplicationDate,
						@psLocalClasses = @sLocalClass,
						@psIntClasses = @sLocalClass,						
						@pnNoOfClasses = 1,
						@pnPolicingBatchNo = @pnPolicingBatchNo,
						@psCaseReference = @psCaseReference,
						@psRelationshipKey = @psRelationshipKey,
						@psShortTitle = @psShortTitle,
						@pnOfficeKey = @pnOfficeKey,
						@psStem = @psStem,
                                                @pnInstructorKey = @pnInstructorKey,
                                                @pnOwnerKey = @pnOwnerKey,
                                                @pnStaffKey = @pnStaffKey,
                                                @psXmlCaseCopyData = @psXmlCaseCopyData,
						@psProgramId = @psProgramId,
						@PsCaseTypeKey = @sCaseTypeKey
		
					Set @nCounter = @nCounter + 1
	
					If len(@psNewCaseKeys)>0				
						Set @psNewCaseKeys = @psNewCaseKeys + ',' + @sNewCaseKey
					Else
						Set @psNewCaseKeys = @sNewCaseKey
				End
			End
		End
	End
End

If @nErrorCode = 0
and @bCreateSingleCase = 1
Begin
	declare @sLocClasses nvarchar(254)
	declare @sIntClasses nvarchar(254)
	declare @nNoOfClasses int	
	
	If @pbUseClassesOverride = 1
	Begin
		Set @sLocClasses = @psLocalClasses
		Set @sIntClasses = @psIntClasses
	End
	Else
	Begin
		Set @sLocClasses = @psDesignatedClasses
		Set @sIntClasses = @psDesignatedClasses
	End
	
	If isNull(@sLocClasses,@sIntClasses) is not null
	Begin
		Set @nNoOfClasses = dbo.fn_StringOccurrenceCount(',',isNull(@sLocClasses,@sIntClasses)) + 1
	End
        
	-- Some of the conditions are not met so only a single case will be created.
	Exec @nErrorCode = cs_CopyCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@psCaseKey = @psCaseKey,
		@psProfileName = @psProfileName,
		@psNewCaseKey = @psNewCaseKeys OUTPUT,
		@psCaseFamilyReference = @psCaseFamilyReference,
		@psCountryKey = @psCountryKey,
		@psCountryName = @psCountryName,
		@psPropertyTypeKey = @psPropertyTypeKey,
		@psCaseCategoryKey = @psCaseCategoryKey,
		@psCaseCategoryDescription = @psCaseCategoryDescription,
		@psSubTypeKey = @psSubTypeKey,
		@psSubTypeDescription = @psSubTypeDescription,
		@psBasisKey = @psBasisKey,
		@psCaseStatusKey = @psCaseStatusKey,
		@psCaseStatusDescription = @psCaseStatusDescription,
		@psApplicationNumber = @psApplicationNumber,
		@pdtApplicationDate = @pdtApplicationDate,
		@psLocalClasses = @sLocClasses,
		@psIntClasses = @sIntClasses,
		@pnNoOfClasses = @nNoOfClasses,
		@pnPolicingBatchNo = @pnPolicingBatchNo,
		@psCaseReference = @psCaseReference,
		@psRelationshipKey = @psRelationshipKey,
		@psShortTitle = @psShortTitle,
		@pnOfficeKey = @pnOfficeKey,
		@psStem = @psStem,
		@psXmlCaseCopyData = @psXmlCaseCopyData,
                @pnInstructorKey = @pnInstructorKey,
                @pnOwnerKey = @pnOwnerKey,
                @pnStaffKey = @pnStaffKey,
		@psProgramId = @psProgramId,
		@PsCaseTypeKey = @sCaseTypeKey

End

-- Update TRANSACTIONINFO records with the corresponding CASEIDs
If @nErrorCode = 0
and len(@psNewCaseKeys) > 0
Begin
	UPDATE TRANSACTIONINFO
	SET CASEID = C.CASEID
	FROM CASES C
	join dbo.fn_Tokenise(@psNewCaseKeys, ',') CK on (CK.Parameter = C.CASEID)
	join TRANSACTIONINFO T on (T.LOGTRANSACTIONNO = C.LOGTRANSACTIONNO and T.CASEID IS NULL)
	
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.csw_CopyCaseSupervisor to public
GO
