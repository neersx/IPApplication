-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_FilterWip
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wp_FilterWip]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wp_FilterWip.' 
	drop procedure dbo.wp_FilterWip
	print '**** Creating procedure dbo.wp_FilterWip...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.wp_FilterWip
(
	@psReturnClause			nvarchar(max)  = null output, 
	@psCurrentCaseTable		nvarchar(60)	= null output, 	-- is the name of the the global temporary table that may hold the list of filtered CaseKeys.	
	@psCurrentWipTable		nvarchar(60)	= null output,	-- is the name of the the global temporary table that may hold the keys of WIP items.
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser		bit		= null,
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)		
-- PROCEDURE :	wp_FilterWip
-- VERSION :	4
-- DESCRIPTION:	wp_FilterWip is responsible for the management of selected/deselected rows 
--		in the search result set (BillableWipGroup).
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Details
-- ----		---	-------	-------	-------------------------------------
-- 13 Apr 2005	TM	RFC1896	1	Procedure created
-- 06 Jun 2005	TM	RFC2554	2	Drop temporary table before creating one.
-- 18 Sep 2013  MS      DR1006  3       Added split wip multi debtor functionality
-- 16 Apr 2014	MF	R33427	4	Increase variables from nvarchar(4000) to nvarchar(max) to avoid truncation
--					of dynamic SQL.

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

Declare @sSql			nvarchar(max)
Declare @sSQLString		nvarchar(max)
Declare @sSelectList		nvarchar(max)  -- the SQL list of columns to return
declare @sWIPWhere		nvarchar(max)
Declare @sNotExists		nvarchar(100)	
Declare @sWhere			nvarchar(max) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	

-- Intialise Variables
Set @nErrorCode			=0 

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML		
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

Set @nErrorCode = @@Error

If @nErrorCode = 0
Begin
	exec @nErrorCode=dbo.wp_ConstructWipWhere	
				@psWIPWhere		= @sWIPWhere	  	OUTPUT, 			
				@psCurrentCaseTable	= @psCurrentCaseTable	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,	
				@psCulture		= @psCulture,	
				@pbExternalUser		= @pbIsExternalUser,
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
				@pbCalledFromCentura	= @pbCalledFromCentura			 
End

-- Check to see if there are any selected/deselected rows:	
If @nErrorCode=0
Begin
	Set @sSql="
	Select	@nOperator	= Operator		
	from	OPENXML (@idoc, '//wp_ListWorkInProgress/FilterCriteria/BillableWipGroup',2)
		WITH (
		      Operator	tinyint	'@Operator/text()'
		     )
	Where Operator in (1,0)"

	exec @nErrorCode=sp_executesql @sSql,
				N'@nOperator	bit		Output,
				  @idoc		int',
				  @nOperator	= @nOperator	Output,
				  @idoc		= @idoc
End

If  @nErrorCode = 0
and @nOperator is not null
Begin
	-- Get the name of the temporary table passed in as a parameter 
	If @nErrorCode=0
	Begin
		If @psCurrentWipTable is null
		Begin
			Set @sCurrentTable = '##SEARCHWIP_' + Cast(@@SPID as varchar(10))
			Set @psCurrentWipTable = @sCurrentTable
		End
		Else Begin		
			Set @sCurrentTable = @psCurrentWipTable
		End
	End		

	-- Drop the temporary table if it exists:
	If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
	and @nErrorCode=0
	Begin
		Set @sSql = "drop table "+@sCurrentTable			
		exec @nErrorCode=sp_executesql @sSql
	End

	If @nErrorCode=0
	Begin
		Set @sSql = 'Create Table ' + @sCurrentTable + ' (EntityKey int, CaseKey int, NameKey int)'	
		exec @nErrorCode=sp_executesql @sSql				
	End

	If @nErrorCode=0
	Begin
		Set @sSelectList = 	'Insert into ' + @sCurrentTable + ' (EntityKey, CaseKey, NameKey)'+char(10)+
				    	'select XW.ENTITYNO, XW.CASEID, XW.ACCTCLIENTNO'+char(10)+
					@sWIPWhere

		exec (@sSelectList)
	End

	-- Add explicitly selected Billable WIP combinations:
	If  @nErrorCode = 0
	and @nOperator = 0
	Begin
		Set @sSql="Delete "+@sCurrentTable+char(10)+
			  "from "  +@sCurrentTable+" X"+char(10)+
			   "left join (	select EntityKey, CaseKey, NameKey"+char(10)+
		  	  " 		from	OPENXML (@idoc, '//wp_ListWorkInProgress/FilterCriteria/BillableWipGroup/BillableWip', 2)"+char(10)+
	 	 	  "		WITH (	EntityKey	int	'EntityKey/text()',"+char(10)+
	  	  	  "			CaseKey		int	'CaseKey/text()',"+char(10)+
	  	  	  "			NameKey		int	'NameKey/text()')"+char(10)+
	  	  	  "	) X2 	on  (X2.EntityKey = X.EntityKey"+char(10)+
		  	  " 		and (ISNULL(X2.CaseKey,'') = ISNULL(X.CaseKey,'') and  ISNULL(X2.NameKey,'') = ISNULL(X.NameKey,'')))"+char(10)+
			  "Where X2.EntityKey is null"

		exec @nErrorCode=sp_executesql @sSql,
						N'@idoc		int',
						  @idoc		= @idoc
	End
	Else If  @nErrorCode = 0
	     and @nOperator = 1
	Begin
		Set @sSql=
		  "Delete "+@sCurrentTable+char(10)+
		  "from "  +@sCurrentTable+" X"+char(10)+
		  "join (	select EntityKey, CaseKey, NameKey"+char(10)+
		  " 		from	OPENXML (@idoc, '//wp_ListWorkInProgress/FilterCriteria/BillableWipGroup/BillableWip', 2)"+char(10)+
	 	  "		WITH (	EntityKey	int	'EntityKey/text()',"+char(10)+
	  	  "			CaseKey		int	'CaseKey/text()',"+char(10)+
	  	  "			NameKey		int	'NameKey/text()')"+char(10)+
	  	  "	) X2 	on  (X2.EntityKey = X.EntityKey"+char(10)+
		  " 		and (ISNULL(X2.CaseKey,'') = ISNULL(X.CaseKey,'') and  ISNULL(X2.NameKey,'') = ISNULL(X.NameKey,'')))"		

		exec @nErrorCode=sp_executesql @sSql,
					N'@idoc		int',
					  @idoc		= @idoc
	End

	-- The current Where clause can now be modified to just return the Cases 
	-- in the temporary table.
	Set @psReturnClause =	char(10)+"	FROM      WORKINPROGRESS XW"+
				char(10)+"	where exists (	select * from "+@sCurrentTable+" XW2"+
				char(10)+"			where ((XW2.EntityKey = XW.ENTITYNO)"+
				char(10)+"                      and (ISNULL(XW2.CaseKey,'') = ISNULL(XW.CASEID,'') and ISNULL(XW2.NameKey,'') = ISNULL(XW.ACCTCLIENTNO,''))))"
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

End
Else If  @nErrorCode = 0
     and @nOperator is null
Begin
	-- The current Where clause can now be modified to just return the Cases 
	-- in the temporary table.
	Set @psReturnClause =	@sWIPWhere
End

RETURN @nErrorCode
go

grant execute on dbo.wp_FilterWip  to public
go



