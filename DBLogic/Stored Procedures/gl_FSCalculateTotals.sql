-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FSCalculateTotals.
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_FSCalculateTotals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_FSCalculateTotals'
	Drop procedure [dbo].[gl_FSCalculateTotals]
End
GO
Print '**** Creating Stored Procedure dbo.gl_FSCalculateTotals...'
Print ''

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_FSCalculateTotals  
(		 
	@pnUserIdentityId		int		= null,  
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnQueryId			int,		
	@psConsolidatedTable		nvarchar(50),
	@psListOfColumns		nvarchar(4000),
	@psListOfPersentageColumns 	nvarchar(4000)
)
AS

-- PROCEDURE:	gl_FSCalculateTotals
-- VERSION:	2
-- SCOPE:	Centura
-- DESCRIPTION:	Calculate the Totals liny type
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 31-Aug-2004  MB	9658	1	Procedure created
-- 22 May 2006	AT	12563	2	Change TABLECODES table to in-line select to avoid problem casting USERCODE.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nLineCount 	int
Declare @nMaxLineNo 	int
Declare @nTotalLineCount int
Declare @nErrorCode 	int
Declare @nLineIndex 	int
Declare @nTotalLineIndex int
Declare @sTotalLineSign char(1)
Declare @nSign 		int
Declare @nLineId 	int
Declare @nTotalLineId 	int
Declare @hDoc		int
Declare @nTotalColumnCount int
Declare @nColumnIndex	int
Declare @nDataItemId	int
Declare @nMaxIdentity	int
Declare @sSqlUpdate1 	nvarchar(4000)
Declare @sSqlUpdate2 	nvarchar(4000)
Declare @sSqlUpdate3 	nvarchar(4000)
Declare @sSql		nvarchar(4000)
Declare @sXml		nvarchar(4000)

Declare @tblTotalLine		table (	LineSequence 	int IDENTITY PRIMARY KEY,
					LineId 		int)

Declare @tblTotalLineDetails 	table (	LineDetailsSequence	int IDENTITY PRIMARY KEY,
			 		TotalLineId		int,
					TotalSign		char(1) collate database_default)

Declare @tblPercentageColumns 	table(	ID		int IDENTITY PRIMARY KEY,
			 		DataItemId	int not null)

-- The table is used to store calculated totals
Declare @tblCalculatedTotals 	table (	LINEID int)

Set @nErrorCode = 0


-- Check if the total does not consists a total line

If @nErrorCode = 0
Begin

	Insert into @tblTotalLine (LineId)
	select DISTINCT A.LINEID 
	from 	QUERYLINETOTAL A join QUERYLINE B
		on (A.LINEID = B.LINEID)
	where  
		B.QUERYID = @pnQueryId 
	and NOT EXISTS 
		( select  1 
		  from 
				QUERYLINETOTAL C join QUERYLINE D 	on (C.LINEID = D.LINEID) 
			join  	QUERYLINETOTAL F 			on (C.TOTALLINEID = F.LINEID )
	    	  where C.LINEID = A.LINEID and D.QUERYID = B.QUERYID
		)
		     
	Select @nLineCount = @@ROWCOUNT, @nErrorCode = @@Error

End

If @nLineCount > 0 and @nErrorCode = 0
Begin
	Exec @nErrorCode = gl_FSConstructUpdate  
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psConsolidatedTable	= @psConsolidatedTable, 
		@psListOfColumns	= @psListOfColumns,
		@psSqlUpdate1		 = @sSqlUpdate1 output,
		@psSqlUpdate2		 = @sSqlUpdate2 output,
		@psSqlUpdate3		 = @sSqlUpdate3 output


	-- insert into CALCULATED TOTLAS table
	If @nErrorCode= 0
	Begin

		Insert into @tblCalculatedTotals ( LINEID)
		select LineId from @tblTotalLine

		Set @nErrorCode = @@ERROR
	End
End

-- Loop over the simple totals

Set @nLineIndex = 1

