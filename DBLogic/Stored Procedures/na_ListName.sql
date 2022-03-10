-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[na_ListName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.na_ListName.'
	drop procedure dbo.na_ListName
end
print '**** Creating procedure dbo.na_ListName...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.na_ListName

-- PROCEDURE :	na_ListName
-- VERSION :	32
-- DESCRIPTION:	Search and return matching names as a result set
-- CALLED BY :	

-- MODIFICTIONS :
-- Date         Who	Number	Version  	Change
-- ------------ ----	------	-------- 	------------------------------------------- 
-- 12 Mar 2002	SF			Procedure created
-- 10 Sep 2002	MF			Complete filtering
-- 24 Sep 2002	MF			Provide a default for the list of columns to display
-- 02 Oct 2002	SF			Part of the sql statement is missing an if block. (when key is provided).
-- 24 Oct 2002	JEK		17	Implement @psSuitableForNameTypeKey.
-- 04 Nov 2002	JEK		18	InProma does not implement same name type, so remove this logic.
-- 06 Nov 2002	MF		19	Move the @psPickListSearch progressive search into this stored procedure.  As it
--					needs to combine the other filter parameters it results in dynamic SQL being 
--					executed which cannot occur within a function.
-- 19 Nov 2002	JB		23	Moved the comment section to the top so version can be detected
-- 09 Dec 2002	SF		24	Implement 345 Name Type rule filtering for Staff/Client
-- 17 Jul 2003	TM	RFC76	25	Case Insensitive searching
-- 07 Nov 2003	MF	RFC586	25	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 02 Sep 2004	JEK	RFC1377	27	Pass new Centura parameter to fn_WrapQuotes
-- 17 Dec 2004	TM	RFC1674	28	Remove the UPPER function around the SearchKey1 and SearchKey2 to improve
--					performance.
-- 27 May 2005	TM	RFC2242	29	RFC2242 Implement Name search with both keys site control in name pick list search.
-- 30 Jan 2007	PY	SQA12521	Replace function call Soundex with fn_SoundsLike
-- 19 Mar 2008	vql	SQA14773 31     Make PurchaseOrderNo nvarchar(80)
-- 11 Dec 2008	MF	17136	32	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	

(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbProduceResultSet		bit		= 1,	-- if TRUE, a result set is published; if FALSE the results are held internally awaiting the next of multiple calls to the sp.
	@psBuildOperator		nvarchar(3)	= 'AND',-- may contain any of the values "and", "OR", "NOT"	
	@psColumnIds			nvarchar(4000)	= 'NameKey^NameCode', -- list of the columns (delimited by ^) required either as ouput or for sorting
	@psColumnQualifiers		nvarchar(1000)	= null,	-- list of qualifiers  (delimited by ^) that further define the data to be selected
	@psPublishColumnNames		nvarchar(4000)	= 'Key^Name Code',-- list of columne names (delimited by ^) to be published as the output name
	@psSortOrderList		nvarchar(1000)	= '^1',	-- list of numbers (delimited by ^) to indicate the precedence of the matching column in the Order By clause
	@psSortDirectionList		nvarchar(1000)	= '^A',	-- list that indicates the direction for the sort of each column included in the Order By
	@pnNameKey			int		= null, 
	@psPickListSearch		nvarchar(254)	= null,
	@pbIsOrganisation		bit		= null,
	@pbIsIndividual			bit		= null,
	@pbIsClient			bit		= null,
	@pbIsStaff			bit		= null,
	@pbIsCurrent			bit		= null,
	@pbIsCeased			bit		= null,
	@psSearchKey			nvarchar(20)	= null,
	@pbUseSearchKey1		bit		= null,
	@pbUseSearchKey2		bit		= null,
	@pnSearchKeyOperator		int		= null,
	@pbSoundsLike			bit		= null,
	@psNameCode			nvarchar(10)	= null,
	@pnNameCodeOperator		tinyint		= null,
	@psName				nvarchar(254) 	= null,
	@pnNameOperator			tinyint 	= null,
	@psFirstName			nvarchar(50)	= null,
	@pnFirstNameOperator		tinyint		= null,
	@pdtLastChangedFromDate		datetime	= null,
	@pdtLastChangedToDate		datetime	= null,
	@pnLastChangedOperator		tinyint		= null,
	@psRemarks			nvarchar(254)	= null,
	@pnRemarksOperator		tinyint		= null,
	@psCountryKey			nvarchar(3)	= null,
	@pnCountryKeyOperator		tinyint		= null, 
	@psStateKey			nvarchar(20)	= null,
	@pnStateKeyOperator		tinyint		= null,
	@psCity				nvarchar(30)	= null,
	@pnCityOperator			tinyint		= null,
	@pnNameGroupKey			smallint	= null, 
	@pnNameGroupKeyOperator		tinyint		= null,
	@psNameTypeKey			nvarchar(3)	= null,
	@pnNameTypeKeyOperator		tinyint		= null,
	@psSuitableForNameTypeKey	nvarchar(3)	= null,
	@psAirportKey			nvarchar(5)	= null,
	@pnAirportKeyOperator		tinyint		= null,
	@pnNameCategoryKey		int		= null,
	@pnNameCategoryKeyOperator	tinyint		= null,
	@pnBadDebtorKey			int		= null,
	@pnBadDebtorKeyOperator		tinyint		= null,
	@psFilesInKey			nvarchar(3)	= null,
	@pnFilesInKeyOperator		tinyint		= null,
	@psTextTypeKey			nvarchar(2)	= null,
	@psText				nvarchar(4000)	= null,
	@pnTextOperator			tinyint		= null,
	@pnInstructionKey		int		= null,
	@pnInstructionKeyOperator	tinyint		= null,
	@pnParentNameKey		int		= null,
	@pnParentNameKeyOperator	tinyint		= null,
	@psRelationshipKey		nvarchar(3)	= null,
	@pnRelationshipKeyOperator	tinyint		= null,
	@pbIsReverseRelationship	bit		= null,
	@psAssociatedNameKeys		nvarchar(4000)	= null,
	@pnAssociatedNameKeyOperator	tinyint		= null,
	@psMainPhoneNumber		nvarchar(50)	= null,
	@pnMainPhoneNumberOperator	tinyint		= null,
	@psMainPhoneAreaCode		nvarchar(5)	= null,
	@pnMainPhoneAreaCodeOperator	tinyint		= null,
	@pnAttributeTypeKey1		int		= null,
	@pnAttributeKey1		int		= null,
	@pnAttributeKey1Operator	tinyint		= null,
	@pnAttributeTypeKey2		int		= null,
	@pnAttributeKey2		int		= null,
	@pnAttributeKey2Operator	tinyint		= null,
	@psAliasTypeKey			nvarchar(2)	= null,
	@psAlias			nvarchar(20)	= null,
	@pnAliasOperator		tinyint		= null,
	@pnQuickIndexKey		int		= null,
	@pnQuickIndexKeyOperator	tinyint		= null,
	@psBillingCurrencyKey		nvarchar(3)	= null,
	@pnBillingCurrencyKeyOperator	tinyint		= null,
	@psTaxRateKey			nvarchar(3)	= null,
	@pnTaxRateKeyOperator		tinyint		= null,
	@pnDebtorTypeKey		int		= null,
	@pnDebtorTypeKeyOperator	tinyint		= null,
	@psPurchaseOrderNo		nvarchar(80)	= null,
	@pnPurchaseOrderNoOperator	tinyint		= null,
	@pnReceivableTermsFromDays	int		= null,
	@pnReceivableTermsToDays	int		= null,
	@pnReceivableTermsOperator	tinyint		= null,
	@pnBillingFrequencyKey		int		= null,
	@pnBillingFrequencyKeyOperator	tinyint		= null,
	@pbIsLocalClient		bit		= null,
	@pnIsLocalClientOperator	tinyint		= null
)	
AS
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF

	declare @ErrorCode		int

	declare @nTableCount		tinyint
	
	declare @sCurrentTable 		nvarchar(50)	
	declare @sCopyTable 		nvarchar(50)	

	declare @bTempTableExists	bit
	declare	@bExternalUser		bit

	declare @sSql			nvarchar(4000)
	declare @sSQLString		nvarchar(4000)
	declare @sSelectList		nvarchar(4000)  -- the SQL list of columns to return
	declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
	declare @sWhere			nvarchar(4000) 	-- the SQL to filter
	declare @sOrder			nvarchar(1000)	-- the SQL sort order
	declare	@sNameFilter		nvarchar(4000)	-- the FROM and WHERE for the Case Filter
	declare	@sNameSearch		nvarchar(254)

	declare @bIsOrganisation	bit
	declare @bIsIndividual		bit
	declare @bIsClient		bit
	declare @bIsStaff		bit
	declare @pbExists		bit
	declare @nPickListFlags		smallint
	declare @bSearchBothKeys 	bit

	set @ErrorCode=0

	-- Case Insensitive searching

	set @psPickListSearch = upper(@psPickListSearch)
	

	set @sCurrentTable = '##SEARCHNAME_' + Cast(@@SPID as nvarchar(30))
	set @sCopyTable    = '##COPYNAMENO_' + Cast(@@SPID as nvarchar(30))


	-- Determine if the temporary table holding previous results exists

	if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable )
		set @bTempTableExists=1
	else
		set @bTempTableExists=0

	-- Check if the result set is to be returned

	if @pbProduceResultSet = 0
	begin
		-- If no results are being returned at this time then we need to create
		-- a temporary table to store the results if it has not been created already
		-- or we needed to create a second temporary table to hold the previous results
		-- so the main table can be loaded with the new query results
  
		if (@bTempTableExists = 0)
		begin
			-- create the ##SEARCHCASE table
			Set @sSql = 'Create Table ' + @sCurrentTable + ' (NAMENO int)'
		end
		else begin
 			-- create the intermediate ##COPYCASEID table
			Set @sSql = 'Create Table ' + @sCopyTable + ' (NAMENO int)'
		end

		exec @ErrorCode=sp_executesql @sSql

		-- the statements above will prepare the temptable needed for this query	
		Set @sSelectList = 'Insert into ' + @sCurrentTable + '(NAMENO) select XN.NAMENO'
	end
	else begin

		exec @ErrorCode=dbo.na_ConstructNameSelect	@sSelectList	OUTPUT,
								@sFrom		OUTPUT,
								@sWhere		OUTPUT,
								@sOrder		OUTPUT,
								@nTableCount	OUTPUT,
								@psColumnIds,
								@psColumnQualifiers,
								@psPublishColumnNames,
								@psSortOrderList,
								@psSortDirectionList,
								@bExternalUser
	

	End

	-- ACTUAL NAME SEARCH SQL BUILDING BEGINS
	-- now prepair the sql with the available filters specified.

	-- A user defined function is used to construct the FROM and WHERE clauses
	-- used to filter what Names are to be returned
	if @ErrorCode=0
	and @pnNameKey is not null
	begin
		If @sWhere is null
			Set @sWhere=' Where N.NAMENO='+convert(varchar, @pnNameKey)
		else
			Set @sWhere=@sWhere+char(10)+'and N.NAMENO='+convert(varchar, @pnNameKey)
	end
	else if @ErrorCode=0
	begin
		-- If @psSuitableForNameTypeKey is provided, filter criteria needs
		-- to be obtained from the NameType rules.
		set @nPickListFlags = 0
		if @psSuitableForNameTypeKey is not null
		begin
			select @nPickListFlags = PICKLISTFLAGS
			from NAMETYPE
			where NAMETYPE = @psSuitableForNameTypeKey

			set @ErrorCode = @@ERROR
		end

		If @ErrorCode = 0 and @nPickListFlags > 0
		Begin
			-- Take explicit parameters in preference to name type rules
			Set @bIsIndividual = isnull(@pbIsIndividual, cast(@nPickListFlags&1 as bit))
			Set @bIsOrganisation = isnull(@pbIsOrganisation, cast(@nPickListFlags&8 as bit))
			---------------------------------------------------------------------------------
			-- JEK 24 Oct 2002
			-- CPA.Net has not implemented client/staff yet.  
			Set @bIsStaff = isnull(@pbIsStaff, cast(@nPickListFlags&2 as bit))
			Set @bIsClient = isnull(@pbIsClient, cast(@nPickListFlags&4 as bit))
			-- To implement, replace the next few statements with the two above.
			---------------------------------------------------------------------------------
			-- if @bIsIndividual = 0 -- treat staff as individual
			-- begin
			--	Set @bIsIndividual = cast(@nPickListFlags&2 as bit)
			-- end 
			-- Set @bIsClient = @pbIsClient
			---------------------------------------------------------------------------------
			-- JEK 04 Nov 2002
			-- Note: InProma does not implement @nPickListFlags&16 = 16: Same Name Type
		End
		Else
		Begin
			-- User parameters directly
			Set @bIsIndividual = @pbIsIndividual
			Set @bIsOrganisation = @pbIsOrganisation
			Set @bIsClient = @pbIsClient
			Set @bIsStaff = @pbIsStaff
		End

		If @ErrorCode = 0
		Begin
			set @sNameFilter=dbo.fn_FilterNames(
				@pnUserIdentityId, 
				@bIsOrganisation,		--Local variable prepared above
				@bIsIndividual,			--Local variable prepared above
				@bIsClient,			--Local variable prepared above
				@bIsStaff,			--Local variable prepared above
				@pbIsCurrent,
				@pbIsCeased,
				@psSearchKey,
				@pbUseSearchKey1,
				@pbUseSearchKey2,
				@pnSearchKeyOperator,
				@pbSoundsLike,
				@psNameCode,
				@pnNameCodeOperator,
				@psName,
				@pnNameOperator,
				@psFirstName,
				@pnFirstNameOperator,
				@pdtLastChangedFromDate,
				@pdtLastChangedToDate,
				@pnLastChangedOperator,
				@psRemarks,
				@pnRemarksOperator,
				@psCountryKey,
				@pnCountryKeyOperator, 
				@psStateKey,
				@pnStateKeyOperator,
				@psCity,
				@pnCityOperator,
				@pnNameGroupKey, 
				@pnNameGroupKeyOperator,
				@psNameTypeKey,
				@pnNameTypeKeyOperator,
				@psAirportKey,
				@pnAirportKeyOperator,
				@pnNameCategoryKey,
				@pnNameCategoryKeyOperator,
				@pnBadDebtorKey,
				@pnBadDebtorKeyOperator,
				@psFilesInKey,
				@pnFilesInKeyOperator,
				@psTextTypeKey,
				@psText,
				@pnTextOperator,
				@pnInstructionKey,
				@pnInstructionKeyOperator,
				@pnParentNameKey,
				@pnParentNameKeyOperator,
				@psRelationshipKey,
				@pnRelationshipKeyOperator,
				@pbIsReverseRelationship,
				@psAssociatedNameKeys,
				@pnAssociatedNameKeyOperator,
				@psMainPhoneNumber,
				@pnMainPhoneNumberOperator,
				@psMainPhoneAreaCode,
				@pnMainPhoneAreaCodeOperator,
				@pnAttributeTypeKey1,
				@pnAttributeKey1,
				@pnAttributeKey1Operator,
				@pnAttributeTypeKey2,
				@pnAttributeKey2,
				@pnAttributeKey2Operator,
				@psAliasTypeKey,
				@psAlias,
				@pnAliasOperator,
				@pnQuickIndexKey,
				@pnQuickIndexKeyOperator,
				@psBillingCurrencyKey,
				@pnBillingCurrencyKeyOperator,
				@psTaxRateKey,
				@pnTaxRateKeyOperator,
				@pnDebtorTypeKey,
				@pnDebtorTypeKeyOperator,
				@psPurchaseOrderNo,
				@pnPurchaseOrderNoOperator,
				@pnReceivableTermsFromDays,
				@pnReceivableTermsToDays,
				@pnReceivableTermsOperator,
				@pnBillingFrequencyKey,
				@pnBillingFrequencyKeyOperator,
				@pbIsLocalClient,
				@pnIsLocalClientOperator)
		end
	end

	-- MF 6/11/2002
	-- If the PickListSearch is being used then the value within the @psPickListSearch parameter
	-- is to be combined with the other filter parameters and a staged search is to be performed.
	-- The staged search is to combine the NameFilter details and first search on :
	-- 1) an exact NAMECODE match
	-- 2) an inexact SEARCHKEY1 starting with the parameter
	-- 3) an inexact SEARCHKEY1 starting with the parameter up to the first comma.
	-- 4) an inexact SEARCHKEY2 OR SOUNDEX if the site control option is ON.
	-- 5) an inexact SEARCHKEY2 starting with the parameter 

	If @psPickListSearch is not null
	Begin
		-- If there is a comma in the field then only use the data up to the comma.

		Select	@sNameSearch=rtrim(Parameter)
		From	dbo.fn_Tokenise(@psPickListSearch, ',')
		Where	InsertOrder=1

		-- If the @sNameSearch is numeric then pad it with zeros to the 
		-- predefined length

		If isnumeric(@sNameSearch)=1
		Begin
			Select @sNameSearch=Replicate('0',S.COLINTEGER-len(@sNameSearch))+@sNameSearch 
			From SITECONTROL S
			Where S.CONTROLID='NAMECODELENGTH'
		End

		-- Check for exact match on NAMECODE

		set @pbExists=0
		set @sSQLString="Select @pbExists=1"+char(10)+
				"from NAME N"+char(10)+
				"where N.NAMECODE="+dbo.fn_WrapQuotes(@sNameSearch,0,0)+char(10)+
				"and exists"+char(10)+
				"(select *"+ char(10)+"	"+@sNameFilter+char(10)+" and XN.NAMENO=N.NAMENO)"

		exec sp_executesql @sSQLString,
				N'@pbExists		bit	OUTPUT,
				  @sNameSearch		nvarchar(254)',
				  @pbExists		=@pbExists OUTPUT,
				  @sNameSearch		=@sNameSearch

		If @pbExists=1
		Begin
			set @sNameFilter=@sNameFilter+char(10)+"	and XN.NAMECODE="+dbo.fn_WrapQuotes(@sNameSearch,0,0)
		End
		Else Begin
			-- If Name search with both keys site control is on 
			-- Search Key 1 or Search Key 2 begins with entered text

			set @sSQLString="Select @bSearchBothKeys=1"+char(10)+
					"from SITECONTROL"+char(10)+
					"where CONTROLID = 'Name search with both keys'"+char(10)+
					"and   COLBOOLEAN=1"

			exec sp_executesql @sSQLString,
					N'@bSearchBothKeys	bit		OUTPUT',
					  @bSearchBothKeys=@bSearchBothKeys 	OUTPUT

			-- Check for partial match on SEARCHKEY1 (or SEARCHKEY2) with the full PickListSearch

			set @sSQLString="Select @pbExists=1"+char(10)+
					"from NAME N"+char(10)+
					"where (N.SEARCHKEY1 like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+char(10)+
					CASE 	WHEN @bSearchBothKeys=1 
						THEN "or N.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)
					END+")"+
					"and exists"+char(10)+
					"(select *"+ char(10)+"	"+@sNameFilter+char(10)+" and XN.NAMENO=N.NAMENO)"

			exec sp_executesql @sSQLString,
					N'@pbExists		bit	OUTPUT',
					  @pbExists=@pbExists 		OUTPUT
	
			If @pbExists=1
			Begin
				set @sNameFilter=@sNameFilter+char(10)+"	and (XN.SEARCHKEY1 like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+char(10)+
									CASE 	WHEN @bSearchBothKeys=1 
										THEN "or N.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)
									END+")"
			End
			Else Begin
				-- Check for partial match on SEARCHKEY1 (or SEARCHKEY2) for the first part of the PickListSearch
	
				set @sSQLString="Select @pbExists=1"+char(10)+
						"from NAME N"+char(10)+
						"where (N.SEARCHKEY1 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)+char(10)+				
						CASE 	WHEN @bSearchBothKeys=1 
							THEN "or N.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)
						END+")"+				
						"and exists"+char(10)+
						"(select *"+ char(10)+"	"+@sNameFilter+char(10)+" and XN.NAMENO=N.NAMENO)"
	
				exec sp_executesql @sSQLString,
						N'@pbExists		bit	OUTPUT',
						  @pbExists=@pbExists 		OUTPUT
		
				If @pbExists=1
				Begin
					set @sNameFilter=@sNameFilter+char(10)+"	and (XN.SEARCHKEY1 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)+char(10)+
										CASE 	WHEN @bSearchBothKeys=1 
											THEN "or N.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)
										END+")"
				End

				-- If the Sitecontrol for searching by Sound Alike is on then search
				-- on Searchkey2 or the Sound alike 
				Else If exists (select * from SITECONTROL SC
						where SC.CONTROLID='SEARCHSOUNDEXFLAG'
						and SC.COLBOOLEAN=1)
				Begin
					set @sNameFilter=@sNameFilter+char(10)+"	and (XN.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+" OR dbo.fn_SoundsLike(XN.NAME)=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@psPickListSearch,0,0)+"))"
				End
				-- Otherwise just search on Searchkey2
				Else Begin
					set @sNameFilter=@sNameFilter+char(10)+"	and XN.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)
				End
			End
		End
	End
