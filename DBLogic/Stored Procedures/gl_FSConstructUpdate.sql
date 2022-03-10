-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FSConstructUpdate.
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_FSConstructUpdate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_FSConstructUpdate'
	Drop procedure [dbo].[gl_FSConstructUpdate]
	Print '**** Creating Stored Procedure dbo.gl_FSConstructUpdate...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_FSConstructUpdate  
(		 
	@pnUserIdentityId	int		= null, -- RFC463. @pnUserIdentityId must accept null (when called from InPro)
	@psCulture		nvarchar(5)	= null, -- the language in which output is to be expressed
	@psConsolidatedTable	nvarchar(50),
	@psListOfColumns	nvarchar(4000),
	@psSqlUpdate1		nvarchar(4000) output,
	@psSqlUpdate2		nvarchar(4000) output,
	@psSqlUpdate3		nvarchar(4000) output

)
AS

-- PROCEDURE:	gl_FSConstructUpdate
-- VERSION:	1
-- SCOPE:	Centura
-- DESCRIPTION:	Consruct the Update statement to update the Totals line
--			
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 31-Aug-2004  MB	9658	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nMaxNumberColumns 	int
Declare @nErrorCode 		int
Declare @nTotalColumnCount 	int
Declare @nColumnIndex 		int
Declare @hDoc			int
Declare @sColumnName 		nvarchar (50)
Declare @sSqlTemp 		nvarchar(4000)
Declare @sXml			nvarchar(4000)


Declare @tblSelectedColumns table(	ColumnID	int IDENTITY PRIMARY KEY,
			 		ColumnName	varchar(50) collate database_default)

Set @nErrorCode = 0
Set @psSqlUpdate1 = ''
Set @psSqlUpdate2 = ''
Set @psSqlUpdate3 = ''

If   @nErrorCode = 0
Begin

	-- Put columns into temporary table

	Set @nErrorCode = 0
	
	Set @sXml = dbo.fn_ListToXML( null, @psListOfColumns,  N',', 0 )
	
	Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @sXml
	
	If @nErrorCode = 0
	Begin
		Insert Into  @tblSelectedColumns (ColumnName) 
		      Select Value 
		      From OPENXML( @hDoc, '/ROOT/Worktable', 1 )
		      WITH  (   Value	nvarchar(50)	'@Value/text()')
		Set @nTotalColumnCount = @@ROWCOUNT
		Set @nErrorCode = @@Error

	End
	
	Exec sp_xml_removedocument @hDoc
End

Set  @nMaxNumberColumns = 20

Set @nColumnIndex = 1
-- CONSTRUCT UPDATE STATEMENT
Set @sSqlTemp = ''
While @nColumnIndex <= @nTotalColumnCount and @nColumnIndex <= @nMaxNumberColumns
and @nErrorCode = 0
Begin

	Select @sColumnName = ColumnName from @tblSelectedColumns where ColumnID = @nColumnIndex

	if @sSqlTemp = ''
		Set @sSqlTemp =  @sColumnName + ' =  ISNULL ( ' +@sColumnName + ',0)   + (@nSign)*
		 (select ISNULL(A.' + @sColumnName + ',0) from ' + @psConsolidatedTable + ' A where A.LINEID = @nTotalLineId )'
	else
		Set @sSqlTemp = @sSqlTemp + ', '  + @sColumnName + ' =  ISNULL ( ' +@sColumnName + ',0)   + (@nSign)*
		 (select ISNULL(A.' + @sColumnName + ',0) from ' + @psConsolidatedTable + ' A where A.LINEID = @nTotalLineId )'

	Set @nColumnIndex = @nColumnIndex + 1

End

if @sSqlTemp <> ''
	Set @psSqlUpdate1 = 'update ' + @psConsolidatedTable + ' set '  + @sSqlTemp + 
	' where LINEID = @nLineId '

Set @sSqlTemp = ''
While @nColumnIndex <= @nTotalColumnCount and @nColumnIndex <= 2*@nMaxNumberColumns
and @nErrorCode = 0
Begin

	Select @sColumnName = ColumnName from @tblSelectedColumns where ColumnID = @nColumnIndex

	If @sSqlTemp = ''
		Set @sSqlTemp =  @sColumnName + ' =  ISNULL ( ' +@sColumnName + ',0)   + (@nSign)*
		 (select ISNULL(A.' + @sColumnName + ',0) from ' + @psConsolidatedTable + ' A where A.LINEID = @nTotalLineId )'
	Else
		Set @sSqlTemp = @sSqlTemp + ', '  + @sColumnName + ' =  ISNULL ( ' +@sColumnName + ',0)   + (@nSign)*
		 (select ISNULL(A.' + @sColumnName + ',0) from ' + @psConsolidatedTable + ' A where A.LINEID = @nTotalLineId )'

	Set @nColumnIndex = @nColumnIndex + 1

End

if @sSqlTemp <> ''
	Set @psSqlUpdate2 = 'UPDATE ' + @psConsolidatedTable + ' set '  + @sSqlTemp + 
	' where LINEID = @nLineId '

Set @sSqlTemp = ''
While @nColumnIndex <= @nTotalColumnCount and @nColumnIndex <= 3*@nMaxNumberColumns
and @nErrorCode = 0
Begin

	Select @sColumnName = ColumnName from @tblSelectedColumns where ColumnID = @nColumnIndex

	If @sSqlTemp = ''
		Set @sSqlTemp =  @sColumnName + ' =  ISNULL ( ' +@sColumnName + ',0)   + (@nSign)*
		 (select ISNULL(A.' + @sColumnName + ',0) from ' + @psConsolidatedTable + ' A where A.LINEID = @nTotalLineId )'
	Else
		Set @sSqlTemp = @sSqlTemp + ', '  + @sColumnName + ' =  ISNULL ( ' +@sColumnName + ',0)   + (@nSign)*
		 (select ISNULL(A.' + @sColumnName + ',0) from ' + @psConsolidatedTable + ' A where A.LINEID = @nTotalLineId )'

	Set @nColumnIndex = @nColumnIndex + 1

End
if @sSqlTemp <> ''
	Set @psSqlUpdate3 = 'Update ' + @psConsolidatedTable + ' set '  + @sSqlTemp + 
	' where LINEID = @nLineId '

Return @nErrorCode
GO

Grant execute on dbo.gl_FSConstructUpdate  to public
GO