While @nLineIndex <= @nLineCount
and @nErrorCode = 0
Begin

	Select	@nLineId = LineId
	from	@tblTotalLine 
	where	LineSequence = @nLineIndex

	Set @nErrorCode = @@ERROR

	If @nErrorCode = 0
	Begin
		Delete from @tblTotalLineDetails
		Set @nErrorCode = @@ERROR

		If @nErrorCode = 0
		Begin
		
			Insert into @tblTotalLineDetails (TotalLineId, TotalSign )
			select A.TOTALLINEID, A.TOTALSIGN 
			from 	QUERYLINETOTAL A
			where A.LINEID = @nLineId
		     
			Select 	@nTotalLineCount = @@ROWCOUNT, 
				@nErrorCode = @@ERROR,
				@nMaxIdentity = @@IDENTITY,
				@nTotalLineIndex = @@IDENTITY - @nTotalLineCount + 1


		End

		While @nTotalLineIndex <= @nMaxIdentity
		and @nErrorCode = 0
		Begin
			
			Select	@nTotalLineId =  TotalLineId, @sTotalLineSign = TotalSign
			from	@tblTotalLineDetails 
			where	LineDetailsSequence = @nTotalLineIndex

			Set @nErrorCode = @@ERROR


			If @sTotalLineSign = '' OR @sTotalLineSign is null OR @sTotalLineSign = '+'
				Set @nSign = 1
			Else
				Set @nSign = -1

			-- EXECUTE UPDATE STATEMENT HERE 
			If @nErrorCode = 0
				Exec @nErrorCode = sp_executesql @sSqlUpdate1,
					N'@nLineId int,
					@nTotalLineId int,
					@nSign int',
 	 				@nLineId = @nLineId,
					@nTotalLineId = @nTotalLineId,
					@nSign = @nSign

			If @sSqlUpdate2 <> '' and @nErrorCode = 0
				Exec @nErrorCode = sp_executesql @sSqlUpdate2,
						N'@nLineId int,
						@nTotalLineId int,
						@nSign int',
 	 					@nLineId = @nLineId,
						@nTotalLineId = @nTotalLineId,
						@nSign = @nSign

			If @sSqlUpdate3 <> '' and @nErrorCode = 0
				Exec @nErrorCode = sp_executesql @sSqlUpdate3,
						N'@nLineId int,
						@nTotalLineId int,
						@nSign int',
 	 					@nLineId = @nLineId,
						@nTotalLineId = @nTotalLineId,
						@nSign = @nSign

			Set @nTotalLineIndex = @nTotalLineIndex + 1
		End --End While
	End

	Set @nLineIndex = @nLineIndex + 1
End
	
-- Loop over the complex totals

While 1=1 and @nErrorCode = 0
Begin	
	Delete from @tblTotalLine
	Set @nErrorCode = @@ERROR
	If @nErrorCode = 0
	Begin
		Insert into @tblTotalLine (LineId)
		select  DISTINCT A.LINEID   
		from 
			QUERYLINETOTAL A join QUERYLINE B on (A.LINEID = B.LINEID) 
			left join @tblCalculatedTotals E on (A.TOTALLINEID = E.LINEID)
		where B.QUERYID = @pnQueryId 
		and exists 
		(select  1 from QUERYLINETOTAL C join QUERYLINE D
		on (C.LINEID = D.LINEID) join  QUERYLINETOTAL F 
		on (C.TOTALLINEID = F.LINEID )
		where C.LINEID = A.LINEID and D.QUERYID = B.QUERYID)
		and not exists 
		(select 1 from  @tblCalculatedTotals G where A.LINEID = G.LINEID)
		and A.LINEID not in
			(select AQ.LINEID 
			 from QUERYLINETOTAL AQ join QUERYLINE BQ on (AQ.LINEID = BQ.LINEID) 
			 where BQ.QUERYID = @pnQueryId  
			 and NOT exists (select 1 from @tblCalculatedTotals BT where 
					AQ.TOTALLINEID = BT.LINEID)
	 		 and AQ.TOTALLINEID not in (select  Q.LINEID 
						      from QUERYLINE Q join (SELECT TABLECODE, USERCODE FROM TABLECODES WHERE TABLETYPE = 100) as TC on (Q.LINETYPE = TC.TABLECODE)
						      where Q.QUERYID = @pnQueryId 
						      and cast (TC.USERCODE as int ) = 1
					     ) 
			  )

		Select 	@nLineCount = @@ROWCOUNT, 
			@nLineIndex = @@IDENTITY  - @nLineCount + 1,
			@nMaxLineNo = @@IDENTITY,
			@nErrorCode=@@ERROR
	
	End


	If @nLineCount = 0
		Break

	Insert into @tblCalculatedTotals ( LINEID)
	select LineId from @tblTotalLine

	Set @nErrorCode=@@ERROR

	While @nLineIndex <= @nMaxLineNo
	and @nErrorCode = 0
	Begin

		Select	@nLineId = LineId
		from	@tblTotalLine 
		where	LineSequence = @nLineIndex

		Set @nErrorCode=@@ERROR

		If @nErrorCode = 0
		Begin
			Delete from @tblTotalLineDetails

			Set @nErrorCode=@@ERROR

			If @nErrorCode = 0
			Begin
		
				Insert into @tblTotalLineDetails (TotalLineId, TotalSign )
				select A.TOTALLINEID, A.TOTALSIGN 
				from 	QUERYLINETOTAL A
				where A.LINEID = @nLineId

				Select 	@nTotalLineCount = @@ROWCOUNT,
					@nErrorCode	= @@ERROR,
					@nTotalLineIndex = @@IDENTITY - @nTotalLineCount + 1,
					@nMaxIdentity 	= @@IDENTITY
		     	End

			While @nTotalLineIndex <= @nMaxIdentity
			and @nErrorCode = 0
			Begin
			
				Select	@nTotalLineId =  TotalLineId, @sTotalLineSign = TotalSign
				from	@tblTotalLineDetails 
				where	LineDetailsSequence = @nTotalLineIndex

				Set @nErrorCode=@@ERROR

				If @sTotalLineSign = '' OR @sTotalLineSign is null OR @sTotalLineSign = '+'
					Set @nSign = 1
				Else
					Set @nSign = -1

				-- EXECUTE UPDATE STATEMENT HERE 
				If @nErrorCode = 0
					Exec @nErrorCode = sp_executesql @sSqlUpdate1,
						N'@nLineId int,
						@nTotalLineId int,
						@nSign int',
 	 					@nLineId = @nLineId,
						@nTotalLineId = @nTotalLineId,
						@nSign = @nSign

				If @sSqlUpdate2 <> '' and @nErrorCode = 0
					Exec @nErrorCode = sp_executesql @sSqlUpdate2,
							N'@nLineId int,
							@nTotalLineId int,
							@nSign int',
 	 						@nLineId = @nLineId,
							@nTotalLineId = @nTotalLineId,
							@nSign = @nSign
				If @sSqlUpdate3 <> '' and @nErrorCode = 0
					Exec @nErrorCode = sp_executesql @sSqlUpdate3,
							N'@nLineId int,
							@nTotalLineId int,
							@nSign int',
 	 						@nLineId = @nLineId,
							@nTotalLineId = @nTotalLineId,
							@nSign = @nSign

				Set @nTotalLineIndex = @nTotalLineIndex + 1

			End
		End
		Set @nLineIndex = @nLineIndex + 1
	End
