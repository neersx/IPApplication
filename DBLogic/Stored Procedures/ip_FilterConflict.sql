-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_FilterConflict
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_FilterConflict]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_FilterConflict.' 
	drop procedure dbo.ip_FilterConflict
	print '**** Creating procedure dbo.ip_FilterConflict...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_FilterConflict
(
	@pnRowCount			int		= null output,
	@psReturnClause			nvarchar(max)  = null output,
	@psFormattedTerms		nvarchar(max)	= null output,
	@psFormattedNameFields		nvarchar(max)	= null output,
	@psFormattedCaseFields		nvarchar(max)	= null output,
	@pbShowMatchingName		bit		= null output,
	@pbShowMatchingCase		bit		= null output,
	@pbShowCasesForName		bit		= null output,
	@psTempTableName		nvarchar(50)	= null, -- is the name of the the global temporary table that holds the results
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser		bit		= null,
	@ptXMLFilterFields		nvarchar(max)	= null,	-- The fields on which filtering is to be conducted.
	@ptXMLFilterCriteria		nvarchar(max)	= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pbPrintSQL			bit		= 0	-- Print out the constructed SQL 
)		
-- PROCEDURE :	ip_FilterConflict
-- VERSION :	12
-- DESCRIPTION:	Loads a global temporary table containing the keys of the names and cases that match the filter
--		criteria. The @psTempTableName output parameter is the name of the the global temporary table.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Details
-- ----		---	-------	-------	-------------------------------------
-- 27 May 2005	MF		1	Procedure created
-- 30 Jun 2005	MF	10718	2	Lowercase table column corrected to uppercase.
-- 05 Jul 2005	MF	10718	3	TableType number changed.
-- 06 Jul 2005	MF	10718	4	When returning Cases attached to found Names only return the Case details
--					and not the Name.
-- 08 Jul 2005	MF	10718	5	If the Boolean is NOT then set it to "AND NOT"
-- 20 Jul 2005	MF	10718	6	Concatenated list of Relationships should not be in quotes as these
--					will be added by a function.
--					Searching should be Case Insensitive
--					Order of Term searches must be preserved with brackets
-- 24 Oct 2005	TM	RFC3024	7	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 28 Sep 2006	MF	13519	8	Logic problems in constructed SQL when AND NOT boolean is used.
-- 11 Feb 2008	MF	15919	9	Search criteria Term is being truncated when displayed.  This was because it
--					was being truncated when read from XML and loaded int @tbTerms.
-- 11 Dec 2008	MF	17136	10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jan 2016	MF	55525	11	Long list of terms is causing dynamic SQL to crash. Change variables to NVARCHAR(max). Also remove
--					the UPPER function as the database must be case insensitive.
-- 27 Apr 2016	MF	R60349	12	Ethical Walls rules applied for logged on user.

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode		int
Declare @nTermCount		tinyint
Declare @nNameFieldCount	tinyint
Declare @nCaseFieldCount	tinyint
Declare @nNameCount		int
		
-- Parameters
Declare @nNamesOperator		tinyint
Declare	@sRelationships		nvarchar(200)

Declare @tbTerms table(
		TermNo		tinyint		identity(1,1),
		BooleanOperator	nvarchar(7)	collate database_default NULL, 
		Operator	tinyint		not null, 
		Term		nvarchar(254) 	collate database_default NOT NULL
		)

Declare @tbCaseFields table(
		Suffix		tinyint		identity(1,1),
		ItemName	nvarchar(50)	collate database_default not null,
		FieldName	nvarchar(50)	collate database_default not null, 
		Qualifier	nvarchar(20)	collate database_default null
		)

Declare @tbNameFields table(
		Suffix		tinyint		identity(1,1),
		ItemName	nvarchar(50)	collate database_default not null,
		FieldName	nvarchar(50)	collate database_default not null, 
		Qualifier	nvarchar(20)	collate database_default null
		)

Declare @sSQLString		nvarchar(max)
Declare	@sNameSelect		nvarchar(max)
Declare	@sCaseSelect		nvarchar(max)
Declare	@sNameWhere		nvarchar(max)
Declare	@sNameSecurity		nvarchar(max)
Declare	@sCaseWhere		nvarchar(max)
Declare	@sCaseSecurity		nvarchar(max)

