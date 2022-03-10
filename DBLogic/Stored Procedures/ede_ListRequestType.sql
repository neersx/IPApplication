-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ListRequestType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_ListRequestType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_ListRequestType.'
	Drop procedure [dbo].[ede_ListRequestType]
End
Print '**** Creating Stored Procedure dbo.ede_ListRequestType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ede_ListRequestType
(
	@pnRowCount				int		= null output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@psPickListSearch		nvarchar(30)	= null,
	@psRequestTypeCode		nvarchar(50)	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ede_ListRequestType
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List sender request types

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26APR2007	SF		RFC4710	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @pnRowCount	 = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	R.REQUESTTYPECODE		as 'RequestTypeCode',
			dbo.fn_GetTranslation(R.REQUESTTYPENAME,null,R.REQUESTTYPENAME_TID,@sLookupCulture) 
									as 'RequestTypeName',			
			R.REQUESTORNAMETYPE		as 'RequestorNameType',
			R.TRANSACTIONREASONNO	as 'TransactionReasonCode',
			dbo.fn_GetTranslation(TR.DESCRIPTION,null,TR.DESCRIPTION_TID,@sLookupCulture) 
									as 'TransactionReason'
	from 	EDEREQUESTTYPE R
	left join TRANSACTIONREASON TR on (TR.TRANSACTIONREASONNO = R.TRANSACTIONREASONNO)
	where	1 = 1
	"

	If @psPickListSearch is not null
	Begin
		set @sSQLString = @sSQLString+char(10)
			+ "		and upper("+dbo.fn_SqlTranslatedColumn('EDEREQUESTTYPE','REQUESTTYPENAME',null,'R',@sLookupCulture,@pbCalledFromCentura)+") like "+
			+ dbo.fn_WrapQuotes(UPPER(@psPickListSearch) + '%', 0, 0)
	End

	If @psRequestTypeCode is not null
	Begin
		Set @sSQLString = @sSQLString + char(10)
			+ "		and REQUESTTYPECODE = " + dbo.fn_WrapQuotes(@psRequestTypeCode, 0, 0)
	End
	
	Set @sSQLString = @sSQLString + char(10)
		+ "order by 'RequestTypeName'"	

	exec @nErrorCode = sp_executesql @sSQLString,
							N'@sLookupCulture	nvarchar(10),
							  @psPickListSearch	nvarchar(254)',
							  @sLookupCulture	= @sLookupCulture,
							  @psPickListSearch	= @psPickListSearch
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ede_ListRequestType to public
GO
