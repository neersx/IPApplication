-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ConstructWipTemplateWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ConstructWipTemplateWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ConstructWipTemplateWhere.'
	Drop procedure [dbo].[wp_ConstructWipTemplateWhere]
End
Print '**** Creating Stored Procedure dbo.wp_ConstructWipTemplateWhere...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wp_ConstructWipTemplateWhere
(
	@psWipTemplateWhere		nvarchar(4000)	= null	OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null	-- The filtering to be performed on the result set.			
)
as
-- PROCEDURE:	wp_ConstructWipTemplateWhere
-- VERSION:	8
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Work In Progress Template
--		and constructs a Where clause.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Jun 2005	TM	RFC2575	1	Procedure created
-- 16 Jun 2005 	TM	RFC2575	2	Use 'or' in the WipCategory and UsedByApplication logic.
-- 21 Jun 2005	TM	RFC2575	3	Improve performance of the UsedByApplication filter criteria logic.
-- 03 Jul 2006	SW	RFC4024	4	Implement the best fit filtering based on the information supplied 
--					in the ContextCriteria node of the @ptXMLFilterCriteria
-- 24 Oct 2006	SW	RFC4024	5	Bug fix for not using joint table when constructing where clause. 
-- 08 Feb 2008	SW	RFC6062	6	Filter by NOTINUSEFLAG to filter out WIP items that are no longer in use. 
-- 04 Nov 2011	ASH	R11460	7	 Cast integer columns as nvarchar(11) data type.    
-- 31 Oct 2018	DL	DR-45102	8	Replace control character (word hyphen) with normal sql editor hyphen

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	N
--	NRL
--	NTR
--	WIP

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int

Declare @sSQLString		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

-- Declare Filter Variables
Declare @sWipTemplateKey 			nvarchar(6)	-- The primary key (and code) for the WIP Template.		
Declare @nWipTemplateKeyOperator		tinyint	
Declare @sPickListSearch			nvarchar(30)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
Declare @bExists				bit
Declare @bIsServices				bit		-- Indicates that the service related WIP Templates should be returned; i.e. those with WIP Category key of 'SC'.
Declare @bIsDisbursements			bit		-- Indicates that the third party disbursement related WIP Templates should be returned; i.e. those with WIP Category key of 'PD'.
Declare @bIsOverheads				bit		-- Indicates that the overhead recovery related WIP Templates should be returned; i.e. those with WIP Category key of 'OR'.

Declare @nUsedBy				smallint	-- Indicates that rows available for use in certain context; i.e. for Billing: UsedBy&1 = 1; Work in Progres: UsedBy&2 = 2; Timesheet: UsedBy&4 = 4; Accounts Payable: UsedBy&8 = 8.
Declare @bIsBilling				bit		-- Indicates that rows available for use in the context of Billing should be returned; i.e. UsedBy&1 = 1.
Declare @bIsWip					bit		-- Indicates that rows available for use in the context of Work in Progress should be returned; i.e. UsedBy&2 = 2.
Declare @bIsTimesheet				bit		-- Indicates that rows available for use in the context of Timesheet should be returned; i.e. UsedBy&4 = 4.
Declare @bIsPayable				bit		-- Indicates that rows available for use in the context of Accounts Payable should be returned; i.e. UsedBy&8 = 8.

-- Information about the context in which the information is being used.
Declare @nStaffKey				int		-- The key of the staff member being recorded on the XWIP.
Declare @nNameKey				int		-- The key of the name the WIP is being recorded against. Either NameKey or CaseKey should be provided - not both.
Declare @nCaseKey				int		-- The key of the case the WIP is being recorded against. Either NameKey or CaseKey should be provided - not both.

Declare @nCount					int		-- Current table row being processed.
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr					nchar(4)

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
Set	@nUsedBy				= 0