-- Variables
Declare @sBooleanOperator	nvarchar(7)
Declare @sItemName		nvarchar(50)
Declare @sFieldName		nvarchar(50)
Declare @sQualifier		nvarchar(20)
Declare @sTerm			nvarchar(254)
Declare @sSystemUser		nvarchar(30)	-- @sSystemUser is used to pass the SYSTEM_USER into the SQL statement to avoid SqlDumpExceptionHandler exception.  
Declare	@nNameFieldNo		int
Declare	@nCaseFieldNo		int
Declare @nTermNo		int
Declare @nOperator		tinyint

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String

-- Initialise Constants
Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Intialise Variables
Set @ErrorCode =0 
Set @nTermCount=0

-- If there is no FilterCriteria or FilterFields passed then 
-- no results will be returned in the temporary table

If  @ErrorCode = 0
and datalength(@ptXMLFilterFields)   > 0
and datalength(@ptXMLFilterCriteria) > 0
Begin
	-- Create an XML document in memory and then retrieve the parameters required 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	Set @sSQLString="
	Select	@pbShowMatchingName	= ShowMatchingName,
		@pbShowMatchingCase	= ShowMatchingCase,
		@pbShowCasesForName	= ShowCasesForName,
		@nNamesOperator		= NamesOperator
	from	OPENXML (@idoc, '//ip_ListConflict/FilterCriteria/Results',2)
	WITH (
		ShowMatchingName	bit		'ShowMatchingName/text()',
		ShowMatchingCase	bit		'ShowMatchingCase/text()',
		ShowCasesForName	bit		'ShowCasesForName/text()',
		NamesOperator		tinyint		'AssociatedNames/@Operator/text()'
	     )"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pbShowMatchingName	bit	OUTPUT,
					  @pbShowMatchingCase	bit	OUTPUT,
					  @pbShowCasesForName	bit	OUTPUT,
					  @nNamesOperator	tinyint	OUTPUT,
					  @idoc			int',
					  @pbShowMatchingName	OUTPUT,
					  @pbShowMatchingCase	OUTPUT,
					  @pbShowCasesForName	OUTPUT,
					  @nNamesOperator	OUTPUT,
					  @idoc

	If @ErrorCode=0
	Begin
		-- Now get the concatenated list of Relationships to be used in the search 
	
		Set @sSQLString="
		Select	@sRelationships=isnull(nullif(@sRelationships+',',','),'')+Relationship
		from	OPENXML (@idoc, '//ip_ListConflict/FilterCriteria/Results/AssociatedNames/RelationshipGroup/RelationshipKey',2)
		WITH (
			Relationship		nvarchar(3)	'text()'
		     )"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sRelationships	varchar(200)	OUTPUT,
						  @idoc			int',
						  @sRelationships	OUTPUT,
						  @idoc
	End

	If @ErrorCode=0
	Begin
		-- Now load each of the Terms to be searched into a table variable
	
		insert into @tbTerms(BooleanOperator, Operator, Term)
		Select	BooleanOperator, Operator, Term
		from	OPENXML (@idoc, '//ip_ListConflict/FilterCriteria/SearchTerm/TermGroup/Term',2)
		WITH (
			Term		nvarchar(254)	'text()',
			BooleanOperator	nvarchar(7)	'@BooleanOperator/text()',
			Operator	nvarchar(3)	'@Operator/text()'
		     )

		Select	@nTermCount=@@Rowcount,
			@ErrorCode=@@Error
	End

	-- Remove the Filter Criteria XML document from memory
	EXEC sp_xml_removedocument @idoc

	If @ErrorCode=0
	Begin
		-- Load the Filter Fields XML document into memory
		exec sp_xml_preparedocument @idoc OUTPUT, @ptXMLFilterFields

		Insert into @tbNameFields(ItemName, Qualifier, FieldName)
		Select	QI.ITEMNAME, QF.QUALIFIER, QF.FIELDNAME
		from	OPENXML (@idoc, '//ip_ListConflict/FilterFields/NameFields/FieldKey',2)
		WITH (NameFieldKey	int	'text()') XML
		join QUERYFILTERFIELD QF on (QF.FILTERFIELDID=XML.NameFieldKey)
		join QUERYFILTERITEM QI  on (QI.FILTERITEMID=QF.FILTERITEMID)

		Select	@nNameFieldCount=@@Rowcount,
			@ErrorCode=@@Error
	End

	If @ErrorCode=0
	Begin
		Insert into @tbCaseFields(ItemName, Qualifier, FieldName)
		Select	QI.ITEMNAME, QF.QUALIFIER, QF.FIELDNAME
		from	OPENXML (@idoc, '//ip_ListConflict/FilterFields/CaseFields/FieldKey',2)
		WITH (CaseFieldKey	int	'text()') XML
		join QUERYFILTERFIELD QF on (QF.FILTERFIELDID=XML.CaseFieldKey)
		join QUERYFILTERITEM QI  on (QI.FILTERITEMID=QF.FILTERITEMID)

		Select	@nCaseFieldCount=@@Rowcount,
			@ErrorCode=@@Error
	End		

	-- Remove the Field Criteria XML document from memory
	EXEC sp_xml_removedocument @idoc

	-- If there are Term(s) to be searched on then commence construction of the Select statements
	If @nTermCount>0
	and @ErrorCode=0
	Begin
		-- If Name Fields are to be searched then construct the Select statement
		If @nNameFieldCount>0
		and @pbShowMatchingName=1
		Begin
			Set @sNameSelect=
			"insert into "+@psTempTableName+" (RecordType, NameKey, IsAssociatedName, IsAssociatedNameDesc)"+char(10)+
			"select distinct 1, N.NAMENO,T.USERCODE,T.DESCRIPTION"+char(10)+
			"from dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") N"+char(10)+
			"join TABLECODES T on (T.TABLETYPE=111"+char(10)+
			"                  and T.USERCODE=0)"

			If exists(select * from @tbNameFields where ItemName in ('VariantName','VariantFirstName'))
			Begin
				Set @sNameSelect=@sNameSelect+char(10)+
				"left join NAMEVARIANT NV on (NV.NAMENO=N.NAMENO)"
			End

			-- Multiple joins for the NAMETEXT table may be required depending on 
			-- the number of different qualifiers.  The following will concatenate
			-- as many different occurrences of NameText rows as is required
			Select 
			@sNameSelect=@sNameSelect+char(10)+
			"left join NAMETEXT NT_"+convert(varchar(3),Suffix)+" on (NT_"+convert(varchar(3),Suffix)+".NAMENO=N.NAMENO"+char(10)+
			"                        and NT_"+convert(varchar(3),Suffix)+".TEXTTYPE='"+Qualifier+"')"
			from @tbNameFields
			where ItemName='NameText'
			and Qualifier is not null
		End

		-- If Case Fields are to be searched then construct the Select statement
		If @nCaseFieldCount>0
		and @pbShowMatchingCase=1
		Begin
			Set @sCaseSelect=
			"insert into "+@psTempTableName+" (RecordType, CaseKey)"+char(10)+
			"select distinct 2, C.CASEID"+char(10)+
			"from dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") C"

			If exists(select * from @tbCaseFields where ItemName='KeyWords')
			Begin
				Set @sCaseSelect=@sCaseSelect+char(10)+
				"left join CASEWORDS CW	on (CW.CASEID=C.CASEID)"+char(10)+
				"left join KEYWORDS K	on (K.KEYWORDNO=CW.KEYWORDNO)"
			End

			If exists(select * from @tbCaseFields where ItemName='OfficialNumbers')
			Begin
				Set @sCaseSelect=@sCaseSelect+char(10)+
				"left join OFFICIALNUMBERS O on (O.CASEID=C.CASEID)"
			End

			-- Multiple joins for the CASETEXT table may be required depending on 
			-- the number of different qualifiers.  The following will concatenate
			-- as many different occurrences of CaseText rows as is required
			Select 
			@sCaseSelect=@sCaseSelect+char(10)+
			"left join CASETEXT CT_"+convert(varchar(3),Suffix)+" on (CT_"+convert(varchar(3),Suffix)+".CASEID=C.CASEID"+char(10)+
			"                        and CT_"+convert(varchar(3),Suffix)+".TEXTTYPE='"+Qualifier+"')"
			from @tbCaseFields
			where ItemName='CaseText'
			and Qualifier is not null
		End

		-- Loop through each of the search terms and for each term construct the components of the WHERE
		-- clause for each of the Name and Case searches. Within each term an inner loop will loop through
		-- each of the Filter Fields.

		Set @nTermNo = 1
		
		If @nNameFieldCount>0
		and @pbShowMatchingName=1
			Set @sNameWhere='Where '+replicate('(',@nTermCount-1)

		If @nCaseFieldCount>0
		and @pbShowMatchingCase=1
			Set @sCaseWhere='Where '+replicate('(',@nTermCount-1)
	
		While @nTermNo <= @nTermCount
		and @ErrorCode = 0
		Begin
			Select	@sBooleanOperator=CASE WHEN(BooleanOperator='NOT') THEN 'AND NOT' ELSE BooleanOperator END,
				@nOperator=Operator,
				@sTerm=Term
			From @tbTerms
			Where TermNo=@nTermNo

			-- Loop through each of the Name fields in order to construct the
			-- Where clause using the current Term.
	
			Set @nNameFieldNo=1

			While @nNameFieldNo<=@nNameFieldCount
			and @pbShowMatchingName=1
			Begin
				If @nNameFieldNo=1
				Begin
					If @nTermNo>1
						Set @sNameWhere=@sNameWhere+@sBooleanOperator

					Set @sNameWhere=@sNameWhere+'('
				End
				Else Begin
					-- Need to use AND between each field in the search
					-- if the AND NOT boolean is used for this TERM
					--If @sBooleanOperator='AND NOT'
					--	Set @sNameWhere=@sNameWhere+' AND '
					--Else
						Set @sNameWhere=@sNameWhere+' OR '
				End

				-- Get the details of the Field to be searched
				Select	@sItemName=ItemName,
					@sFieldName=FieldName,
					@sQualifier=Qualifier
				From @tbNameFields
				Where Suffix=@nNameFieldNo
			
				-- Generate the WHERE clause for each Field to be searched

				If @sItemName='Name'
				Begin
					Set @sNameWhere = @sNameWhere+"N.NAME"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='FirstName'
				Begin
					Set @sNameWhere = @sNameWhere+"isnull(N.FIRSTNAME,'')"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='VariantName'
				Begin
					Set @sNameWhere = @sNameWhere+"isnull(NV.NAMEVARIANT,'')"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='VariantFirstName'
				Begin
					Set @sNameWhere = @sNameWhere+"isnull(NV.FIRSTNAMEVARIANT,'')"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='SearchKey1'
				Begin
					Set @sNameWhere = @sNameWhere+"isnull(N.SEARCHKEY1,'')"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='SearchKey2'
				Begin
					Set @sNameWhere = @sNameWhere+"isnull(N.SEARCHKEY2,'')"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='Remarks'
				Begin
					Set @sNameWhere = @sNameWhere+"isnull(N.REMARKS,'')"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='NameText'
				Begin
					Set @sNameWhere = @sNameWhere+"NT_"+convert(varchar(3),@nNameFieldNo)+".TEXT"+dbo.fn_ConstructOperator(@nOperator,@Text,@sTerm, null,@pbCalledFromCentura)
				End

				-- If the last field has been included in the WHERE clause
				-- then close the bracket.
				If @nNameFieldNo=@nNameFieldCount
				Begin
					Set @sNameWhere=@sNameWhere+')'

					-- An extra bracket close is required if this is not
					-- the first Term
					If @nTermNo>1
						Set @sNameWhere=@sNameWhere+')'
				End

				-- Line feed
				Set @sNameWhere=@sNameWhere+char(10)

				-- Increment the field number
				Set @nNameFieldNo=@nNameFieldNo+1
			End -- End loop through the Name fields.

			-- Loop through each of the Case fields in order to construct the
			-- Where clause using the current Term.	
			Set @nCaseFieldNo=1

			While @nCaseFieldNo<=@nCaseFieldCount
			and @pbShowMatchingCase=1
			Begin
				If @nCaseFieldNo=1
				Begin
					If @nTermNo>1
						Set @sCaseWhere=@sCaseWhere+@sBooleanOperator

					Set @sCaseWhere=@sCaseWhere+'('
				End
				Else Begin
					--If @sBooleanOperator='AND NOT'
					--	Set @sCaseWhere=@sCaseWhere+' AND '
					--Else
						Set @sCaseWhere=@sCaseWhere+' OR '
				End

				-- Get the details of the Field to be searched
				Select	@sItemName=ItemName,
					@sFieldName=FieldName,
					@sQualifier=Qualifier
				From @tbCaseFields
				Where Suffix=@nCaseFieldNo
			
				-- Generate the WHERE clause for each Field to be searched

				If @sItemName='Title'
				Begin
					Set @sCaseWhere = @sCaseWhere+"C.TITLE"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='KeyWords'
				Begin
					Set @sCaseWhere = @sCaseWhere+"K.KEYWORD"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='OfficialNumbers'
				Begin
					Set @sCaseWhere = @sCaseWhere+"O.OFFICIALNUMBER"+dbo.fn_ConstructOperator(@nOperator,@String,@sTerm, null,@pbCalledFromCentura)
				End

				Else If @sItemName='CaseText'
				Begin
					Set @sCaseWhere = @sCaseWhere+"isnull(CT_"+convert(varchar(3),@nCaseFieldNo)+".TEXT,CT_"+convert(varchar(3),@nCaseFieldNo)+".SHORTTEXT)"+dbo.fn_ConstructOperator(@nOperator,@Text,@sTerm, null,@pbCalledFromCentura)
				End

				-- If the last field has been included in the WHERE clause
				-- then close the bracket.
				If @nCaseFieldNo=@nCaseFieldCount
				Begin
					Set @sCaseWhere=@sCaseWhere+')'

					-- An extra bracket close is required if this is not
					-- the first Term
					If @nTermNo>1
						Set @sCaseWhere=@sCaseWhere+')'
				End

				-- Line feed
				Set @sCaseWhere=@sCaseWhere+char(10)

				-- Increment the field number
				Set @nCaseFieldNo=@nCaseFieldNo+1
			End -- End loop through the Case fields.

			-- Increment the TermNo
			Set @nTermNo=@nTermNo+1
		End -- End of the "While" loop
	End
