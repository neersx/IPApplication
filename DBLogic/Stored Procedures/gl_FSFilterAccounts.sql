-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FSFilterAccounts
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[gl_FSFilterAccounts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.gl_FSFilterAccounts.' 
	drop procedure dbo.gl_FSFilterAccounts
	print '**** Creating procedure dbo.gl_FSFilterAccounts...'
	print ''
End
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.gl_FSFilterAccounts
(
	@pnLineId			int,			-- Line Id in XML document
	@psTempTableName		nvarchar(50),	 	-- is the name of the the global temporary table that will hold the filtered list of transactions.
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@psEntityTableName		varchar(30),		-- the name of the temp table to hold Entity part of the filter
	@psProfitCentreTableName	varchar(30),		-- the name of the temp table to hold Profit Centre Code part of the filter
	@psLedgerAccountTableName	varchar(30),		-- the name of the temp table to hold ledger Account part of the filter
	@psFilterCriteriaTableName 	varchar(30)		-- the name of the temp table to hold Filter Criteria part of the filter
)		

-- PROCEDURE:	gl_FSFilterAccounts
-- VERSION:	2
-- SCOPE:	Centura
-- DESCRIPTION:	gl_FSFilterAccounts is responsible for the management of the multiple occurrences of the filter criteria 
--		and the production of an appropriate result set. It calls gl_FSConstructWhere to obtain the where 
--		clause for each separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the 
--		name of the the global temporary table that may hold the filtered list of cases.

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 31-Aug-2004  MB	9658	1	Procedure created
-- 23-May-2005  MB	11278	2	Performance improvement

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @nFilterGroupCount	tinyint		-- The number of FilterCriterisGroupe contained in the @ptXMLFilterCriteria parameter 
Declare @nFilterGroupIndex	tinyint		-- The FilterCriteriaGroup node number.		
Declare @sBuildOperator		nvarchar(3)	-- may contain any of the values "and", "OR", "NOT"
Declare @sSql			nvarchar(4000)  
Declare	@sAccountFilter		nvarchar(4000)	-- the FROM and WHERE for the Case Filter
Declare @sFilterId		nvarchar(40)

Set @nErrorCode	= 0


If @nErrorCode = 0
Begin
	Set @sSql = 'Select @sFilterId=MIN(FILTERID)
		     from ' + @psFilterCriteriaTableName + ' where LINEID = @pnLineId ' 
	Exec @nErrorCode=sp_executesql @sSql, 
			N'@sFilterId 	nvarchar(40) Output,
			@pnLineId	int', 
			@sFilterId Output,
			@pnLineId = @pnLineId
End


While (@sFilterId is not null and @nErrorCode = 0)
Begin
		
	Set 	@sSql = 'Select	@sBuildOperator	   = BOOLEANOPERATOR
			from	' + @psFilterCriteriaTableName + '
			where LINEID = @pnLineId and FILTERID = @sFilterId'
		
	Exec @nErrorCode=sp_executesql @sSql, 
			N'@sFilterId 	nvarchar(40) ,
			@pnLineId	int,
			@sBuildOperator nvarchar(3) Output', 
			@sFilterId 	= @sFilterId,
			@pnLineId 	= @pnLineId,
			@sBuildOperator = @sBuildOperator Output
				
	
	If @nErrorCode=0
	Begin
		Exec @nErrorCode = dbo.gl_FSConstructWhere
			@pnLineId			= @pnLineId,
			@psFilterId			= @sFilterId,
		   	@psReturnClause			= @sAccountFilter	output,
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@psEntityTableName 		= @psEntityTableName,
			@psProfitCentreTableName	= @psProfitCentreTableName,
			@psLedgerAccountTableName 	= @psLedgerAccountTableName
				
	End

	If @nErrorCode=0
	Begin
		If ( @sBuildOperator is null or upper(@sBuildOperator)='OR' )
		Begin   
			-- the statements above will prepare the temptable needed for this query	
			Set @sSql = '
				Insert into ' + @psTempTableName + '(
					ENTITYNO ,
					PROFITCENTRECODE,
					ACCOUNTID  ) 
					(select 	
						A.NAMENO,
						B.PROFITCENTRECODE,
						C.ACCOUNTID 
				from SPECIALNAME A, PROFITCENTRE B, LEDGERACCOUNT C
				where 	A.ENTITYFLAG = 1 
				and 	A.NAMENO = B.ENTITYNO 
				and 	' + @sAccountFilter + ' )'

				Exec @nErrorCode = sp_executesql @sSql

		End
		Else
		Begin
			If upper(@sBuildOperator)='AND'
			Begin
				-- delete from temporary table the row not matching with the current step
				-- previous queries also match with the current query
				Set @sSql  = 'Delete from ' + @psTempTableName + 
							' from ' + @psTempTableName + ' TMP ' +  
							' join SPECIALNAME A on (A.NAMENO=TMP.ENTITYNO ) ' +  
							' join PROFITCENTRE B on (B.PROFITCENTRECODE = TMP.PROFITCENTRECODE ) ' +  
							' join LEDGERACCOUNT C on (C.ACCOUNTID = TMP.ACCOUNTID ) '+  
							' where ' +  
							' NOT ( ' + @sAccountFilter + ')'

				Exec @nErrorCode = sp_executesql @sSql 

			End
			Else if upper(@sBuildOperator)='NOT'
			Begin
				-- delete from temporary table where rows are matching with current steps
				Set @sSql  ='Delete from ' + @psTempTableName + 
							' from ' + @psTempTableName + ' TMP ' +  
							' join SPECIALNAME A on (A.NAMENO=TMP.ENTITYNO ) ' +  
							' join PROFITCENTRE B on (B.PROFITCENTRECODE = TMP.PROFITCENTRECODE ) ' +  
							' join LEDGERACCOUNT C on (C.ACCOUNTID = TMP.ACCOUNTID ) '+  
							' where ' +  
							' ( ' + @sAccountFilter + ')'

				Exec @nErrorCode = sp_executesql @sSql 
			End
		End		
	End
	
	
	If @nErrorCode = 0
	Begin
		Set @sSql = 'SELECT @sFilterId=MIN(FILTERID)
			     FROM ' + @psFilterCriteriaTableName + ' where LINEID = @pnLineId 
				and FILTERID > @sFilterId' 
		Exec @nErrorCode=sp_executesql @sSql, 
				N'@sFilterId nvarchar(40) Output,
				@pnLineId		int', 
				@sFilterId Output,
				@pnLineId = @pnLineId
	End
	
End -- End of the "While" loop


Return @nErrorCode
go

Grant execute on dbo.gl_FSFilterAccounts  to public
go