set 	@sFrom					= char(10)+"From WIPTEMPLATE XWIP"
set 	@sWhere 				= char(10)+"	WHERE 1=1"
set 	@sLookupCulture 			= dbo.fn_GetLookupCulture(@psCulture, null, 0)

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the filter criteria using element-centric mapping (implement 
	--    Case Insensitive searching were required)   

	Set @sSQLString = 	
	"Select @sWipTemplateKey	= WipTemplateKey,"+CHAR(10)+
	"	@nWipTemplateKeyOperator= WipTemplateKeyOperator,"+CHAR(10)+
	"	@sPickListSearch	= upper(PickListSearch),"+CHAR(10)+
	"	@bIsServices		= IsServices,"+CHAR(10)+
	"	@bIsDisbursements	= IsDisbursements,"+CHAR(10)+
	"	@bIsOverheads		= IsOverheads,"+CHAR(10)+	
	"	@bIsBilling		= IsBilling,"+CHAR(10)+
	"	@bIsWip			= IsWip,"+CHAR(10)+
	"	@bIsTimesheet		= IsTimesheet,"+CHAR(10)+
	"	@bIsPayable		= IsPayable"+CHAR(10)+

	"from	OPENXML (@idoc, '//wp_ListWipTemplate/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      WipTemplateKey		nvarchar(6)	'WipTemplateKey/text()',"+CHAR(10)+
	"	      WipTemplateKeyOperator	tinyint		'WipTemplateKey/@Operator/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(30)	'PickListSearch/text()',"+CHAR(10)+	
	"	      IsServices		bit		'WipCategory/IsServices/text()',"+CHAR(10)+
	"	      IsDisbursements		bit		'WipCategory/IsDisbursements/text()',"+CHAR(10)+	
	"	      IsOverheads		bit		'WipCategory/IsOverheads/text()',"+CHAR(10)+	
	"	      IsBilling			bit		'UsedByApplication/IsBilling/text()',"+CHAR(10)+	
	"	      IsWip			bit		'UsedByApplication/IsWip/text()',"+CHAR(10)+
	"	      IsTimesheet		bit		'UsedByApplication/IsTimesheet/text()',"+CHAR(10)+	
	"	      IsPayable			bit		'UsedByApplication/IsPayable/text()'"+CHAR(10)+	
	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sWipTemplateKey 		nvarchar(6)		output,
				  @nWipTemplateKeyOperator	tinyint			output,
				  @sPickListSearch		nvarchar(30)		output,
				  @bIsServices			bit			output,
				  @bIsDisbursements		bit			output,
				  @bIsOverheads			bit			output,
				  @bIsBilling			bit			output,
				  @bIsWip			bit			output,
				  @bIsTimesheet			bit			output,
				  @bIsPayable			bit			output',
				  @idoc				= @idoc,	
				  @sWipTemplateKey		= @sWipTemplateKey	output,
				  @nWipTemplateKeyOperator	= @nWipTemplateKeyOperator output,
				  @sPickListSearch		= @sPickListSearch	output,
				  @bIsServices			= @bIsServices		output,
				  @bIsDisbursements		= @bIsDisbursements	output,
				  @bIsOverheads			= @bIsOverheads		output,
				  @bIsBilling			= @bIsBilling		output,
				  @bIsWip			= @bIsWip		output,
				  @bIsTimesheet			= @bIsTimesheet		output,
				  @bIsPayable			= @bIsPayable		output			  


	-- 2) Retrieve the context criteria using element-centric mapping
	Set @sSQLString = 	
	"Select @nCaseKey		= CaseKey"+CHAR(10)+
	
	"from	OPENXML (@idoc, '//wp_ListWipTemplate/ContextCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseKey			int		'CaseKey/text()'"+CHAR(10)+	
	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nCaseKey			int			output',
				  @idoc				= @idoc,
				  @nCaseKey			= @nCaseKey		output
			
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
		If @sWipTemplateKey is not NULL
		or @nWipTemplateKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XWIP.WIPCODE " + dbo.fn_ConstructOperator(@nWipTemplateKeyOperator,@String,@sWipTemplateKey, null,0)
		End		

		If @bIsServices = 1
		or @bIsDisbursements = 1
		or @bIsOverheads = 1
		Begin
			Set @sWhere = @sWhere+char(10)+"and exists (Select 1"	
					     +char(10)+"	    from WIPTYPE WT"
					     +char(10)+"	    where WT.WIPTYPEID = XWIP.WIPTYPEID"

			Set @sWhere = @sWhere+char(10)+"and ("
			Set @sOr    = NULL

			If @bIsServices = 1
			Begin
				Set @sWhere = @sWhere+char(10)+"	WT.CATEGORYCODE = 'SC'"
				Set @sOr    =' OR '
			End

			If @bIsDisbursements = 1
			Begin
				Set @sWhere = @sWhere+@sOr+char(10)+"	WT.CATEGORYCODE = 'PD'"
				Set @sOr    =' OR '
			End

			If @bIsOverheads = 1
			Begin
				Set @sWhere = @sWhere+@sOr+char(10)+"	WT.CATEGORYCODE = 'OR'"
			End		
			
			Set @sWhere = @sWhere+"))"
		End

		If (@nCaseKey is not null)
		Begin

			Set @sFrom = @sFrom
			    + char(10)+"join CASES C		on (C.CASEID = "+ISNULL(CAST(@nCaseKey as varchar(11)), 'NULL')+")"

			Set @sWhere = @sWhere
			    + char(10) + "AND (	XWIP.CASETYPE		= C.CASETYPE		OR XWIP.CASETYPE	is NULL )"
			    + char(10) + "AND (	XWIP.COUNTRYCODE 	= C.COUNTRYCODE 	OR XWIP.COUNTRYCODE 	IS NULL )"
			    + char(10) + "AND (	XWIP.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR XWIP.PROPERTYTYPE 	IS NULL )"
			    + char(10) + "AND (	XWIP.ACTION 		in (Select OA.ACTION"
			    + char(10) + "				    from OPENACTION OA"
			    + char(10) + "				    where OA.CASEID = "+ISNULL(CAST(@nCaseKey as varchar(11)), 'NULL')
			    + char(10) + "				    and   OA.POLICEEVENTS = 1)"
			    + char(10) + "OR XWIP.ACTION 	IS NULL )"

		End

		If @bIsBilling = 1
		Begin
			Set @nUsedBy = @nUsedBy|1
		End	
		
		If @bIsWip = 1
		Begin
			Set @nUsedBy = @nUsedBy|2
		End

		If @bIsTimesheet = 1
		Begin
			Set @nUsedBy = @nUsedBy|4			
		End

		If @bIsPayable = 1
		Begin
			Set @nUsedBy = @nUsedBy|8
		End

		If @nUsedBy > 0
		Begin
			Set @sWhere = @sWhere+char(10)+" and XWIP.USEDBY&"+cast(@nUsedBy as varchar(5))+">0" 	
		End

		-- Filter out not in use WIP Code
		Set @sWhere=@sWhere+char(10)+"and XWIP.NOTINUSEFLAG = 0"

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced. The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			-- If the length of PickListSearch does not exceed the maximum length of the Code
			
			If LEN(@sPickListSearch) <= 6
			Begin
				Set @bExists = 0
				-- Check if Code Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						  @sFrom+char(10)+
						  @sWhere+
						  "and (XWIP.WIPCODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
		
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(30)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (XWIP.WIPCODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (XWIP.WIPCODE like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
								     " or upper("+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'XWIP',@sLookupCulture,0)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End
			Else 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'XWIP',@sLookupCulture,0)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
			End
		End	
	End
End

If @nErrorCode=0
Begin 		
	Set @psWipTemplateWhere = ltrim(rtrim(@sFrom+char(10)+@sWhere))
End


Return @nErrorCode
GO

Grant execute on dbo.wp_ConstructWipTemplateWhere to public
GO
