-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FSConstructWhere.
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_FSConstructWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_FSConstructWhere'
	Drop procedure [dbo].[gl_FSConstructWhere]
	Print '**** Creating Stored Procedure dbo.gl_FSConstructWhere...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_FSConstructWhere  
(		
	@pnLineId			int	,			-- Line Id
	@psFilterId 			nvarchar(40),			-- Filter Id
	@psReturnClause			nvarchar(4000)  = null output, 	-- variable to hold the constructed "where" clause 
	@pnUserIdentityId		int		= null,		-- @pnUserIdentityId must accept null (when called from InPro)
	@psCulture			nvarchar(5)	= null, 	-- the language in which output is to be expressed
	@psEntityTableName		varchar(30),
	@psProfitCentreTableName	varchar(30),
	@psLedgerAccountTableName	varchar(30)		
)
AS

-- PROCEDURE:	gl_FSConstructWhere
-- VERSION:	2
-- SCOPE:	Centura
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter General Ledger Transactions and
--			constructs a JOIN and WHERE clause. 

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 31-Aug-2004  MB	9658	1	Procedure created
-- 23-May-2005  MB	11278	2	Performance improvement


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @nEntity 		int
Declare @sProfitCentreCodeWhere nvarchar(4000)
Declare @sAccountIdWhere 	nvarchar(4000)
Declare @sSql	 		nvarchar(4000)


Set @nErrorCode      		= 0
Set @sProfitCentreCodeWhere 	= ''
Set @sAccountIdWhere 		= ''

If @nErrorCode = 0
Begin
	
	Set @sSql = 	
		"Select @nEntity = ENTITYNO 
		from	" + @psEntityTableName + "
		where LINEID = @pnLineId 
		and FILTERID = @psFilterId" 
		
	Exec @nErrorCode = sp_executesql @sSql,
				N'@nEntity 	int output,
				@pnLineId 	int,
				@psFilterId 	nvarchar(40)',
				@nEntity 	= @nEntity output,
				@pnLineId 	= @pnLineId,
				@psFilterId 	= @psFilterId
End

If @nErrorCode = 0
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	Set @psReturnClause = ' 1 = 1'
	If @nEntity is not null
		Set @psReturnClause = @psReturnClause + ' AND A.NAMENO = ' + cast ( @nEntity as nvarchar )
End
		
		-- construct Profit Centre Codes as CSV

If @nErrorCode = 0
Begin
	Set @sSql = 
		"Select @sProfitCentreCodeWhere = @sProfitCentreCodeWhere + nullif(',', ',' + @sProfitCentreCodeWhere) + dbo.fn_WrapQuotes(PROFITCENTRECODE,0,0)
		from " + @psProfitCentreTableName  + "
		where 	LINEID = @pnLineId 
		and 	FILTERID = @psFilterId" 
	Exec @nErrorCode = sp_executesql @sSql,
				N'
				@sProfitCentreCodeWhere nvarchar(4000) output,
				@pnLineId 	int,
				@psFilterId 	nvarchar(40)',
				@sProfitCentreCodeWhere = @sProfitCentreCodeWhere output,
				@pnLineId 	= @pnLineId,
				@psFilterId 	= @psFilterId
End

If @nErrorCode = 0 and @sProfitCentreCodeWhere <> ''
	Set @psReturnClause = @psReturnClause+char(10)+ " AND B.PROFITCENTRECODE IN  ( " + @sProfitCentreCodeWhere + ") "

	-- construct Account Ids as CSV

If   @nErrorCode = 0
Begin
	Set @sSql =
		"Select @sAccountIdWhere = @sAccountIdWhere + nullif(',', ',' + @sAccountIdWhere) + cast ( ACCOUNTID as nvarchar)   
		from	" + @psLedgerAccountTableName  + "
		where 	LINEID = @pnLineId 
		and 	FILTERID = @psFilterId" 
	Exec @nErrorCode = sp_executesql @sSql,
				N'
				@sAccountIdWhere nvarchar(4000) output,
				@pnLineId 	int,
				@psFilterId 	nvarchar(40)',
				@sAccountIdWhere = @sAccountIdWhere output,
				@pnLineId 	= @pnLineId,
				@psFilterId 	= @psFilterId
End

If @nErrorCode = 0 and @sAccountIdWhere <> ''
	Set @psReturnClause = @psReturnClause+char(10)+ " AND C.ACCOUNTID IN  ( " + @sAccountIdWhere + ") "


Return @nErrorCode
GO

Grant execute on dbo.gl_FSConstructWhere  to public
GO