End

-- Calculate Variance percentage column

If @psListOfPersentageColumns <> '' and @nErrorCode = 0
Begin

	-- Put columns into temporary table

	Set @nErrorCode = 0
	
	Set @sXml = dbo.fn_ListToXML( null, @psListOfPersentageColumns,  N',', 0 )
	
	Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @sXml
	
	If @nErrorCode = 0
	Begin
		Insert Into  @tblPercentageColumns (DataItemId) 
		      Select Value 
		      From OPENXML( @hDoc, '/ROOT/Worktable', 1 )
		      WITH  (   Value	nvarchar(50)	'@Value/text()')
		Set @nTotalColumnCount = @@ROWCOUNT
		Set @nErrorCode = @@Error
	End
	
	Exec sp_xml_removedocument @hDoc

	Set @nColumnIndex = 1
	While @nColumnIndex <= @nTotalColumnCount and @nErrorCode = 0
	Begin

		Select @nDataItemId = cast ( DataItemId as int ) from @tblPercentageColumns where ID = @nColumnIndex

		If @nDataItemId= 436 -- Variance%AccountMovementVsBudgetMovement
			Set @sSql = 'UPDATE ' + @psConsolidatedTable + ' SET VAR_PCT_ACCT_BUDG_MOVE = 
				CASE WHEN (BUDGETMOVEMENT IS NOT NULL and BUDGETMOVEMENT <>0) 
					THEN ((ISNULL (ACCOUNTMOVEMENT,0)  - BUDGETMOVEMENT)/BUDGETMOVEMENT)
					ELSE NULL
				END'
		If @nDataItemId= 437  -- Variance%AccountMovementVsForecastMovement
			Set @sSql = ' UPDATE ' + @psConsolidatedTable + ' SET VAR_PCT_ACCT_FORE_MOVE = 
				CASE WHEN (FORECASTMOVEMENT IS NOT NULL and FORECASTMOVEMENT <>0) 
					THEN (( ISNULL ( ACCOUNTMOVEMENT, 0 ) - FORECASTMOVEMENT )/FORECASTMOVEMENT) 
					ELSE NULL
				END' 
		If @nDataItemId= 438  -- Variance%AccountMovementYTDVsBudgetMovementYTD
			Set @sSql = ' UPDATE ' + @psConsolidatedTable + ' SET VAR_PCT_ACCT_YTD_BUDG_MOVE = 
				CASE WHEN (BUDGETMOVEMENTYTD IS NOT NULL and BUDGETMOVEMENTYTD <>0) 
					THEN ((ISNULL ( ACCOUNTMOVEMENTYTD,0)  - BUDGETMOVEMENTYTD )/BUDGETMOVEMENTYTD) 
					ELSE NULL
				END'
		If @nDataItemId= 439   -- Variance%AccountMovementYTDVsForecastMovementYTD
			Set @sSql = 'Update ' + @psConsolidatedTable + ' set 
				VAR_PCT_ACCT_YTD_FORE_MOVE = 
				CASE WHEN (FORECASTMOVEMENTYTD IS NOT NULL and FORECASTMOVEMENTYTD <>0) 
					THEN ((ISNULL( ACCOUNTMOVEMENTYTD,0) - FORECASTMOVEMENTYTD )/FORECASTMOVEMENTYTD) 
					ELSE NULL
				END'

		Exec @nErrorCode=sp_executesql @sSql

		Set @nColumnIndex = @nColumnIndex + 1

	End
End

Return @nErrorCode
GO

Grant execute on dbo.gl_FSCalculateTotals  to public
GO
