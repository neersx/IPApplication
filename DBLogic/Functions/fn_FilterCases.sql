-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterCases') and xtype='FN')
begin
	print '**** Drop function dbo.fn_FilterCases.'
	drop function dbo.fn_FilterCases
end
print '**** Creating function dbo.fn_FilterCases...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_FilterCases 
(	
	@pnUserIdentityId		int		= null, -- RFC463. @pnUserIdentityId must accept null (when called from InPro)
	@psAnySearch 			nvarchar(20),
	@pnCaseKey			int,		-- the CaseId of the Case
	@psCaseReference 		nvarchar(30),	
	@pnCaseReferenceOperator	tinyint,
	@pbWithinFileCover		bit,		-- if TRUE, select both the @psCaseReference Case, and any Cases where the @psCaseReference case is defined as the FileCover. @psCaseReference is never partial in this context.
	@psOfficialNumber 		nvarchar(36),
	@pnOfficialNumberOperator 	tinyint,
	@psNumberTypeKey		nvarchar(3),	-- used in conjunction with @psOfficialNumber if supplied, but will search for Cases with any official number of this type.
	@pnNumberTypeKeyOperator	tinyint,
	@psRelatedOfficialNumber	nvarchar(36),	-- the official number of a related case.  if partial, a "%" character is present.
	@pnRelatedOfficialNumberOperator tinyint,
	@psCaseTypeKey			nvarchar(1),	-- Include/Exclude based on next parameter
	@pnCaseTypeKeyOperator		tinyint,	-- 
	@psCountryCodes			nvarchar(1000),	-- A comma separated list of Country Codes.
	@pnCountryCodesOperator		tinyint,	 
	@pbIncludeDesignations		bit, 
	@psPropertyTypeKey		nchar(1),	
	@pnPropertyTypeKeyOperator	tinyint,
	@psCategoryKey			nvarchar(2),	-- Include/Exclude based on next parameter
	@pnCategoryKeyOperator		tinyint,	-- 
	@psSubTypeKey			nvarchar(2),	-- Include/Exclude based on next parameter
	@pnSubTypeKeyOperator		tinyint,
	@psClasses			nvarchar(max),
	@pnClassesOperator		tinyint,
	@psKeyword	 		nvarchar(50),
	@pnKeywordOperator		tinyint,
	@psFamilyKey	 		nvarchar(20),
	@pnFamilyKeyOperator		tinyint,
	@psTitle			nvarchar(254),	-- if partial, a "%" character is present.  The search should be case independent
	@pnTitleOperator		tinyint,
	@pnTypeOfMarkKey		int,		--  Include/Exclude based on next parameter
	@pnTypeOfMarkKeyOperator	tinyint,	-- 
	@pnInstructionKey		int,		-- applies only to instructions held against the Case (not inherited from the Case's Names)
	@pnInstructionKeyOperator	tinyint,
	@psInstructorKeys		nvarchar(max),	-- A comma separated list of Instructor NameKeys
	@pnInstructorKeysOperator	tinyint,
	@psAttentionNameKeys		nvarchar(max),	-- A comma separated list of NameKeys that appear as the correspondence name on any CaseName record for the Case.
	@pnAttentionNameKeysOperator	tinyint,
	@psNameKeys	 		nvarchar(max),	-- A comma separated list of NameKeys. Used in conjunction with @psNameTypeKey if supplied.
	@pnNameKeysOperator		tinyint,
	@psNameTypeKey	 		nvarchar(3),	-- Used in conjunction with @psNameKeys if supplied, but will search for Cases where any names exists with the name type otherwise.
	@pnNameTypeKeyOperator		tinyint,
	@psSignatoryNameKeys		nvarchar(max),	-- A comma separated list of NameKeys that act as NameType Signatory for the case.
	@pnSignatoryNameKeysOperator	tinyint,
	@psStaffNameKeys		nvarchar(max),	-- A comma separated list of NameKeys that act as Name Type Responsible Staff for the case.
	@pnStaffNameKeysOperator	tinyint,
	@psReferenceNo			nvarchar(80),
	@pnReferenceNoOperator		tinyint,
	@pnEventKey			int,
	@pbSearchByDueDate 		bit,
	@pbSearchByEventDate 		bit,
	@pnEventDateOperator		tinyint,
	@pdtEventFromDate		datetime,
	@pdtEventToDate			datetime,
	@pnDeadlineEventNo		int,
	@pnDeadlineEventDateOperator	tinyint,
	@pdtDeadlineEventFromDate	datetime,
	@pdtDeadlineEventToDate		datetime,
	@pnStatusKey	 		int,		-- if supplied, @pbCasePending, @pbCaseRegistered and @pbCaseDead are ignored.
	@pnStatusKeyOperator		tinyint,
	@pbPending			bit,		-- if TRUE, any cases with a status that is Live but not registered
	@pbRegistered			bit,		-- if TRUE, any cases with a status that is both Live and Registered
	@pbDead				bit,		-- if TRUE, any Cases with a status that is not Live.
	@pbRenewalFlag			bit,
	@pbLettersOnQueue		bit,
	@pbChargesOnQueue		bit,
	@pnAttributeTypeKey1		int,
	@pnAttributeKey1		int,
	@pnAttributeKey1Operator	tinyint,
	@pnAttributeTypeKey2		int,
	@pnAttributeKey2		int,
	@pnAttributeKey2Operator	tinyint,
	@pnAttributeTypeKey3		int,
	@pnAttributeKey3		int,
	@pnAttributeKey3Operator	tinyint,
	@pnAttributeTypeKey4		int,
	@pnAttributeKey4		int,
	@pnAttributeKey4Operator	tinyint,
	@pnAttributeTypeKey5		int,
	@pnAttributeKey5		int,
	@pnAttributeKey5Operator	tinyint,
	@psTextTypeKey1			nvarchar(2),
	@psText1			nvarchar(max),
	@pnText1Operator		tinyint,
	@psTextTypeKey2			nvarchar(2),
	@psText2			nvarchar(max),
	@pnText2Operator		tinyint,
	@psTextTypeKey3			nvarchar(2),
	@psText3			nvarchar(max),
	@pnText3Operator		tinyint,
	@psTextTypeKey4			nvarchar(2),
	@psText4			nvarchar(max),
	@pnText4Operator		tinyint,
	@psTextTypeKey5			nvarchar(2),
	@psText5			nvarchar(max),
	@pnText5Operator		tinyint,
	@psTextTypeKey6			nvarchar(2),
	@psText6			nvarchar(max),
	@pnText6Operator		tinyint,
	@psTextTypeKey7			nvarchar(2), --RFC421
	@psText7			nvarchar(max),
	@pnText7Operator		tinyint,
	@pnQuickIndexKey		int,
	@pnQuickIndexKeyOperator	tinyint,
	@pnOfficeKey			int,
	@pnOfficeKeyOperator	        tinyint	
	
)
Returns nvarchar(max)
-- FUNCTION :	fn_FilterCases
-- VERSION :	36
-- DESCRIPTION:	This function accepts the variables that may be used to filter Cases and
--		constructs a JOIN and WHERE clause. 

-- Modifications
-- =============
-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 03/06/2002	MF			Function created
-- 26/07/2002	MF			Add new parameters to support the CPA.NET interface.
-- 15/08/2002	SF			Add @pnQuickIndexKey for recent cases (quick index), and userIdentity
-- 20/08/2002	MF			Correction to search by Designations
-- 20/08/2002	MF			Correction to search by Events to allow any Event to be considered
-- 20/08/2002	MF			Correction to search for Pending cases.  No Status will be treated as Pending.
-- 05/09/2002	MF			To avoid a single search parameter with embedded commas being treated as a list
--					of comma separated parameters surround it with quotes.
-- 20/09/2002	MF		0.6	Additional search parameters added
-- 21/10/2002	MF		2.3.7	Add row level security
-- 25/10/2002	MF			If restriction is by an Event Date then there is not the requirement for the 
--					Event to be associated with an Action.
-- 29/10/2002	MF		2.3.8	If filtering by related Case without a Relationship specified then only look at
--					relationships that have the ShowFlag set on.
-- 29/10/2002	MF		2.3.9	Reinstate old row low level security due to error in previous code.
-- 06/11/2002	MF		7	Remove the searching on PickListSearch as this has moved into the calling procedure
-- 19 Nov 2002	JB		14	Moved the comment section to the top so version can be detected
-- 15 Apr 2003	JEK	RFC13	15	Remove implementation of the following site controls as they do not belong in a generic
--					filtering routine: Client Importance, Events Displayed, Client PublishAction, Publish Action
-- 28 Apr 2003	JEK	RFC97	16	Allow filtering on deadline event without dates.
-- 19 May 2003  TM      RFC52	17      Fixed bug - Case Search for Name Type is Null  
-- 17 Jul 2003	TM	RFC76	18	Case Insensitive searching	
-- 13 Aug 2003  TM	RFC224	19	Office level rules. Add @pnOfficeKey and @pnOfficeKeyOperator parameters 
--					and include case office as a filter criteria. In the Row level security section
--					modify the logic so that if the Row Security Uses Case Office site control is turned on,
--					CASES.OFFICEID should be used instead of the office obtained from TableAttributes.    
-- 01 Sep 2003	TM	RFC40	20	Case List SQL exseeds max size. Move 'If @psInstructorKeys is null
--					and (@psNameTypeKey is not null or @psNameKeys is not null)' logic in the  
--					@pnNameTypeKey, @pnNameKeysOperator, @psNameKeys and @pnNameKeysOperator section 
-- 05 Sep 2003	TM	RFC40	21	Error when all columns are selected for a Saved Query. For '@psReferenceNo is not NULL'
--					section add 'and @psInstructorKeys is null or @pnReferenceNoOperator between 2 and 6' condition
-- 15 Sep 2003	TM	RFC421	22	Field Names in Search Screens not consistent. Implement new parameters:@psTextTypeKey7,
--					@psText7 (mapped to 'Title') and @pnText7Operator. 
-- 17 Sep 2003	TM	RFC463	23	Review Due Date Report contents (SQA9232/SQA9235). Accept a @pnUserIdentityId of null.
--					Suppress the row level security if the @pnUserIdentityId is null.
--  6 Nov 2003	MF	RFC586	24	Explicitly identify variables that contain comma delimited strings with a new datatype.
-- 10 Mar 2004	TM	RFC1128	25	Remove the ROWACCESSDETAIL NAMETYPE, NAMENO and SUBSTITUTENAME from the best fit. 
-- 23 Jul 2004	TM	RFC1610	26	Increase the datasize of the @psReferenceNo from nvarchar(50) to nvarchar(80).
-- 02 Sep 2004	JEK	RFC1377	27	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 29 Sep 2004	MF	RFC1846	28	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 17 Dec 2004	TM	RFC1674	29	Remove the UPPER function around the IRN, KeyWord and Family to improve performance.
-- 07 Jul 2005	TM	RFC2329	30	Increase the size of all case category parameters and local variables to 2 characters.
-- 15 Dec 2008	MF	17136	31	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 14 Apr 2011	MF	RFC10475 32	Change nvarchar(4000) to nvarchar(max)
-- 16 Apr 2013	ASH	R13270 33	Change varchar(10) to varchar(11)
-- 05 Jul 2013	vql	R13629	34	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	35   Date conversion errors when creating cases and opening names in Chinese DB
-- 13 May 2020	DL	DR-58943	36	Ability to enter up to 3 characters for Number type code via client server	
		
AS
Begin
	-- declare variables
	declare @sReturnClause	nvarchar(max),
		@sFrom		nvarchar(max),
		@sWhere		nvarchar(max),
		@sInOperator	nvarchar(6),
		@sOperator	nvarchar(6),
		@sStatusFlag	nvarchar(5),
		@nImportance	int,		-- the level of importance of Events to be searched
		@sDisplayAction	nvarchar(3),	-- the default action allowed to be seen by the user
		@nSaveOperator	tinyint,
		@bColboolean	bit,		-- RFC224 - @bColboolean = 1 if the Row Security Uses Case Office site control is turned on 
	 	@sOfficeFilter	nvarchar(1000),	-- RFC224 - Dynamically set filter accordingly to the site control 
		@sRenewalAction	nvarchar(2)
		
	-- declare some constants
	declare @String			nchar(1),
		@Date			nchar(2),
		@Numeric		nchar(1),
		@Text			nchar(1),
		@CommaDelimitedString	nchar(2)

	Set	@String ='S'
	Set	@Date   ='DT'
	Set	@Numeric='N'
	Set	@Text   ='T'
	Set	@CommaDelimitedString='CS'

	-- Case Insensitive searching

	set @psAnySearch 		= upper(@psAnySearch)
	set @psCaseReference 		= upper(@psCaseReference)
	set @psOfficialNumber		= upper(@psOfficialNumber)
	set @psRelatedOfficialNumber	= upper(@psRelatedOfficialNumber)
	set @psKeyword			= upper(@psKeyword)
	set @psFamilyKey		= upper(@psFamilyKey)

	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"	WHERE 1=1"

 	set @sFrom  = char(10)+"	FROM      CASES XC"

	if (@psAnySearch is not NULL)
	begin
		set @psAnySearch = @psAnySearch+CASE WHEN(CHARINDEX ('%' , @psAnySearch)=0) THEN '%' END

		set @sFrom = @sFrom+char(10)+"	left join OFFICIALNUMBERS XO	on (XO.CASEID=XC.CASEID)"

		set @sWhere = 	@sWhere+char(10)+"	and " +
						"(XC.IRN              LIKE " + dbo.fn_WrapQuotes(@psAnySearch,0,0) + " OR
						 upper(XO.OFFICIALNUMBER)    LIKE " + dbo.fn_WrapQuotes(@psAnySearch,0,0) + ")"

	end

	else If @pnCaseKey is not null
	begin
		set @sWhere=@sWhere+char(10)+"	and	XC.CASEID="+cast(@pnCaseKey as varchar)
	end
	else begin
		if @psCaseReference is not NULL
		or @pnCaseReferenceOperator between 2 and 6
		begin
			if @pbWithinFileCover=1
			begin
				set @sFrom = @sFrom+char(10)+"	     join CASES XC1	on (XC1.CASEID      = XC.CASEID"+
						   +char(10)+"	                   	or  XC1.CASEID      = XC.FILECOVER)"
				set @sWhere = @sWhere+char(10)+"	and	XC1.IRN"+dbo.fn_ConstructOperator(@pnCaseReferenceOperator,@String,@psCaseReference, null,0)
			end
			else begin
				set @sWhere = @sWhere+char(10)+"	and	XC.IRN"+dbo.fn_ConstructOperator(@pnCaseReferenceOperator,@String,@psCaseReference, null,0)
			end
		end

		if @pnQuickIndexKey is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join IDENTITYINDEX IX	on (IX.IDENTITYID      = " + cast(@pnUserIdentityId as varchar(11)) +
					   +char(10)+"	                   	and  	IX.INDEXID      = " + cast(@pnQuickIndexKey as varchar(11)) + ")"
			set @sWhere = @sWhere+char(10)+"	and	XC.CASEID = IX.COLINTEGER"
		end

		if @pnOfficeKey is not NULL  
		or @pnOfficeKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	XC.OFFICEID"+dbo.fn_ConstructOperator(@pnOfficeKeyOperator,@Numeric,@pnOfficeKey, null,0)
		end

		if  @psOfficialNumber is not NULL 
		or  @pnOfficialNumberOperator between 2 and 6
		or  @psNumberTypeKey is not NULL
		or  @pnNumberTypeKeyOperator in (5,6)
		begin
			set @sFrom = @sFrom+char(10)+"	left join OFFICIALNUMBERS XO	on(XO.CASEID    = XC.CASEID"
		
			If  @pnNumberTypeKeyOperator in (5,6)
			and @psNumberTypeKey is not NULL
			begin 
				set @sFrom = @sFrom+char(10)+"	                               and XO.NUMBERTYPE="+dbo.fn_WrapQuotes(@psNumberTypeKey,0,0)+")"	
			end
			else begin
				set @sFrom = @sFrom+")"
			end

			If @pnNumberTypeKeyOperator in (5,6)
			or @psNumberTypeKey is not NULL
			begin
				set @sWhere= @sWhere+char(10)+"	and	XO.NUMBERTYPE"+dbo.fn_ConstructOperator(@pnNumberTypeKeyOperator,@String,@psNumberTypeKey, null,0)
			end

			if @psOfficialNumber is not NULL
			begin
				set @sWhere = @sWhere+char(10)+" and	upper(XO.OFFICIALNUMBER)"+dbo.fn_ConstructOperator(@pnOfficialNumberOperator,@String,@psOfficialNumber, null,0)
			end
		end

		if @psRelatedOfficialNumber is not NULL
		or @pnRelatedOfficialNumberOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	     join RELATEDCASE XRC	on (XRC.CASEID = XC.CASEID)"
					   +char(10)+"       join CASERELATION XCR	on (XCR.RELATIONSHIP=XRC.RELATIONSHIP"
					   +char(10)+"                             	and XCR.SHOWFLAG=1)"
					   +char(10)+"	left join OFFICIALNUMBERS XO1	on (XO1.CASEID = XRC.RELATEDCASEID)"

			set @sWhere = @sWhere+char(10)+"	and	isnull(upper(XO1.OFFICIALNUMBER),upper(XRC.OFFICIALNUMBER))"+dbo.fn_ConstructOperator(@pnRelatedOfficialNumberOperator,@String,@psRelatedOfficialNumber, null,0)
		end

		if @psCaseTypeKey is not NULL
		or @pnCaseTypeKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	XC.CASETYPE"+dbo.fn_ConstructOperator(@pnCaseTypeKeyOperator,@String,@psCaseTypeKey, null,0)
		end

		if @psCountryCodes is not NULL
		or @pnCountryCodesOperator between 2 and 6
		begin
			If @pbIncludeDesignations=1
			begin
				set @sWhere = @sWhere+char(10)+"	and	(XC.COUNTRYCODE"+dbo.fn_ConstructOperator(@pnCountryCodesOperator,@CommaDelimitedString,@psCountryCodes, null,0)
						     +char(10)+"	 or  EXISTS (	Select *  from COUNTRYGROUP XCG"
						     +char(10)+"			join COUNTRY XCT on (XCT.COUNTRYCODE=XCG.MEMBERCOUNTRY)"
						     +char(10)+"	             	where XCG.MEMBERCOUNTRY"+dbo.fn_ConstructOperator(@pnCountryCodesOperator,@CommaDelimitedString,@psCountryCodes, null,0)
						     +char(10)+"	             	and XCG.TREATYCODE=XC.COUNTRYCODE and XCT.ALLMEMBERSFLAG = 1 )"
						     +char(10)+"	 or  EXISTS (	Select *  from RELATEDCASE XRC1"
						     +char(10)+"	             	left join COUNTRYFLAGS XCF on (XCF.COUNTRYCODE=XC.COUNTRYCODE"
						     +char(10)+"	             	                           and XCF.FLAGNUMBER =XRC1.CURRENTSTATUS)"
						     +char(10)+"	             	where XRC1.COUNTRYCODE"+dbo.fn_ConstructOperator(@pnCountryCodesOperator,@CommaDelimitedString,@psCountryCodes, null,0)
						     +char(10)+"	             	and XRC1.RELATIONSHIP='DC1'"
						     +char(10)+"		     	and XRC1.RELATEDCASEID is null"
						     +char(10)+"	             	and XRC1.CASEID=XC.CASEID"

				-- If the filter is restricting on the status category (Pending, Registered and/or Dead)
				-- then the search must also take the Designated Countries status into consideration
				if @pbPending=1
					set @sStatusFlag='1 '
				if @pbRegistered=1	
					set @sStatusFlag=@sStatusFlag+'2 '
				if @pbDead=1
					set @sStatusFlag=@sStatusFlag+'0'

				set @sStatusFlag=replace(rtrim(@sStatusFlag),' ',',')

				if @sStatusFlag is not null
					set @sWhere=@sWhere+char(10)+"	             	and XCF.STATUS in ("+@sStatusFlag+") ))"
				else
					set @sWhere=@sWhere+"))"
			end
			-- IncludeDesignations is OFF
			else begin
				set @sWhere = @sWhere+char(10)+"	and	XC.COUNTRYCODE"+dbo.fn_ConstructOperator(@pnCountryCodesOperator,@CommaDelimitedString,@psCountryCodes, null,0)
			end
		end

		if @psPropertyTypeKey is not NULL
		or @pnPropertyTypeKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	XC.PROPERTYTYPE"+dbo.fn_ConstructOperator(@pnPropertyTypeKeyOperator,@String,@psPropertyTypeKey, null,0)
		end

		if @psCategoryKey is not NULL
		or @pnCategoryKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	XC.CASECATEGORY"+dbo.fn_ConstructOperator(@pnCategoryKeyOperator,@String,@psCategoryKey, null,0)
		end

		if @psSubTypeKey is not NULL
		or @pnSubTypeKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	XC.SUBTYPE"+dbo.fn_ConstructOperator(@pnSubTypeKeyOperator,@String,@psSubTypeKey, null,0)
		end

		if(@pnAttributeKey1 is not NULL and @pnAttributeKey1Operator is not null)
		or @pnAttributeKey1Operator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES XTA1 on (XTA1.PARENTTABLE='CASES'"
					   +char(10)+"	                               and XTA1.TABLETYPE="+convert(varchar,@pnAttributeTypeKey1)
					   +char(10)+"	                               and XTA1.GENERICKEY=convert(varchar,XC.CASEID))"

			set @sWhere =@sWhere+char(10)+"	and	XTA1.TABLECODE"+dbo.fn_ConstructOperator(@pnAttributeKey1Operator,@Numeric,@pnAttributeKey1, null,0)
		end

		if(@pnAttributeKey2 is not NULL and @pnAttributeKey2Operator is not null)
		or @pnAttributeKey2Operator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES XTA2 on (XTA2.PARENTTABLE='CASES'"
					   +char(10)+"	                               and XTA2.TABLETYPE="+convert(varchar,@pnAttributeTypeKey2)
					   +char(10)+"	                               and XTA2.GENERICKEY=convert(varchar,XC.CASEID))"

			set @sWhere =@sWhere+char(10)+"	and	XTA2.TABLECODE"+dbo.fn_ConstructOperator(@pnAttributeKey2Operator,@Numeric,@pnAttributeKey2, null,0)
		end

		if(@pnAttributeKey3 is not NULL and @pnAttributeKey3Operator is not null)
		or @pnAttributeKey3Operator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES XTA3 on (XTA3.PARENTTABLE='CASES'"
					   +char(10)+"	                               and XTA3.TABLETYPE="+convert(varchar,@pnAttributeTypeKey3)
					   +char(10)+"	                               and XTA3.GENERICKEY=convert(varchar,XC.CASEID))"

			set @sWhere =@sWhere+char(10)+"	and	XTA3.TABLECODE"+dbo.fn_ConstructOperator(@pnAttributeKey3Operator,@Numeric,@pnAttributeKey3, null,0)
		end

		if(@pnAttributeKey4 is not NULL and @pnAttributeKey4Operator is not null)
		or @pnAttributeKey4Operator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES XTA4 on (XTA4.PARENTTABLE='CASES'"
					   +char(10)+"	                               and XTA4.TABLETYPE="+convert(varchar,@pnAttributeTypeKey4)
					   +char(10)+"	                               and XTA4.GENERICKEY=convert(varchar,XC.CASEID))"

			set @sWhere =@sWhere+char(10)+"	and	XTA4.TABLECODE"+dbo.fn_ConstructOperator(@pnAttributeKey4Operator,@Numeric,@pnAttributeKey4, null,0)
		end

		if(@pnAttributeKey5 is not NULL and @pnAttributeKey5Operator is not null)
		or @pnAttributeKey5Operator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES XTA5 on (XTA5.PARENTTABLE='CASES'"
					   +char(10)+"	                               and XTA5.TABLETYPE="+convert(varchar,@pnAttributeTypeKey5)
					   +char(10)+"	                               and XTA5.GENERICKEY=convert(varchar,XC.CASEID))"

			set @sWhere =@sWhere+char(10)+"	and	XTA5.TABLECODE"+dbo.fn_ConstructOperator(@pnAttributeKey5Operator,@Numeric,@pnAttributeKey5, null,0)
		end

		if  @psTextTypeKey1 is not NULL
		and(@pnText1Operator in (5,6) or (@psText1 is not null and @pnText1Operator is not null))
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASETEXT XCT1 on (XCT1.CASEID=XC.CASEID"
					   +char(10)+"	                        and XCT1.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey1,0,0)+")"

			set @sWhere =@sWhere+char(10)+"	and	isnull(XCT1.SHORTTEXT, XCT1.TEXT)"+dbo.fn_ConstructOperator(@pnText1Operator,@Text,@psText1, null,0)
		end

		if  @psTextTypeKey2 is not NULL
		and(@pnText2Operator in (5,6) or (@psText2 is not null and @pnText2Operator is not null))
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASETEXT XCT2 on (XCT2.CASEID=XC.CASEID"
					   +char(10)+"	                        and XCT2.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey2,0,0)+")"

			set @sWhere =@sWhere+char(10)+"	and	isnull(XCT2.SHORTTEXT, XCT2.TEXT)"+dbo.fn_ConstructOperator(@pnText2Operator,@Text,@psText2, null,0)
		end

		if  @psTextTypeKey3 is not NULL
		and(@pnText3Operator in (5,6) or (@psText3 is not null and @pnText3Operator is not null))
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASETEXT XCT3 on (XCT3.CASEID=XC.CASEID"
					   +char(10)+"	                        and XCT3.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey3,0,0)+")"

			set @sWhere =@sWhere+char(10)+"	and	isnull(XCT3.SHORTTEXT, XCT3.TEXT)"+dbo.fn_ConstructOperator(@pnText3Operator,@Text,@psText3, null,0)
		end

		if  @psTextTypeKey4 is not NULL
		and(@pnText4Operator in (5,6) or (@psText4 is not null and @pnText4Operator is not null))
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASETEXT XCT4 on (XCT4.CASEID=XC.CASEID"
					   +char(10)+"	                        and XCT4.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey4,0,0)+")"

			set @sWhere =@sWhere+char(10)+"	and	isnull(XCT4.SHORTTEXT, XCT4.TEXT)"+dbo.fn_ConstructOperator(@pnText4Operator,@Text,@psText4, null,0)
		end

		if  @psTextTypeKey5 is not NULL
		and(@pnText5Operator in (5,6) or (@psText5 is not null and @pnText5Operator is not null))
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASETEXT XCT5 on (XCT5.CASEID=XC.CASEID"
					   +char(10)+"	                        and XCT5.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey5,0,0)+")"

			set @sWhere =@sWhere+char(10)+"	and	isnull(XCT5.SHORTTEXT, XCT5.TEXT)"+dbo.fn_ConstructOperator(@pnText5Operator,@Text,@psText5, null,0)
		end

		if  @psTextTypeKey6 is not NULL
		and(@pnText6Operator in (5,6) or (@psText6 is not null and @pnText6Operator is not null))
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASETEXT XCT6 on (XCT6.CASEID=XC.CASEID"
					   +char(10)+"	                        and XCT6.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey6,0,0)+")"

			set @sWhere =@sWhere+char(10)+"	and	isnull(XCT6.SHORTTEXT, XCT6.TEXT)"+dbo.fn_ConstructOperator(@pnText6Operator,@Text,@psText6, null,0)
		end

		-- RFC421 Advanced Case Search fields. @psText7 is mapped to 'Title' 
		if  @psTextTypeKey7 is not NULL
		and(@pnText7Operator in (5,6) or (@psText7 is not null and @pnText7Operator is not null))
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASETEXT XCT7 on (XCT7.CASEID=XC.CASEID"
					   +char(10)+"	                        and XCT7.TEXTTYPE="+dbo.fn_WrapQuotes(@psTextTypeKey7,0,0)+")"

			set @sWhere =@sWhere+char(10)+"	and	isnull(XCT7.SHORTTEXT, XCT7.TEXT)"+dbo.fn_ConstructOperator(@pnText7Operator,@Text,@psText7, null,0)
		end

		if @psClasses is not NULL
		or @pnClassesOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	     join CASETEXT XCT	on (XCT.CASEID     = XC.CASEID)"

			set @sWhere = @sWhere+char(10)+"	and	XCT.CLASS"+dbo.fn_ConstructOperator(@pnClassesOperator,@CommaDelimitedString,@psClasses, null,0)
		end

		if @psKeyword is not NULL
		or @pnKeywordOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASEWORDS XCW	on (XCW.CASEID     = XC.CASEID)"
				           +char(10)+"	left join KEYWORDS XKW	on (XKW.KEYWORDNO  = XCW.KEYWORDNO)"
		
			set @sWhere = @sWhere+char(10)+"	and	XKW.KEYWORD"+dbo.fn_ConstructOperator(@pnKeywordOperator,@String,@psKeyword, null,0)
		end

		if @psFamilyKey is not NULL
		or @pnFamilyKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	XC.FAMILY"+dbo.fn_ConstructOperator(@pnFamilyKeyOperator,@String,@psFamilyKey, null,0)
		end

		if @psTitle is not NULL
		or @pnTitleOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	upper(XC.TITLE)"+dbo.fn_ConstructOperator(@pnTitleOperator,@String,upper(@psTitle), null,0)
		end

		if @pnTypeOfMarkKey is not NULL
		or @pnTypeOfMarkKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"	and	XC.TYPEOFMARK"+dbo.fn_ConstructOperator(@pnTypeOfMarkKeyOperator,@Numeric,@pnTypeOfMarkKey, null,0)
		end

		if @pnInstructionKey is not NULL
		or @pnInstructionKeyOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join NAMEINSTRUCTIONS XNI	on (XNI.CASEID     = XC.CASEID)"

			set @sWhere = @sWhere+char(10)+"	and	XNI.INSTRUCTIONCODE"+dbo.fn_ConstructOperator(@pnInstructionKeyOperator,@Numeric,@pnInstructionKey, null,0)
		end

		if @psInstructorKeys is not null
		or @pnInstructorKeysOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASENAME XCNI	on (XCNI.CASEID     = XC.CASEID"
					   +char(10)+"	                        and XCNI.NAMETYPE   = 'I'"
					   +char(10)+"	                        and(XCNI.EXPIRYDATE is NULL or XCNI.EXPIRYDATE >getdate()))"

			set @sWhere = @sWhere+char(10)+"	and	XCNI.NAMENO"+dbo.fn_ConstructOperator(@pnInstructorKeysOperator,@Numeric,@psInstructorKeys, null,0)
		end

		if @psAttentionNameKeys is not null
		or @pnAttentionNameKeysOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASENAME XAT	on (XAT.CASEID     = XC.CASEID"
					   +char(10)+"	                        and(XAT.EXPIRYDATE is NULL or XAT.EXPIRYDATE >getdate()))"

			set @sWhere = @sWhere+char(10)+"	and	XAT.CORRESPONDNAME"+dbo.fn_ConstructOperator(@pnAttentionNameKeysOperator,@Numeric,@psAttentionNameKeys, null,0)
		end

		

        If @psNameTypeKey is not null
	or @pnNameTypeKeyOperator between 2 and 6
	or @psNameKeys is not null
	or @pnNameKeysOperator between 2 and 6
	Begin
		Set @nSaveOperator = null

		set @sFrom = @sFrom

		-- If either Operator is set to NOT NULL then use EXISTS
		If @pnNameTypeKeyOperator  =5
		or @pnNameKeysOperator     =5
		Begin
			set @sWhere =@sWhere+char(10)+"and exists"
		End

		-- If either Operator is set to IS NULL then use NOT EXISTS
		Else
		If @pnNameTypeKeyOperator  =6
		or @pnNameKeysOperator     =6
		Begin
			set @sWhere =@sWhere+char(10)+"and not exists"
		End

		-- If either Operator is set to EQUAL then use EXISTS
		Else 
		If @pnNameTypeKeyOperator  =0
		or @pnNameKeysOperator     =0
		Begin
			set @sWhere =@sWhere+char(10)+"and exists"
		End

		-- If either Operator is set to NOT EQUAL then use NOT EXISTS
		Else 
		If @pnNameTypeKeyOperator       =1
		or @pnNameKeysOperator          =1
		Begin
			set @sWhere =@sWhere+char(10)+"and not exists"
		End

		Else Begin
			set @sWhere =@sWhere+char(10)+"and exists"
		End


		set @sWhere=@sWhere+char(10)+"(select * from CASENAME XCN"
				   +char(10)+" where XCN.CASEID = XC.CASEID"
			           +char(10)+" and(XCN.EXPIRYDATE is NULL or XCN.EXPIRYDATE>getdate())"
		
				  
		If  @psNameTypeKey is not null
		Begin
			-- Change the Operator because of the NOT EXISTS clause under certain situations
			If  @pnNameTypeKeyOperator=1
			and(@pnNameKeysOperator in (1,8) OR @pnNameKeysOperator is NULL)
			Begin
				set @nSaveOperator=@pnNameTypeKeyOperator
				set @pnNameTypeKeyOperator=0
			End
			
			If @pnNameTypeKeyOperator not in (5,6)
				set @sWhere=@sWhere+char(10)+" and XCN.NAMETYPE"+dbo.fn_ConstructOperator(@pnNameTypeKeyOperator,@String,@psNameTypeKey, null,0)

			If @nSaveOperator is not null
				set @pnNameTypeKeyOperator=@nSaveOperator
		End

		If @psNameKeys is not null
		Begin
			If  @pnNameKeysOperator     =1
			and @pnNameTypeKeyOperator  =5
			Begin
				set @pnNameKeysOperator=0
					set @sWhere=@sWhere+")"
					   	   +char(10)+"and not exists"
						   +char(10)+"(select * from CASENAME XCN1"
						   +char(10)+" where XCN1.CASEID = XC.CASEID"
			                           +char(10)+" and(XCN1.EXPIRYDATE is NULL or XCN1.EXPIRYDATE>getdate())"	
						   +char(10)+" and XCN1.NAMENO"+dbo.fn_ConstructOperator(@pnNameKeysOperator,@Numeric,@psNameKeys, null,0)
			End
						   		

			Else Begin
				If  @pnNameKeysOperator=1
				and(@pnNameTypeKeyOperator in (1, 5, 6, 8) or @pnNameTypeKeyOperator is NULL)
					set @pnNameKeysOperator=0

				If @pnNameKeysOperator not in (5,6)
				Begin
					set @sWhere =@sWhere+char(10)+" and XCN.NAMENO"+dbo.fn_ConstructOperator(@pnNameKeysOperator,@Numeric,@psNameKeys, null,0)
				End
			End
		End
		
		if @psReferenceNo is not NULL
		or @pnReferenceNoOperator between 2 and 6
		Begin
			If @psInstructorKeys is null
			Begin
				set @sWhere=@sWhere+char(10)+"	and	upper(XCN.REFERENCENO)"+dbo.fn_ConstructOperator(@pnReferenceNoOperator,@String,upper(@psReferenceNo), null,0)
			End
		End

		set @sWhere =@sWhere+")"
	End
		

		if @psSignatoryNameKeys is not null
		or @pnSignatoryNameKeysOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join CASENAME XSIG	on (XSIG.CASEID     = XC.CASEID"
					   +char(10)+"	                        and XSIG.NAMETYPE   = 'SIG'"
					   +char(10)+"	                        and(XSIG.EXPIRYDATE is NULL or XSIG.EXPIRYDATE >getdate()))"

			set @sWhere = @sWhere+char(10)+"	and	XSIG.NAMENO"+dbo.fn_ConstructOperator(@pnSignatoryNameKeysOperator,@Numeric,@psSignatoryNameKeys, null,0)
		end

		if @psStaffNameKeys is not null
		or @pnStaffNameKeysOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	     join CASENAME XEMP	on (XEMP.CASEID     = XC.CASEID"
					   +char(10)+"	                        and XEMP.NAMETYPE   = 'EMP'"
					   +char(10)+"	                        and(XEMP.EXPIRYDATE is NULL or XEMP.EXPIRYDATE >getdate()))"

			set @sWhere = @sWhere+char(10)+"	and	XEMP.NAMENO"+dbo.fn_ConstructOperator(@pnStaffNameKeysOperator,@Numeric,@psStaffNameKeys, null,0)
		end
		
		if @psReferenceNo is not NULL
		or @pnReferenceNoOperator between 2 and 6
		begin
			if @psInstructorKeys is not null
				set @sWhere=@sWhere+char(10)+"	and	upper(XCNI.REFERENCENO)"+dbo.fn_ConstructOperator(@pnReferenceNoOperator,@String,upper(@psReferenceNo), null,0)
			else
			if @psNameKeys is null
			and @psNameTypeKey is null 
			begin
				if @psAttentionNameKeys is not null
				begin
					set @sWhere=@sWhere+char(10)+"	and	upper(XAT.REFERENCENO)"+dbo.fn_ConstructOperator(@pnReferenceNoOperator,@String,upper(@psReferenceNo), null,0)
				end
				else begin
					set @sFrom = @sFrom+char(10)+"	left join CASENAME XREF	on (XREF.CASEID    = XC.CASEID"
							   +char(10)+"				and(XREF.EXPIRYDATE is null or XREF.EXPIRYDATE>getdate()))"
					set @sWhere=@sWhere+char(10)+"	and	upper(XREF.REFERENCENO)"+dbo.fn_ConstructOperator(@pnReferenceNoOperator,@String,upper(@psReferenceNo), null,0)
				end
			end
		end

		if  @pnEventDateOperator=6
		and @pnEventKey is not NULL
		begin
			-- Find Cases where the Event does not exist

			set @sFrom = @sFrom+char(10)+"	left join CASEEVENT XCE on (XCE.CASEID	= XC.CASEID"
					   +char(10)+"	                        and XCE.EVENTNO="+convert(varchar,@pnEventKey)+")"

			set @sWhere= @sWhere+char(10)+"	and XCE.CASEID is NULL"
		end
		else if (@pbSearchByDueDate=0 OR @pbSearchByDueDate is null)
		     and(@pnEventKey       is not NULL
		      or @pdtEventFromDate is not NULL
		      or @pdtEventToDate   is not NULL)
		begin
			If  (@pbSearchByEventDate is NULL or @pbSearchByEventDate=0)
				set @pbSearchByEventDate=1

			set @sFrom = @sFrom+char(10)+"	     join CASEEVENT XCE	on (XCE.CASEID     = XC.CASEID)"

			if @pnEventKey is not NULL
			begin
				set @sWhere = @sWhere+char(10)+"	and	XCE.EVENTNO="+convert(varchar,@pnEventKey)
			end

			set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG between 1 and 8"

			if @pdtEventFromDate is not null
			or @pdtEventToDate   is not null
			begin
				set @sWhere =  @sWhere+char(10)+"	and	XCE.EVENTDATE"+dbo.fn_ConstructOperator(@pnEventDateOperator,@Date,convert(nvarchar,@pdtEventFromDate,112), convert(nvarchar,@pdtEventToDate,112),0)
			end
		end
		else if  @pbSearchByDueDate=1
		     and(@pnEventKey       is not NULL
		      or @pdtEventFromDate is not NULL
		      or @pdtEventToDate   is not NULL)
		begin
			-- Extract the Action used to identify the Renewal process so that the
			-- Next Renewal Date will only be considered due if it is attached to the
			-- specific Action
			Select @sRenewalAction=S.COLCHARACTER
			from SITECONTROL S
			where CONTROLID='Main Renewal Action'

			If  (@pbSearchByDueDate   is NULL or @pbSearchByDueDate=0)
			and (@pbSearchByEventDate is NULL or @pbSearchByEventDate=0)
				set @pbSearchByEventDate=1

			-- If the Case search is restricted to Event Due Dates then the events to be considered
			-- must be attached to an open action.
			set @sFrom = @sFrom+char(10)+"	     join OPENACTION XOA on (XOA.CASEID     = XC.CASEID"
					   +char(10)+"				 and XOA.POLICEEVENTS="+CASE WHEN(@pbSearchByDueDate=1) THEN "1)" ELSE "XOA.POLICEEVENTS)" END
					   +char(10)+"	     join ACTIONS XA	   on (XA.ACTION     = XOA.ACTION)"
					   +char(10)+"	     join EVENTCONTROL XEC on (XEC.CRITERIANO= XOA.CRITERIANO)"
					   +char(10)+"	     join CASEEVENT XCE	on (XCE.CASEID     = XC.CASEID"
					   +char(10)+"				and XCE.EVENTNO    = XEC.EVENTNO"
					   +char(10)+"				and XCE.CYCLE      = CASE WHEN(XA.NUMCYCLESALLOWED>1) THEN XOA.CYCLE ELSE XCE.CYCLE END)"

			if @pnEventKey is not NULL
			begin
				set @sWhere = @sWhere+char(10)+"	and	XEC.EVENTNO="+convert(varchar,@pnEventKey)
			end

			if  @pbSearchByDueDate  =1
			and @pbSearchByEventDate=1
			begin
				set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG between 0 and 8"

				if @pdtEventFromDate is not null
				or @pdtEventToDate   is not null
				begin
					set @sWhere =  @sWhere+char(10)+"	and	isnull(XCE.EVENTDATE,XCE.EVENTDUEDATE)"+dbo.fn_ConstructOperator(@pnEventDateOperator,@Date,convert(nvarchar,@pdtEventFromDate,112), convert(nvarchar,@pdtEventToDate,112),0)
				end
			end
			else if @pbSearchByDueDate=1
			begin
				set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG=0"

				if @pdtEventFromDate is not null
				or @pdtEventToDate   is not null
				begin
					set @sWhere =  @sWhere+char(10)+"	and	XCE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@pnEventDateOperator,@Date,convert(nvarchar,@pdtEventFromDate,112), convert(nvarchar,@pdtEventToDate,112),0)
				end

				-- The Next Renewal Date will only be considered due if it is attached
				-- to the specific Action
				If @sRenewalAction is not null
				Begin
					Set @sWhere = @sWhere+char(10)+
						"	and	((XOA.ACTION='"+@sRenewalAction+"' and XCE.EVENTNO=-11) OR XCE.EVENTNO<>-11)"
				End
			end
			else begin
				set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG between 1 and 8"

				if @pdtEventFromDate is not null
				or @pdtEventToDate   is not null
				begin
					set @sWhere =  @sWhere+char(10)+"	and	XCE.EVENTDATE"+dbo.fn_ConstructOperator(@pnEventDateOperator,@Date,convert(nvarchar,@pdtEventFromDate,112), convert(nvarchar,@pdtEventToDate,112),0)
				end
			end
		end

		-- Search explicitly by the Due Date

		if @pnDeadlineEventNo        is not NULL
		or @pdtDeadlineEventFromDate is not NULL
		or @pdtDeadlineEventToDate   is not NULL
		begin

			-- Extract the Action used to identify the Renewal process so that the
			-- Next Renewal Date will only be considered due if it is attached to the
			-- specific Action
			If @sRenewalAction is NULL
			Begin
				Select @sRenewalAction=S.COLCHARACTER
				from SITECONTROL S
				where CONTROLID='Main Renewal Action'
			End

			-- Due Dates must be attached to an Open Action
			set @sFrom = @sFrom+char(10)+"	     join OPENACTION XOA1   on (XOA1.CASEID      = XC.CASEID"
					   +char(10)+"				    and XOA1.POLICEEVENTS=1)"
					   +char(10)+"	     join ACTIONS XA1	    on (XA1.ACTION     = XOA1.ACTION)"
					   +char(10)+"	     join EVENTCONTROL XEC1 on (XEC1.CRITERIANO= XOA1.CRITERIANO)"
					   +char(10)+"	     join CASEEVENT XCE1    on (XCE1.CASEID    = XC.CASEID"
					   +char(10)+"                              and XCE1.EVENTNO   = XEC1.EVENTNO"
					   +char(10)+"                              and XCE1.CYCLE     = CASE WHEN(XA1.NUMCYCLESALLOWED>1) THEN XOA1.CYCLE ELSE XCE1.CYCLE END)"

			if @pnDeadlineEventNo is not NULL
			begin
				set @sWhere = @sWhere+char(10)+"	and	XEC1.EVENTNO="+convert(varchar,@pnDeadlineEventNo)
			end

			set @sWhere = @sWhere+char(10)+"	and	XCE1.OCCURREDFLAG=0"

			If @pdtDeadlineEventFromDate is not NULL	-- RFC97
			or @pdtDeadlineEventToDate   is not NULL
			begin
				set @sWhere =  @sWhere+char(10)+"	and	XCE1.EVENTDUEDATE"+dbo.fn_ConstructOperator(@pnDeadlineEventDateOperator,@Date,convert(nvarchar,@pdtDeadlineEventFromDate,112), convert(nvarchar,@pdtDeadlineEventToDate,112),0)
			end

			-- The Next Renewal Date will only be considered due if it is attached
			-- to the specific Action
			If @sRenewalAction is not null
			Begin
				Set @sWhere = @sWhere+char(10)+
					"	and	((XOA1.ACTION='"+@sRenewalAction+"' and XCE1.EVENTNO=-11) OR XCE1.EVENTNO<>-11)"
			End
		end

-- RFC13 -------------------------------------------------------------------------------------------
-- If implemented at all, this logic belongs in the calling code.
--
--		-- If Events are included in the search then restrict the events to those within the 
--		-- importance level range depending on whether the user is external or not.
--		-- Where there is a default Action then also restrict the Events by that Action
--
--		if @pnEventKey        is not NULL
--		or @pdtEventFromDate is not NULL
--		or @pdtEventToDate   is not NULL
--		begin
--			select	@nImportance=
--					CASE WHEN(EXTERNALUSERFLAG > 1)	THEN isnull(S1.COLINTEGER,0)
--									ELSE isnull(S2.COLINTEGER,0)
--					END,
--				@sDisplayAction  =	
--					CASE WHEN(EXTERNALUSERFLAG > 1) THEN S3.COLCHARACTER 
--									ELSE S4.COLCHARACTER
--					END
--			from USERS U
--			left join SITECONTROL S1	on (upper(S1.CONTROLID)='CLIENT IMPORTANCE')
--			left join SITECONTROL S2	on (upper(S2.CONTROLID)='EVENTS DISPLAYED')
--			left join SITECONTROL S3	on (upper(S3.CONTROLID)='CLIENT PUBLISHACTION')
--			left join SITECONTROL S4	on (upper(S4.CONTROLID)='PUBLISH ACTION')
--			where U.USERID=user
--
--			If  @nImportance is not null
--			begin
--				set @sWhere = @sWhere+char(10)+"	and	(XEC.IMPORTANCELEVEL>"+convert(varchar,@nImportance)+" OR XCE.CREATEDBYCRITERIA is null)"
--
--				If charindex('join EVENTCONTROL XEC',@sFrom)=0
--				begin
--					set @sFrom = @sFrom+char(10)+"	     left join EVENTCONTROL XEC on (XEC.CRITERIANO= XCE.CREATEDBYCRITERIA"
--							   +char(10)+"			  	        and XEC.EVENTNO    =XCE.EVENTNO)"
--				end
--			end
--
--			If  @sDisplayAction is not null
--			and charindex('join OPENACTION XOA',@sFrom)>0
--			begin
--				set @sWhere = @sWhere+char(10)+"	and	XOA.ACTION='"+@sDisplayAction+"'"
--			end
--		end
--
--------------------------------------------------------------------------------------------------------------------

		-- When a specific status is being filtered on check to see if it is a Renewal Status and if so
		-- then also join on the RenewalStatus

		if @pnStatusKey is not NULL
		OR @pnStatusKeyOperator between 2 and 6
		begin
			if exists (select * from STATUS where STATUSCODE=@pnStatusKey and RENEWALFLAG=1)
			begin
				set @sFrom=@sFrom+char(10)+"	left join PROPERTY XP	on (XP.CASEID      = XC.CASEID)"
						 +char(10)+"	left join STATUS XRS	on (XRS.STATUSCODE = XP.RENEWALSTATUS)"

				set @sWhere = @sWhere+char(10)+"	and	XRS.STATUSCODE"+dbo.fn_ConstructOperator(@pnStatusKeyOperator,@Numeric,@pnStatusKey, null,0)
			end
			else begin
				set @sFrom=@sFrom+char(10)+"	left join STATUS XST	on (XST.STATUSCODE = XC.STATUSCODE)"

				set @sWhere = @sWhere+char(10)+"	and	XST.STATUSCODE"+dbo.fn_ConstructOperator(@pnStatusKeyOperator,@Numeric,@pnStatusKey, null,0)
			end
		end
		else begin
			if @pbRenewalFlag=1
			or @pbDead       =1
			or @pbRegistered =1
			or @pbPending    =1
			begin
				set @sFrom=@sFrom+char(10)+"	left join STATUS XST	on (XST.STATUSCODE = XC.STATUSCODE)"
						 +char(10)+"	left join PROPERTY XP	on (XP.CASEID      = XC.CASEID)"
						 +char(10)+"	left join STATUS XRS	on (XRS.STATUSCODE = XP.RENEWALSTATUS)"
			end

			-- If the RenewalFlag is set on then there must be a RenewalStatus
			if @pbRenewalFlag=1
			begin
				set @sWhere = @sWhere+char(10)+"	and    	XP.RENEWALSTATUS is not null"
			end

			-- Dead cases only
			If   @pbDead      =1
			and (@pbRegistered=0 or @pbRegistered is null)
			and (@pbPending   =0 or @pbPending    is null)
			begin
				set @sWhere = @sWhere+char(10)+"	and    (XST.LIVEFLAG=0 OR XRS.LIVEFLAG=0)"
			end
	
			-- Registered cases only
			else
			if  (@pbDead      =0 or @pbDead       is null)
			and (@pbRegistered=1)
			and (@pbPending   =0 or @pbPending    is null)
			begin
				set @sWhere = @sWhere+char(10)+"	and	XST.LIVEFLAG=1"
					    	     +char(10)+"	and	XST.REGISTEREDFLAG=1"
					     	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
			end

			-- Pending cases only
			else
			if  (@pbDead      =0 or @pbDead       is null)
			and (@pbRegistered=0 or @pbRegistered is null)
			and (@pbPending   =1)
			begin
				-- Note the absence of a Case Status will be treated as "Pending"
				set @sWhere = @sWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=0) OR XST.STATUSCODE is null)"
					    	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
			end

			-- Pending cases or Registed cases only (not dead)
			else
			if  (@pbDead      =0 or @pbDead       is null)
			and (@pbRegistered=1)
			and (@pbPending   =1)
			begin
				set @sWhere = @sWhere+char(10)+"	and    (XST.LIVEFLAG=1 or XST.STATUSCODE is null)"
					     	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
			end

			-- Registered cases or Dead cases
			else
			if  (@pbDead      =1)
			and (@pbRegistered=1)
			and (@pbPending   =0 or @pbPending is null)
			begin
				set @sWhere = @sWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=1) OR XST.LIVEFLAG =0 OR XRS.LIVEFLAG=0)"
			end

			-- Pending cases or Dead cases
			else
			if  (@pbDead      =1)
			and (@pbRegistered=0 or @pbRegistered is null)
			and (@pbPending   =1)
			begin
				set @sWhere = @sWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=0) OR XST.STATUSCODE is null OR XST.LIVEFLAG =0 OR XRS.LIVEFLAG=0)"
	
			end
		end

		if @pbLettersOnQueue=1
		begin
			set @sWhere = @sWhere+char(10)+"	and exists (select * from ACTIVITYREQUEST XAR1 where XAR1.CASEID=XC.CASEID and XAR1.LETTERNO is not null and XAR1.ACTIVITYCODE=3204)"
		end

		if @pbChargesOnQueue=1
		begin
			set @sWhere = @sWhere+char(10)+"	and exists (select * from ACTIVITYREQUEST XAR2 where XAR2.CASEID=XC.CASEID and XAR2.LETTERNO is null and XAR2.ACTIVITYCODE=3202)"
		end
	end

	-- External Users have a security restriction to only allow them to see Cases of a particular CaseType
	-- and only Cases that are linked to a specific Name that they have access to.

	if (exists (	select * from USERIDENTITY
			where IDENTITYID = @pnUserIdentityId
			AND ISEXTERNALUSER = 1))
	begin
		set @sFrom = @sFrom+char(10)+"	     join SITECONTROL XS on (XS.CONTROLID='Client Case Types')"
				   +char(10)+"	     join SITECONTROL XT on (XT.CONTROLID='Client Name Types')"
				   +char(10)+"	     join NAMEALIAS XNA  on (XNA.ALIAS=user"
				   +char(10)+"				 and XNA.ALIASTYPE='IU')"
				   +char(10)+"	     join CASENAME XCN1	on (XCN1.CASEID=XC.CASEID"
				   +char(10)+"				and XCN1.NAMENO=XNA.NAMENO)"

		set @sWhere = @sWhere+char(10)+"	and	patindex('%'+XC.CASETYPE+'%',XS.COLCHARACTER)>0"

		if @psNameKeys is not NULL
		or @psNameTypeKey     is not NULL
		begin
			set @sWhere = @sWhere 	+char(10)+"	and	patindex('%'+XCN.NAMETYPE+'%',XT.COLCHARACTER)>0"
		end
		else begin
			set @sWhere = @sWhere 	+char(10)+"	and	patindex('%'+XCN1.NAMETYPE+'%',XT.COLCHARACTER)>0"
		end

	end

	-- If Row level security is in use for Cases then add a further restriction to ensure that
	-- only the Cases the user may see is returned. 

	if exists (	SELECT *
			FROM IDENTITYROWACCESS I
			join ROWACCESSDETAIL R	on (R.ACCESSNAME=I.ACCESSNAME)
			WHERE RECORDTYPE = 'C')
	-- RFC463 - suppress the row level security if the @pnUserIdentityId is null 
	and @pnUserIdentityId is not null
	Begin

		-- Find out if the Row Security Uses Case Office site control is turned on (@bColboolean = 1)
		
		Select  @bColboolean = COLBOOLEAN
		from SITECONTROL
		where CONTROLID = 'Row Security Uses Case Office'
		
		-- If the Row Security Uses Case Office site control is turned on (@bColboolean = 1) then use CASES.OFFICEID
		-- otherwise use the Office obtained from TableAttributes.
	
		Set @sOfficeFilter = CASE WHEN @bColboolean = 1 THEN    		"left join CASENAME XCN 	on   XCN.CASEID = XC.CASEID"
									+char(10)+"	 join ROWACCESSDETAIL XRAD	on  (XRAD.ACCESSNAME   = XIA.ACCESSNAME"
									+char(10)+"	 and (XRAD.OFFICE = XC.OFFICEID or   XRAD.OFFICE       is null)" 
	
							        ELSE			"left join TABLEATTRIBUTES XTA 	on (XTA.PARENTTABLE='CASES'"
							           	+char(10)+"		and XTA.TABLETYPE=44"
									+char(10)+"		and XTA.GENERICKEY=convert(varchar, XC.CASEID))"
								   	+char(10)+"	 left join CASENAME XCN 	on XCN.CASEID = XC.CASEID"
								   	+char(10)+"	 join ROWACCESSDETAIL XRAD	on  (XRAD.ACCESSNAME   = XIA.ACCESSNAME"
								   	+char(10)+"	 and (XRAD.OFFICE = XTA.TABLECODE or   XRAD.OFFICE       is null)"
				 	END 
		
		-- The row level security SQL has been explicitly coded in the manner below to address
		-- performance problems associated with the initial technique used that required a subselect.  This
		-- method utilises a derived table.

		set @sWhere = @sWhere 	+char(10)+"	and	Substring("
					+char(10)+"		(Select MAX (   CASE when XRAD.OFFICE       is null then '0' else '1' end +"
					+char(10)+"				CASE when XRAD.CASETYPE     is null then '0' else '1' end +"
					+char(10)+"				CASE when XRAD.PROPERTYTYPE is null then '0' else '1' end +"								
					+char(10)+"				CASE when XRAD.SECURITYFLAG < 10    then '0' else ''  end +"
					+char(10)+"				convert(nvarchar(2),XRAD.SECURITYFLAG)"
					+char(10)+"			)"
					+char(10)+"		from IDENTITYROWACCESS XIA"
					+char(10)+"		join USERIDENTITY XUI on XUI.IDENTITYID = XIA.IDENTITYID"
					+char(10)+		@sOfficeFilter
					+char(10)+"						and (XRAD.CASETYPE     = XC.CASETYPE     or XRAD.CASETYPE     is null)"
					+char(10)+"						and (XRAD.PROPERTYTYPE = XC.PROPERTYTYPE or XRAD.PROPERTYTYPE is null)"					
					+char(10)+"						and  XRAD.RECORDTYPE = 'C')"
					+char(10)+"		where XIA.IDENTITYID=" + convert(varchar,@pnUserIdentityId)
					+char(10)+"		),4,2) in (  '01','03','05','07','09','11','13','15' )"
	End

	set @sReturnClause=@sFrom+char(10)+@sWhere
	Return ltrim(rtrim(@sReturnClause))
End
GO

grant execute on dbo.fn_FilterCases  to public
GO
