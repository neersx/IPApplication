---------------------------------------------------------------------------------------------
-- Creation of dbo.cs_RunCaseDocItem
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_RunCaseDocItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_RunCaseDocItem.'
	drop procedure [dbo].[cs_RunCaseDocItem]
	Print '**** Creating Stored Procedure dbo.cs_RunCaseDocItem...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.cs_RunCaseDocItem
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnDocItemKey 		int,		-- Mandatory
	@pnCaseKey 		int 		= null,
	@psCaseReference 	nvarchar(30) 	= null
)
AS
-- PROCEDURE:	cs_RunCaseDocItem
-- VERSION:	7
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedures executes a doc item. The procedure returns
--		whatever the doc item selects as a result set. It caters for doc items
--		defined as both SQL statements and stored procedures.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Aug 2004  TM	R1233	1	Procedure created
-- 02 Sep 2004	JEK	R1377	2	Pass new Centura parameter to fn_WrapQuotes
-- 16 May 2005	TM	R2554	3	Modify procedure to handle long strings by implementing pt_GetDocItemSql.
-- 08 Jun 2005	JEK	R2690	4	Handle SQL_QUERY column of type text as well as ntext
-- 22 Dec 2010	MF	R10129	5	Allow additional parameters to be passed into the SQL associated with the Doc Item:
--						@pnUserIdentityId as :gstrUserId
--						@psCulture        as :gstrCulture
-- 08 Oct 2014	MF	R40092	6	DocItems that are defined as a stored procedure need to be extended to allow additional parameters:
--						@pnUserIdentityId as @pnUserIdentityId
--						@psCulture        as @psCulture
-- 07 Sep 2018	AV	74738	7	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @nErrorCode 		int
Declare	@sSQLString		nvarchar(max)

Declare @sUserSQL		nvarchar(max)
Declare @nItemType		smallint	-- For a stored procedure @nItemType = 1.

-- Initialise variables
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin
	-- Get the user defined SELECT statement that needs to be executed
	-- along with an Item Type 
	
	Set @sSQLString=
	"Select @sUserSQL  	= convert(nvarchar(max),SQL_QUERY),
		@nItemType 	= I.ITEM_TYPE"

	-- If the @psCaseReference is not provided, it is extracted from the @pnCaseKey:  
	If @pnCaseKey is not null
	and @psCaseReference is null
	Begin
		Set @sSQLString = @sSQLString+"," 
			+char(10)+"@psCaseReference	= C.IRN" 
	  		+char(10)+"from ITEM I" 
			+char(10)+"left join CASES C	on (C.CASEID = @pnCaseKey)" 
			+char(10)+"Where I.ITEM_ID = @pnDocItemKey"

	End
	Else Begin
		Set @sSQLString = @sSQLString+
			+char(10)+"from ITEM I" 
			+char(10)+"Where I.ITEM_ID = @pnDocItemKey"		
	End	

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sUserSQL		nvarchar(max)	OUTPUT,
				  @nItemType		smallint	OUTPUT,
				  @psCaseReference	nvarchar(30)	OUTPUT,
				  @pnDocItemKey		int,
				  @pnCaseKey		int',
				  @sUserSQL		= @sUserSQL	OUTPUT,
				  @nItemType		= @nItemType	OUTPUT,
				  @psCaseReference	= @psCaseReference OUTPUT,
				  @pnDocItemKey		= @pnDocItemKey,
				  @pnCaseKey		= @pnCaseKey
End

-- If the @sUserSQL is an SQL statement: 
If  @sUserSQL is not null
and @nItemType <> 1
and @nErrorCode = 0
Begin	
	-- In the user defined SQL replace the constants
	Set @sUserSQL  = replace(@sUserSQL,':gstrEntryPoint',dbo.fn_WrapQuotes(@psCaseReference,0,0))
	Set @sUserSQL  = replace(@sUserSQL,':gstrUserId',    dbo.fn_WrapQuotes(@pnUserIdentityId,0,0))

	If @psCulture is not null
		Set @sUserSQL  = replace(@sUserSQL,':gstrCulture',   dbo.fn_WrapQuotes(@psCulture,0,0))
	else
		Set @sUserSQL  = replace(@sUserSQL,':gstrCulture',   "''")
	
	exec @nErrorCode = sp_executesql @sUserSQL 	

	Set @pnRowCount = @@RowCount
End
-- If the @sUserSQL is a stored procedure name:
Else 	If  @sUserSQL is not null
	and @nItemType = 1
	and @nErrorCode = 0 
Begin
	-------------------------------------------
	-- Pass @psCaseReference to the stored 
	-- procedure as the first unnamed parameter
	-------------------------------------------
	Set @sSQLString = @sUserSQL + ' ' + dbo.fn_WrapQuotes(@psCaseReference,0,0)
	
	-----------------------------------------
	-- Check if the stored procedure has a
	-- parameter to accept the UserIdentityId
	-----------------------------------------
	If exists(select 1 from INFORMATION_SCHEMA.PARAMETERS 
	          where SPECIFIC_NAME=@sUserSQL
	          and ORDINAL_POSITION=2
	          and DATA_TYPE='int')
		Set @sSQLString=@sSQLString + ', ' + CAST(@pnUserIdentityId as nvarchar)
	
	-----------------------------------------
	-- Check if the stored procedure has a
	-- parameter to accept the Culter
	-----------------------------------------
	If exists(select 1 from INFORMATION_SCHEMA.PARAMETERS 
	          where SPECIFIC_NAME=@sUserSQL
	          and ORDINAL_POSITION=3
	          and DATA_TYPE='nvarchar')
	and @psCulture is not null
		Set @sSQLString=@sSQLString + ', ' + dbo.fn_WrapQuotes(@psCulture,0,0)

	Exec (@sSQLString) 

	Select	@nErrorCode = @@ERROR,
		@pnRowCount = @@RowCount
End


Return @nErrorCode
GO

Grant exec on dbo.cs_RunCaseDocItem to public
GO