End

-- Construct the SQL for Row Level Security for Names if it is required
If   @ErrorCode=0
and (@pbShowMatchingName=1 and @nNameFieldCount>0)
and exists(	Select 1                         
		from USERROWACCESS U
		join ROWACCESSDETAIL R on (R.ACCESSNAME = U.ACCESSNAME) 
		where RECORDTYPE = 'N')
and exists (	Select 1
		from SITECONTROL
		where CONTROLID = 'Office Restricted Names'
		and COLINTEGER>0)
Begin
	-- Get the @sSystemUser associated with the IdentityId
	Set @sSQLString = "
	Select  @sSystemUser = min(USERID)
	from USERS
	where IDENTITYID = @pnUserIdentityId"

	exec @ErrorCode = sp_executesql @sSQLString,
				N'@sSystemUser		nvarchar(30)	output,
				  @pnUserIdentityId	int',
				  @sSystemUser     = @sSystemUser	output,
				  @pnUserIdentityId=@pnUserIdentityId


	-- If not USERID was found then use the current login
	If @sSystemUser is null
		Set @sSystemUser=SYSTEM_USER

	-- Different security depending on whether Case Office is used
	If  @ErrorCode =0
	Begin
		Set @sNameSecurity = 
		+char(10)+"and(Not Exists (Select 1 from TABLEATTRIBUTES TA"
		+char(10)+"                where TA.PARENTTABLE='NAME'"
		+char(10)+"                and TA.GENERICKEY=cast(N.NAMENO as varchar)"
		+char(10)+"                and TA.TABLETYPE=44"
		+char(10)+"                and TA.TABLECODE is not null)"
		+char(10)+" or  Substring("          
		+char(10)+"	(select MAX (   CASE WHEN RAD.OFFICE IS NULL THEN '0' ELSE '1' END +"  
					        --  pack a single digit flag with zero 
		+char(10)+"			CASE WHEN RAD.SECURITYFLAG < 10    THEN '0' END +"
		+char(10)+"	convert(nvarchar,RAD.SECURITYFLAG))"   
		+char(10)+"	from USERROWACCESS UA"   
		+char(10)+"	left join ROWACCESSDETAIL RAD 	on (RAD.ACCESSNAME=UA.ACCESSNAME"        
		+char(10)+"					and (RAD.OFFICE in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='NAME' and TA.TABLETYPE=44 and TA.GENERICKEY=cast(N.NAMENO as varchar))"  
		+char(10)+"					 or RAD.OFFICE is NULL)" 
		+char(10)+"					and RAD.RECORDTYPE = 'N')"  
		+char(10)+"	where UA.USERID = "+dbo.fn_WrapQuotes(@sSystemUser,0,0)+"),   2,2)" -- end of the SUBSTRING        
				-- list of SECURITYFLAG with SELECT set ON 
		+char(10)+"	in (  '01','03','05','07','09','11','13','15'))"     
	End
