-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ArrangeAccountTree
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_ArrangeAccountTree]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.gl_ArrangeAccountTree.'
	drop procedure dbo.gl_ArrangeAccountTree
	print '**** Creating procedure dbo.gl_ArrangeAccountTree...'
	print ''
end
go

CREATE PROCEDURE dbo.gl_ArrangeAccountTree
(
	@psRelAcctTableName nvarchar(128) output
)
AS
-- PROCEDURE :	gl_ArrangeAccountTree
-- VERSION :	1.0
-- DESCRIPTION:	·	The stored procedure flattens the account tree. 
--					It uses the  ##TEMPACCOUNTS table to find out the list of all 
--					required “child” account and the globl RELATEDACCOUNT table 
--					as an outcome table. The ##TEMPACCOUNTS table must be created 
--					prior calling the stored procedure
-- SCOPE:	General Ledger
-- CALLED BY :	gl_ListProfitAndLossDetails, gl_ListBalanceSheetDetails
-- DEPENDENCIES: gl_GetParentAccountAndLevel 

-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  	Change
-- ------------ ----	---- 	-------- 	------------------------------------------- 
-- 8 May 2003	MB	8202	1.0		Created
-- 1 Mar 2004	SFOO	9614	1.5		Replaced Cursor with Select, generated the unique global
--						temporary table in @psRelAcctTableName return it as
--						output variable so the calling SP can use it.				
Begin
	DECLARE @iAccount 	Int
	DECLARE @iParentAccount Int
	DECLARE @iParentLevel 	Int
	DECLARE @iLevel1 	Int
	DECLARE @iLevel2 	Int
	DECLARE @iLevel3 	Int
	DECLARE @iLevel4 	Int
	DECLARE @iLevel5 	Int
	DECLARE @iRet 		Int
	DECLARE @iTempAccountId Int
	DECLARE @sSql 		Nvarchar(1000)
	DECLARE	@ErrorCode	Int
	
	Set @ErrorCode=0

	-- Generate an unique global temporary table specific to db process of the user.
	Set @psRelAcctTableName = '##RELATEDACCOUNT' + CONVERT(nvarchar(7), @@SPID)

	Set @sSql = 'CREATE TABLE ' + @psRelAcctTableName + ' (
			CHILDID int, 
			LEVEL1 int,
			LEVEL2 int,
			LEVEL3 int, 
			LEVEL4 int, 
			LEVEL5 int )'
	Exec @ErrorCode=sp_executesql @sSql

	If @ErrorCode = 0
	begin
		Select @iAccount = MIN(DISTINCT ACCOUNTID)
		from #TEMPACCOUNTS
		Set @ErrorCode = @@ERROR
	end

	WHILE (@ErrorCode = 0) AND (@iAccount is not NULL)
	begin
		Set @iLevel1 = NULL
		Set @iLevel2 = NULL
		Set @iLevel3 = NULL
		Set @iLevel4 = NULL
		Set @iLevel5 = NULL

		Set @iRet = 1	
		Set @iTempAccountId = @iAccount
		While @iRet = 1 AND @ErrorCode =0
		begin
			exec @iRet = gl_GetParentAccountAndLevel @iTempAccountId, 0, @iParentAccount OUTPUT, @iParentLevel OUTPUT

			If @iParentLevel = 1 
				Set @iLevel1 = @iTempAccountId
			If @iParentLevel = 2 
				Set @iLevel2 = @iTempAccountId
			If @iParentLevel = 3 
				Set @iLevel3 = @iTempAccountId
			If @iParentLevel = 4 
				Set @iLevel4 = @iTempAccountId
			If @iParentLevel = 5 
				Set @iLevel5 = @iTempAccountId

			Set @iTempAccountId = @iParentAccount
		end

		Set @sSql = 'INSERT INTO ' + @psRelAcctTableName + ' (CHILDID, LEVEL1, LEVEL2, LEVEL3, LEVEL4, LEVEL5)
				VALUES (@iAccount, @iLevel1, @iLevel2, @iLevel3, @iLevel4, @iLevel5)'
		Exec @ErrorCode=sp_executesql @sSql,
						N'@iAccount int,
						  @iLevel1 int,
						  @iLevel2 int,
						  @iLevel3 int,
						  @iLevel4 int,
						  @iLevel5 int',
						@iAccount,
						@iLevel1,
						@iLevel2,
						@iLevel3,
						@iLevel4,
						@iLevel5

		If @ErrorCode = 0
		begin
			Set @sSql = 'Select @iAccount = MIN(DISTINCT ACCOUNTID)
					from #TEMPACCOUNTS
					where ACCOUNTID > @iAccount'
			Exec @ErrorCode=sp_executesql @sSql,
							N'@iAccount int output',
							@iAccount output
		end
	end
 
	return @ErrorCode
End
go

grant execute on dbo.gl_ArrangeAccountTree to public
go

/*
To test
Insert Into #TEMPACCOUNTS
Select LEDGERACCOUNT.ACCOUNTID
from LEDGERACCOUNT
where ACCOUNTTYPE in (8104, 8105)
and ACCOUNTID not in (Select PARENTACCOUNTID 
			from LEDGERACCOUNT 
			where PARENTACCOUNTID is not null) 
Select b.*
from #TEMPACCOUNTS a 
	inner join 
     LEDGERACCOUNT b on (b.ACCOUNTID = a.ACCOUNTID)
Declare @sRelAcctTableName nvarchar(128)
Exec dbo.gl_ArrangeAccountTree @sRelAcctTableName output
Declare @sSql nvarchar(1000)
Set @sSql = 'Select * from ' + @sRelAcctTableName
Exec sp_executesql @sSql
Drop table #TEMPACCOUNTS
Set @sSql = 'Drop table ' + @sRelAcctTableName
Exec sp_executesql @sSql
*/
