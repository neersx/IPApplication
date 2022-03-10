-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_TraverseAccount
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_TraverseAccount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_TraverseAccount.'
	drop procedure dbo.gl_TraverseAccount
	print '**** Creating procedure dbo.gl_TraverseAccount...'
	print ''
end
go

CREATE PROCEDURE dbo.gl_TraverseAccount
(	
	@psAccountTable      Nvarchar(128),
	@prsRelatedAcctTable Nvarchar(128) OUTPUT
)
AS
-- PROCEDURE :	gl_TraverseAccount
-- VERSION :	3
-- DESCRIPTION:	The proc creates the ##RELATEDACCOUNT temporary table
--				and lists all child accounts in it for every account in the 
--				##TEMPACCOUNTS table
-- CALLED BY :	gl_ListAccountComparison and gl_ListAccountTransactions
-- DEPENDICES : gl_PopulateRelatedAccounts

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 2.5.03	MB			Created
-- 6.2.04	SFOO	8851		1. Replaced Cursor with Temp table,
--			9614		2. Returned an unique global table name for calling 
--						stored procedure to access
--			8851		3. Supplied acct table name. 
-- 23-May-2005  MB	11278	3	Performance improvement

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @iAccount 		int
Declare @iRet 			int
Declare	@nErrorCode		int
Declare @sSql			nvarchar(1000)

Set @nErrorCode = 0

	-- Prepare unique global temporary table.
	-- Note the table name is assigned to an output param,
	-- so that it will be visible from the calling stored procedures.
If @nErrorCode = 0
Begin
	Set @prsRelatedAcctTable = '##RELACCT_' +
					REPLACE( CONVERT(Nvarchar(100), NEWID()), '-', '_' )

	Set @sSql = 'Create table ' + @prsRelatedAcctTable + ' (PARENTID int, CHILDID int)'

	Exec @nErrorCode=sp_executesql @sSql
End

-- 11278	Check if need to do the travers. If the ledger accounts are "flat" there is no need for travers
If exists (select TOP 1 ACCOUNTID from LEDGERACCOUNT where PARENTACCOUNTID is NOT NULL)
Begin

	If @nErrorCode = 0
	Begin
		Set @sSql = 'Select @iAccount=MIN(DISTINCT ACCOUNTID)
			     from ' + @psAccountTable
		Exec @nErrorCode=sp_executesql @sSql, N'@iAccount Int Output', @iAccount Output
	End

	While (@iAccount is not Null AND @nErrorCode = 0)
	Begin
		Exec @iRet = gl_PopulateRelatedAccounts @iAccount, @iAccount, @prsRelatedAcctTable
		If @iRet = 0
		Begin 
			Set @sSql = 'Insert into ' + @prsRelatedAcctTable +
					' (PARENTID, CHILDID) values (@iAccount, @iAccount)'
				
			Exec @nErrorCode=sp_executesql @sSql,
				N'@iAccount Int',
				@iAccount
		End

		If @nErrorCode = 0
		Begin
			Set @sSql = 'Select @iAccount=MIN(DISTINCT ACCOUNTID)
				from ' + @psAccountTable + 
			      ' where ACCOUNTID > @iAccount'

			Exec @nErrorCode=sp_executesql @sSql,
				N'@iAccount Int Output',
				@iAccount Output
		End
	End
End
Else
Begin
	Exec ('INSERT INTO ' + @prsRelatedAcctTable + ' 
		(PARENTID, CHILDID) 
		SELECT DISTINCT ACCOUNTID, ACCOUNTID
	     FROM ' + @psAccountTable )
	Set @nErrorCode = @@ERROR
						
End
Return @nErrorCode

go

Grant execute on dbo.gl_TraverseAccount to public
go

/*
To Test:
Declare @sSql nvarchar(1000)
Declare @sAccountTable nvarchar(128)
Declare @sTableName nvarchar(128)

drop table ##TEMPACCOUNTS
CREATE TABLE ##TEMPACCOUNTS
(ACCOUNTID INT)
INSERT INTO ##TEMPACCOUNTS VALUES(3)
INSERT INTO ##TEMPACCOUNTS VALUES(9)
Set @sAccountTable='##TEMPACCOUNTS'
Exec dbo.gl_TraverseAccount @sAccountTable, @sTableName OUTPUT
Set @sSql = 'SELECT * FROM ' + @sTableName
Exec sp_executesql @sSql
*/