End

-- If Names are to be loaded then execute the constructed SQL
If @nNameFieldCount>0
and @pbShowMatchingName=1
and @ErrorCode=0
Begin 
	Set @sSQLString='SET ANSI_NULLS OFF '+@sNameSelect+char(10)+@sNameWhere+@sNameSecurity

	If @pbPrintSQL=1
	begin
		Print ''
		Print @sSQLString
	End

	exec @ErrorCode=sp_executesql @sSQLString

	Set @nNameCount=@@Rowcount
End

-- If Names have been loaded and related Names are also to be searched then
-- include the related names in the result set.
If @nNameCount>0
and @sRelationships is not null
and @nNamesOperator<2
and @ErrorCode=0
Begin
	Set @sSQLString=
	"SET ANSI_NULLS OFF "+char(10)+ 
	"insert into "+@psTempTableName+" (RecordType, NameKey, IsAssociatedName, IsAssociatedNameDesc)"+char(10)+
	"select 1, N.NAMENO,T.USERCODE,T.DESCRIPTION"+char(10)+
	"from "+@psTempTableName+" TN"+char(10)+
	"join TABLECODES T on (T.TABLETYPE=111"+char(10)+
	"                  and T.USERCODE=1)"+char(10)+
	"join ASSOCIATEDNAME N on (N.RELATEDNAME=TN.NameKey)"+char(10)+
	"left join "+@psTempTableName+" TN1 on (TN1.NameKey=N.NAMENO)"+char(10)+
	"where TN1.NameKey is null"+char(10)+
	"and N.RELATIONSHIP"+dbo.fn_ConstructOperator(@nNamesOperator,@CommaString,@sRelationships, null,@pbCalledFromCentura)+
	@sNameSecurity+char(10)+
	"UNION"+char(10)+
	"select 1, A.RELATEDNAME,T.USERCODE,T.DESCRIPTION"+char(10)+
	"from "+@psTempTableName+" TN"+char(10)+
	"join TABLECODES T on (T.TABLETYPE=111"+char(10)+
	"                  and T.USERCODE=1)"+char(10)+
	"join ASSOCIATEDNAME A on (A.NAMENO=TN.NameKey)"+char(10)+
	"join NAME N on (N.NAMENO=A.RELATEDNAME)"+char(10)+
	"left join "+@psTempTableName+" TN1 on (TN1.NameKey=A.RELATEDNAME)"+char(10)+
	"where TN1.NameKey is null"+char(10)+
	"and A.RELATIONSHIP"+dbo.fn_ConstructOperator(@nNamesOperator,@CommaString,@sRelationships, null,@pbCalledFromCentura)+
	@sNameSecurity

	If @pbPrintSQL=1
	begin
		Print ''
		Print @sSQLString
	End

	exec @ErrorCode=sp_executesql @sSQLString

	Set @nNameCount=@nNameCount+1
