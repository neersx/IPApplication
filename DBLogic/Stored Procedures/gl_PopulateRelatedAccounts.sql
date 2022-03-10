-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_PopulateRelatedAccounts
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_PopulateRelatedAccounts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_PopulateRelatedAccounts.'
	drop procedure dbo.gl_PopulateRelatedAccounts
	print '**** Creating procedure dbo.gl_PopulateRelatedAccounts...'
	print ''
end
go

CREATE PROCEDURE dbo.gl_PopulateRelatedAccounts
as
  -- blank to create sp so the next ALTER statement will work with no warnings on self called execution.
go

ALTER PROCEDURE dbo.gl_PopulateRelatedAccounts (
	@piGrandAccount		Int, 
	@piAccount 		Int,
	@psRelatedAcctTable 	Nvarchar(128)
)
As
-- PROCEDURE :	gl_PopulateRelatedAccounts
-- VERSION :	1.0.0
-- DESCRIPTION:	The proc stores all  child accounts in 
--		a global temporary table supplied in @psRelatedAcctTable.
-- CALLED BY :	gl_TraverseAccount
-- DEPENDICES : gl_ListRelatedAccounts (recursive call)

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 2.5.03	MB	Created
-- 7.2.04	SFOO	Replaced CURSOR with selecting temporary table. SQA8851
--11.2.04	SFOO	Insert accounts into the global temporary table supplied. SQA9614
--			in @psRelatedAcctTable
Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	DECLARE @iAccount Int
	DECLARE @iRet Int
	DECLARE @iErrorCode int
	DECLARE @sSql Nvarchar(1000)

	Set @iRet = 0
	Set @iErrorCode = 0

	IF @iErrorCode = 0
	begin
		SELECT @iAccount=MIN(ACCOUNTID)
		FROM LEDGERACCOUNT 
		WHERE PARENTACCOUNTID = @piAccount
		Set @iErrorCode = @@ERROR
	end
	
	IF @iErrorCode = 0
	begin
		WHILE (@iAccount is not NULL AND @iErrorCode = 0)
		begin
			Set @sSql = 'INSERT INTO ' + @psRelatedAcctTable + 
				    ' (PARENTID, CHILDID) VALUES (@piGrandAccount, @iAccount)'
			Exec @iErrorCode=sp_executesql @sSql, 
						       N'@piGrandAccount Int,
							 @iAccount	  Int',
						       @piGrandAccount,
						       @iAccount

			If @iErrorCode = 0
			begin
				-- Indicate that at least one hierachy has been inserted.			
				Set @iRet = 1
			end
			
			-- Don't need to catch error code as the return value is not an Error Code.
			Exec gl_PopulateRelatedAccounts @piGrandAccount, @iAccount, @psRelatedAcctTable
		
			If @iErrorCode = 0
			begin
				Set @sSql = 'SELECT @iAccount=MIN(ACCOUNTID)
					     FROM LEDGERACCOUNT
					     WHERE PARENTACCOUNTID = @piAccount
					     AND ACCOUNTID > @iAccount'
				Exec @iErrorCode=sp_executesql @sSql,
							       N'@iAccount Int Output,
								 @piAccount Int',
							       @iAccount Output,
							       @piAccount
			end
		end
	end

	Return @iRet	-- Return 0 if there is no children OR error occurred.
			--        1 where there is at least 1 child.
End
go

grant execute on dbo.gl_PopulateRelatedAccounts to public
go

/*
To Test:

DROP TABLE ##RELATEDACCOUNT
CREATE TABLE ##RELATEDACCOUNT
(
 PARENTID int,
 CHILDID int
)
Exec dbo.gl_PopulateRelatedAccounts 3, 3, '##RELATEDACCOUNT'
SELECT * FROM ##RELATEDACCOUNT
*/
