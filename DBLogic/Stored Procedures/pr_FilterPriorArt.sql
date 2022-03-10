-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pr_FilterPriorArt
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pr_FilterPriorArt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pr_FilterPriorArt.' 
	drop procedure dbo.pr_FilterPriorArt
	print '**** Creating procedure dbo.pr_FilterPriorArt...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.pr_FilterPriorArt
(
	@psReturnClause			nvarchar(max)  = null output, 
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser		bit		= null,
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)		
-- PROCEDURE :	pr_FilterPriorArt
-- VERSION :	1
-- DESCRIPTION:	pr_FilterPriorArt is responsible for the management of selected/deselected rows 
--		in the search result set .
-- CALLED BY :	

-- MODIFICTIONS :
-- Date				Who	Number	Version	Details
-- ----				---	-------	-------	-------------------------------------
-- 03 Feb 2011		KR	RFC6563	1		Procedure created

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @nTableCount		tinyint

Declare @sCurrentTable 		nvarchar(50)	

Declare @pbExists		bit
Declare @bAddedCases		bit
Declare	@bTickedCases		bit
Declare @nOperator		bit

Declare @nCaseCount		int

Declare @sSql			nvarchar(4000)
Declare @sSQLString		nvarchar(4000)
Declare @sSelectList		nvarchar(4000)  -- the SQL list of columns to return
declare @sWIPWhere		nvarchar(4000)
Declare @sNotExists		nvarchar(100)	
Declare @sWhere			nvarchar(4000) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	

-- Intialise Variables
Set @nErrorCode			=0 

Declare @sPriorArtWhere nvarchar(max)

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML		
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

Set @nErrorCode = @@Error

If @nErrorCode = 0
Begin
	exec @nErrorCode=dbo.pr_ConstructPriorArtWhere	
				@psPriorArtWhere		= @sPriorArtWhere	  	OUTPUT, 
				@pnUserIdentityId	= @pnUserIdentityId,	
				@psCulture		= @psCulture,	
				@pbExternalUser		= @pbIsExternalUser,
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
				@pbCalledFromCentura	= @pbCalledFromCentura
							 
End

If  @nErrorCode = 0
	Set @psReturnClause = @sPriorArtWhere


RETURN @nErrorCode
go

grant execute on dbo.pr_FilterPriorArt  to public
go