End

-- Construct the SQL for Row Level Security if it is required
If   @ErrorCode=0
and((@pbShowCasesForName=1 and @nNameCount>0)
 or (@pbShowMatchingCase=1 and @nCaseFieldCount>0))
and exists(Select 1                         
	   from USERROWACCESS U
	   join ROWACCESSDETAIL R on (R.ACCESSNAME = U.ACCESSNAME) 
	   where RECORDTYPE = 'C')  
Begin
	-- Get the @sSystemUser associated with the IdentityId if it 
	-- has not already been extracted
	If @sSystemUser is null
	Begin
		Set @sSQLString = "
		Select  @sSystemUser = min(USERID)
		from USERS
		where IDENTITYID = @pnUserIdentityId"
	
		exec @ErrorCode = sp_executesql @sSQLString,
					N'@sSystemUser		nvarchar(30)	output,
					  @pnUserIdentityId	int',
					  @sSystemUser     = @sSystemUser	output,
					  @pnUserIdentityId=@pnUserIdentityId
	
	
		-- If not USERID was found then use the current login
		If @sSystemUser is null
			Set @sSystemUser=SYSTEM_USER
	End

	-- Different security depending on whether Case Office is used
	If  @ErrorCode =0
	and exists (	Select 1
			from SITECONTROL
			where CONTROLID = 'Row Security Uses Case Office'
			and COLBOOLEAN=1)
	Begin
		Set @sCaseSecurity=	
		    +char(10)+"and  Substring("          
		    +char(10)+"	    (Select MAX (CASE WHEN RAD.OFFICE       IS NULL THEN '0' ELSE '1' END +"   
		    +char(10)+"			 CASE WHEN RAD.CASETYPE     IS NULL THEN '0' ELSE '1' END +"   
		    +char(10)+"			 CASE WHEN RAD.PROPERTYTYPE IS NULL THEN '0' ELSE '1' END +"   
		    				 --  pack a single digit flag with zero
		    +char(10)+"			 CASE WHEN RAD.SECURITYFLAG < 10    THEN '0' END +"     
		    +char(10)+"			 convert(nvarchar,RAD.SECURITYFLAG))"   
		    +char(10)+"	     from USERROWACCESS UA"   
		    +char(10)+"	     left join ROWACCESSDETAIL RAD 	on (RAD.ACCESSNAME = UA.ACCESSNAME"        
		    +char(10)+"						and (RAD.OFFICE = C.OFFICEID"    
		    +char(10)+"						 or RAD.OFFICE is NULL)"        
		    +char(10)+"						and (RAD.CASETYPE = C.CASETYPE"     
		    +char(10)+"						 or RAD.CASETYPE is NULL)"        
		    +char(10)+"						and (RAD.PROPERTYTYPE = C.PROPERTYTYPE" 
		    +char(10)+"						 or RAD.PROPERTYTYPE is NULL)"        
		    +char(10)+"						and RAD.RECORDTYPE = 'C')"   					     
		    +char(10)+"	     where UA.USERID = "+dbo.fn_WrapQuotes(@sSystemUser,0,0)+"),   4,2)" -- end of the SUBSTRING     
		    		     -- list of SECURITYFLAG with SELECT set ON
		    +char(10)+"	     in (  '01','03','05','07','09','11','13','15' )"
	End	
	Else If @ErrorCode=0
	Begin
		Set @sCaseSecurity = 
		+char(10)+"and  Substring("          
		+char(10)+"	(select MAX (   CASE WHEN RAD.OFFICE  	   IS NULL THEN '0' ELSE '1' END +"   
		+char(10)+"			CASE WHEN RAD.CASETYPE     IS NULL THEN '0' ELSE '1' END +"   
		+char(10)+"			CASE WHEN RAD.PROPERTYTYPE IS NULL THEN '0' ELSE '1' END +"  
					        --  pack a single digit flag with zero 
		+char(10)+"			CASE WHEN RAD.SECURITYFLAG < 10    THEN '0' END +" -- pack a single digit flag with zero
		+char(10)+"	convert(nvarchar,RAD.SECURITYFLAG))"   
		+char(10)+"	from USERROWACCESS UA"   
		+char(10)+"	left join ROWACCESSDETAIL RAD 	on (RAD.ACCESSNAME=UA.ACCESSNAME"        
		+char(10)+"					and (RAD.OFFICE in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='CASES' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, C.CASEID))"  
		+char(10)+"					 or RAD.OFFICE is NULL)"        
		+char(10)+"					and (RAD.CASETYPE = C.CASETYPE or RAD.CASETYPE is NULL)"        
		+char(10)+"					and (RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)"        
		+char(10)+"					and RAD.RECORDTYPE = 'C')"  
		+char(10)+"	where UA.USERID = "+dbo.fn_WrapQuotes(@sSystemUser,0,0)+"),   4,2)" -- end of the SUBSTRING        
				-- list of SECURITYFLAG with SELECT set ON 
		+char(10)+"	in (  '01','03','05','07','09','11','13','15' )"     
	End
