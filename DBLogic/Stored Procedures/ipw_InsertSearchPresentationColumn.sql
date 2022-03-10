-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertSearchPresentationColumn
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertSearchPresentationColumn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertSearchPresentationColumn.'
	Drop procedure [dbo].[ipw_InsertSearchPresentationColumn]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertSearchPresentationColumn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_InsertSearchPresentationColumn
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@pnQueryContext				int,
	@psColumnLabel				nvarchar(50),	-- Mandatory
	@pnDataItemID				int = null,
	@psColumnDescription		nvarchar(254) = null,
	@pnGroupID					int = null,
	@psQualifier				nvarchar(20) = null,
	@pnDocItemID				int = null,
	@pbIsVisible				bit = 0,
	@pbIsBillCaseColumn             bit             = null
)
as
-- PROCEDURE:	ipw_InsertSearchPresentationColumn
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert or update Currency
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2010  	DV	RFC9437	1	Procedure created
-- 28 mar 2011 	 DV       RFC10041        2       Pass extra parameter @pbIsBillCaseColumn and use the variable to determine DataItemId
-- 26 Jul 2011  DV           RFC10857        3       Fix issue where the Column ID was being set incorrectly

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

Declare @nColumnID int

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If (@nErrorCode = 0 and @pnDataItemID is null and @pbIsBillCaseColumn = 1)
Begin
        Set @sSQLString = "Select @pnDataItemID = DATAITEMID from QUERYDATAITEM where
                                PROCEDUREITEMID = 'UserColumnString' and PROCEDURENAME = 'xml_GetDebitNoteMappedCodes'"
        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDataItemID				int OUTPUT',
					@pnDataItemID	 			= @pnDataItemID OUTPUT
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Insert into QUERYCOLUMN 
				(COLUMNLABEL, DATAITEMID, DESCRIPTION, DOCITEMID, QUALIFIER)
			values 
				(@psColumnLabel,@pnDataItemID,@psColumnDescription, @pnDocItemID, @psQualifier)"
					
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nColumnID				int,
					  @psColumnLabel			nvarchar(50),	
					  @pnDataItemID				int,
					  @psColumnDescription		nvarchar(254),
					  @psQualifier				nvarchar(20),
					  @pnDocItemID				int',					
					  @nColumnID	 			= @nColumnID,
					  @psColumnLabel	 		= @psColumnLabel,
					  @pnDataItemID				= @pnDataItemID,
					  @psColumnDescription	 	= @psColumnDescription,
					  @psQualifier	 			= @psQualifier,
					  @pnDocItemID	 			= @pnDocItemID
	
	Set @nColumnID = IDENT_CURRENT('QUERYCOLUMN')
	
	if(@nErrorCode =0 and (@pbIsVisible = 1 or @pnGroupID is not null or @pbIsBillCaseColumn = 1))
	Begin
		Set @sSQLString = "
					INSERT into QUERYCONTEXTCOLUMN (CONTEXTID, COLUMNID, GROUPID, ISMANDATORY, ISSORTONLY)
					values (@pnQueryContext,@nColumnID, @pnGroupID,0,0)"
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnQueryContext		int,
						@nColumnID				int, 
						@pnGroupID				int',					
						@pnQueryContext	 		= @pnQueryContext,
						@nColumnID	 			= @nColumnID,
						@pnGroupID	 			= @pnGroupID
	End	
End

if (@nErrorCode = 0)
Begin
	Select @nColumnID as 'ColumnID',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from QUERYCOLUMN 
	WHERE COLUMNID = @nColumnID
End

Return @nErrorCode
go

Grant exec on dbo.ipw_InsertSearchPresentationColumn to Public
go