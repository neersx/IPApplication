-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ConstructWipHaving
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[wp_ConstructWipHaving]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.wp_ConstructWipHaving.'
	drop procedure dbo.wp_ConstructWipHaving
End
print '**** Creating procedure dbo.wp_ConstructWipHaving...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.wp_ConstructWipHaving
(
	@psWIPHaving			nvarchar(4000)	= null	OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbExternalUser			bit,			-- Mandatory. Flag to indicate if user is external.  Default on as this is the lowest security level
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLFilterCriteria		ntext		= null,	-- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)	
AS
-- PROCEDURE :	wp_ConstructWipHaving
-- VERSION :	2
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Work In Progress 
--		and constructs a HAVING clause.  
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18 Mar 2005  TM	RFC1896	1	Skeleton implementation
-- 15 May 2005	JEK	RFC2508	2	Extract @sLookupCulture and pass to translation instead of @psCulture


-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sAlertXML	 		nvarchar(400)

Declare @sSQLString			nvarchar(4000)

-- Aggregate Filter Criteria
Declare @nSumLocalBalanceFrom		decimal(11,2)	-- Returns aggregated rows where the total of the local balances 
Declare @nSumLocalBalanceTo		decimal(11,2)	-- that matches this filter criteria.
Declare @nSumLocalBalanceOperator 	tinyint		

Declare	@bExternalUser			bit

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

Set 	@nErrorCode			= 0
					
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE HAVING CLAUSE  ****/
/****                                       ****/
/***********************************************/

-- If filter criteria was passed, extract details from the XML
If @nErrorCode = 0 
and PATINDEX ('%<AggregateFilterCriteria>%', @ptXMLFilterCriteria)>0 
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the Filter elements using element-centric mapping (implement 
	--    Case Insensitive searching) 

	Set @sSQLString = 	
	"Select @nSumLocalBalanceFrom		= SumLocalBalanceFrom,"+CHAR(10)+	
	"	@nSumLocalBalanceTo		= SumLocalBalanceTo,"+CHAR(10)+
	"	@nSumLocalBalanceOperator	= SumLocalBalanceOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/wp_ListWorkInProgress/AggregateFilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      SumLocalBalanceFrom	decimal(11,2)	'SumLocalBalance/From/text()',"+CHAR(10)+
	"	      SumLocalBalanceTo		decimal(11,2)	'SumLocalBalance/To/text()',"+CHAR(10)+
	"	      SumLocalBalanceOperator	tinyint		'SumLocalBalance/@Operator/text()'"+CHAR(10)+	
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nSumLocalBalanceFrom		decimal(11,2)		output,
				  @nSumLocalBalanceTo		decimal(11,2)		output,
				  @nSumLocalBalanceOperator 	tinyint			output',
				  @idoc				= @idoc,
				  @nSumLocalBalanceFrom		= @nSumLocalBalanceFrom	output,
				  @nSumLocalBalanceTo		= @nSumLocalBalanceTo	output,
				  @nSumLocalBalanceOperator 	= @nSumLocalBalanceOperator output
		
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc			
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
		-- Initialise the 'Having' clause
		Set @psWIPHaving	= char(10)+ 'Having 1=1'
	
		If @nSumLocalBalanceFrom is not NULL
		or @nSumLocalBalanceTo is not NULL
		or @nSumLocalBalanceOperator is not null
		Begin
			Set @psWIPHaving = @psWIPHaving+char(10)+"	and	SUM(ISNULL(W.BALANCE,0))"+dbo.fn_ConstructOperator(@nSumLocalBalanceOperator,@Numeric,@nSumLocalBalanceFrom, @nSumLocalBalanceTo,@pbCalledFromCentura)
		End
	End
End


RETURN @nErrorCode
GO

Grant execute on dbo.wp_ConstructWipHaving  to public
GO