End

-- If Cases are to be loaded then execute the constructed SQL
If @nCaseFieldCount>0
and @pbShowMatchingCase=1
and @ErrorCode=0
Begin
	Set @sSQLString='SET ANSI_NULLS OFF '+@sCaseSelect+char(10)+@sCaseWhere+@sCaseSecurity

	If @pbPrintSQL=1
	begin
		Print ''
		Print @sSQLString
	End

	exec @ErrorCode=sp_executesql @sSQLString
End

-- If Cases that are associated with the Names found are required to be returned then 
-- include those Cases in the result set.
-- Details of the Name are returned in the same result set to allow the Cases to be reported by Name and 
-- then associated Cases.
If @pbShowCasesForName=1
and @nNameCount>0
and @ErrorCode=0
Begin
	Set @sSQLString=
	"SET ANSI_NULLS OFF "+char(10)+
	"insert into "+@psTempTableName+" (RecordType, CaseKey, NameKey,IsAssociatedName,IsAssociatedNameDesc)"+char(10)+
--	"select distinct 2, CN.CASEID, CN.NAMENO,T.IsAssociatedName,T.IsAssociatedNameDesc"+char(10)+
	"select distinct 2, CN.CASEID, null,null,null"+char(10)+
	"from "+@psTempTableName+" T"+char(10)+
	"join CASENAME CN on (CN.NAMENO=T.NameKey and CN.EXPIRYDATE is null)"+char(10)+
	"join CASES C     on (C.CASEID=CN.CASEID)"+char(10)+
	"left join "+@psTempTableName+" T1 on (T1.CaseKey=CN.CASEID)"+char(10)+
	"where T1.CaseKey is null"+
	@sCaseSecurity

	If @pbPrintSQL=1
	begin
		Print ''
		Print @sSQLString
	End

	exec @ErrorCode=sp_executesql @sSQLString