--select @sNameFilter
	-- Check if the result set is to be returned

	if @pbProduceResultSet = 1
	and @ErrorCode=0
	begin
		If @pnNameKey is null
		Begin
			if @bTempTableExists = 0
			begin
				-- No previous results were returned so just combine the filter
				-- details returned to create a simple WHERE EXISTS clause
		
				Set @sWhere =	char(10)+"	Where exists (select *"+
						char(10)+"	"+@sNameFilter+
						char(10)+"	and XN.NAMENO=N.NAMENO)"
			end
			else begin
				-- if previous result set details have been returned then they need
				-- to be combined with new query using the boolean operator passed
			 	-- as a parameter
				if upper(@psBuildOperator)='AND'
				begin
					-- insert an additional join to ensure the contents of the 
					-- previous queries also match with the current query
	
					set @sNameFilter=replace(@sNameFilter,'Where 1=1', '     join '+@sCurrentTable+' TC On (TC.NAMENO=XN.NAMENO)'+char(10)+'	Where 1=1')
					Set @sWhere =	char(10)+"	Where exists (select XN.NAMENO"+
							char(10)+"	"+@sNameFilter+
							char(10)+"	and XN.NAMENO=N.NAMENO)"
				end
				else if upper(@psBuildOperator)='OR'
				begin
					-- combine the results of the previous queries with the
					-- results of the current query
	
					Set @sWhere =	char(10)+"	Where exists (select XN.NAMENO"+
							char(10)+"	"+@sNameFilter+
							char(10)+"	and XN.NAMENO=N.NAMENO"+
							char(10)+"	union"+
							char(10)+"	select TC.NAMENO"+
							char(10)+"	from "+@sCurrentTable+" TC"+
							char(10)+"	where TC.NAMENO=N.NAMENO)"
				end
				else if upper(@psBuildOperator)='NOT'
				begin
					-- We want the Cases from the previous queries that 
					-- do not match with the current query
	
					Set @sWhere =	char(10)+"	Where exists("+
							char(10)+"	select TC.NAMENO"+
							char(10)+"	from "+@sCurrentTable+" TC"+
							char(10)+"	where TC.NAMENO=N.NAMENO)"+
							char(10)+"	and not exists"+
							char(10)+"	(select XN.NAMENO"+
							char(10)+"	"+@sNameFilter+
							char(10)+"	and XN.NAMENO=N.NAMENO)"
				end
			end
		end
		-- Now execute the constructed SQL to return the result set

		exec (@sSelectList + @sFrom + @sWhere + @sOrder)
		select 	@ErrorCode =@@Error,
			@pnRowCount=@@Rowcount

		-- Now drop the temporary table holding the results

		if  @bTempTableExists = 1
		and @ErrorCode=0
		begin
			Set @sSql = "drop table "+@sCurrentTable

			exec @ErrorCode=sp_executesql @sSql
		end
	end

	else if @ErrorCode=0
	begin
		-- Results are not being returned so we need to save the results
		-- in a temporary table.  

		if @bTempTableExists = 0
		begin
			-- This is the first search so it needs to be saved into a
			-- temporary table without the need to refer to earlier search results.

			exec (@sSelectList + @sNameFilter)

			select 	@ErrorCode =@@Error,
				@pnRowCount=@@Rowcount
		end	
		else begin
			-- A previous query has already been run and the results saved to a temporary
			-- table. Copy the Names from the first temporary table to another table

			Set  @sSql = 'Insert into ' + @sCopyTable + '(NAMENO) select NAMENO from ' + @sCurrentTable

			exec @ErrorCode=sp_executesql @sSql

			-- Now clear out the first temporary table so the Names returned from the
			-- current query can be loaded in combination with the previous query

			if @ErrorCode=0
			begin
				Set @sSql = 'delete from ' + @sCurrentTable
				exec sp_executesql @sSql
			end

			-- if previous result set details have been returned then they need
			-- to be combined with a new query using the boolean operator passed
		 	-- as a parameter

			if upper(@psBuildOperator)='AND'
			begin
				-- insert an additional join to ensure the contents of the 
				-- previous queries also match with the current query

				set @sNameFilter=replace(@sNameFilter,'Where 1=1', '     join '+@sCopyTable+' TC On (TC.NAMENO=XN.NAMENO)'+char(10)+'	Where 1=1')
				Set @sWhere =	char(10)+"	"+@sNameFilter
			end
			else if upper(@psBuildOperator)='OR'
			begin
				-- combine the results of the previous queries with the
				-- results of the current query

				Set @sWhere =	char(10)+"	"+@sNameFilter+
						char(10)+"	union"+
						char(10)+"	select TC.NAMENO"+
						char(10)+"	from "+@sCopyTable+" TC"
			end
			else if upper(@psBuildOperator)='NOT'
			begin
				-- We want the Cases from the previous queries that 
				-- do not match with the current query

				Set @sSelectList = 'Insert into ' + @sCurrentTable + '(NAMENO) select TC.NAMENO'

				Set @sWhere =	char(10)+"	from "+@sCopyTable+" TC"+
						char(10)+"	where not exists (select *"+
						char(10)+"	"+@sNameFilter+
						char(10)+"	and XN.NAMENO=TC.NAMENO)"
			end

			-- Now execute the constructed SQL to return the combined result set

			exec (@sSelectList + @sFrom + @sWhere)
			select 	@ErrorCode =@@Error,
				@pnRowCount=@@Rowcount
		end
	end

	-- Finally drop the copy temporary table if it exists
 	
	if exists(select * from tempdb.dbo.sysobjects where name = @sCopyTable)
	and @ErrorCode=0
	begin
		set @sSql = 'drop table ' + @sCopyTable
		exec @ErrorCode=sp_executesql @sSql			
	end

	RETURN @ErrorCode
go

grant execute on dbo.na_ListName  to public
go





