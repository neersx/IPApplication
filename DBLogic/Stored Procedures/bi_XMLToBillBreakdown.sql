-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_XMLToBillBreakdown
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_XMLToBillBreakdown]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_XMLToBillBreakdown.'
	Drop procedure [dbo].[bi_XMLToBillBreakdown]
End
Print '**** Creating Stored Procedure dbo.bi_XMLToBillBreakdown...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.bi_XMLToBillBreakdown
(
	@pnUserIdentityId	int		= null, 
	@psCulture		nvarchar(5) 	= null,
	@pbCalledFromCentura 	tinyint 	= 0,
	@pbDebugFlag	 	tinyint 	= 0,
	@psTempTableName	nvarchar(254),
	@psBillBreakdown	ntext
)
as
-- PROCEDURE:	bi_XMLToBillBreakdown
-- VERSION:	3
-- SCOPE:	Inprotech
-- DESCRIPTION:	Receives an XML Document, creates the globabl temporary table using the 
-- 		name specified in the @psTempTableName parameter and insert the values 
--		in the XML document into the temporary table.

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 08-Aug-2005  CR	11725	1	Procedure created
-- 21-Aug-2005	CR	11725	2	Split rows with both Renewal and Non-renewal Totals
-- 					Into separate rows.
-- 27-Nov-2006	MF	13919	3	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode 	int
	Declare @hDoc 		int
	Declare @sSql		nvarchar(1000)

	Set @nErrorCode = 0

	Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @psBillBreakdown
	

	If @nErrorCode = 0
	Begin
		Set @sSql = "CREATE TABLE " + @psTempTableName + " ( 
			DEBTORNO 	int		NOT NULL, 
			CASEID 		int		NULL, 
			PROPERTYTYPE 	nvarchar(1) 	collate database_default NULL, 
			PAYFORWIP 	nvarchar(1) 	collate database_default NULL, 
			RENEWALTOTAL 	decimal(11,2) 	NULL, 
			NONRENEWALTOTAL decimal(11,2) 	NULL )"
	
		exec @nErrorCode=sp_executesql @sSql
	
		If @pbDebugFlag = 1
			print @sSql
	end

	
	If @nErrorCode = 0
	Begin
		Set @sSql = 'Insert Into ' +  @psTempTableName +
			    ' Select * 
			      From OPENXML( @phDoc, ''/Filter//Row'', 2 )
			      With	(colnAcctDebtorNo int ''colnAcctDebtorNo/text()'',
					colnCaseId int ''colnCaseId/text()'',
					colsPropertyType nvarchar(1) ''colsPropertyType/text()'',
					colsPayForWIP nVarchar(1) ''colsPayForWIP/text()'',
					colnRenewalTotal decimal(11,2) ''colnRenewalTotal/text()'',
					colnNonrenewalTotal decimal(11,2) ''colnNonrenewalTotal/text()'')'


		Exec @nErrorCode = sp_executesql @sSql, N'@phDoc Int', @hDoc

		If @pbDebugFlag = 1
			print @sSql
	End
	
	Exec sp_xml_removedocument @hDoc


-- SPLIT OUT NONSPECIFIC ROWS FOR THE PURPOSE OF FILTERING.
	If @nErrorCode = 0
	Begin
		Set @sSql = "Insert Into " +  @psTempTableName +
			    " Select DEBTORNO, CASEID, PROPERTYTYPE, 'R', 
				RENEWALTOTAL, 0 
			      From " +  @psTempTableName +
			    " Where PAYFORWIP IS NULL OR PAYFORWIP = ''"


		Exec @nErrorCode = sp_executesql @sSql
				
		If @pbDebugFlag = 1
			print @sSql
	End


	If @nErrorCode = 0
	Begin
		Set @sSql = "Update " +  @psTempTableName +
			    " Set PAYFORWIP = 'N',
			     RENEWALTOTAL = 0
			     Where PAYFORWIP IS NULL OR PAYFORWIP = ''"


		Exec @nErrorCode = sp_executesql @sSql

		If @pbDebugFlag = 1
			print @sSql
	End


	Return @nErrorCode
End
GO

Grant execute on dbo.bi_XMLToBillBreakdown to public
GO