End	

If @nTermCount>0
and @ErrorCode=0
Begin
	Select @psFormattedTerms=@psFormattedTerms+
				 CASE WHEN(@psFormattedTerms is not null) THEN ' ' END+
				 CASE WHEN(TC1.DESCRIPTION is not null) THEN TC1.DESCRIPTION+' ' END+
				 TC2.DESCRIPTION+' '+
				 T.Term
	from @tbTerms T
	left join TABLECODES TC1 on (TC1.TABLETYPE=113
				 and TC1.USERCODE=T.BooleanOperator)
	     join TABLECODES TC2 on (TC2.TABLETYPE=112
				 and TC2.USERCODE=T.Operator)
	Order by TermNo

	Set @ErrorCode=@@Error
End

If @nNameFieldCount>0
and @ErrorCode=0
Begin
	Select @psFormattedNameFields=@psFormattedNameFields+
				      CASE WHEN(@psFormattedNameFields is not null) THEN ', ' END+
				      T.FieldName
	from @tbNameFields T
	Order by Suffix

	Set @ErrorCode=@@Error
End

If @nCaseFieldCount>0
and @ErrorCode=0
Begin
	Select @psFormattedCaseFields=@psFormattedCaseFields+
				      CASE WHEN(@psFormattedCaseFields is not null) THEN ', ' END+
				      T.FieldName
	from @tbCaseFields T
	Order by Suffix

	Set @ErrorCode=@@Error
End

RETURN @ErrorCode
go

grant execute on dbo.ip_FilterConflict  to public
go



