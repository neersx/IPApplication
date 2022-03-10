-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListAttributeTypeData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListAttributeTypeData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListAttributeTypeData.'
	Drop procedure [dbo].[ipw_ListAttributeTypeData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListAttributeTypeData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE [dbo].[ipw_ListAttributeTypeData]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psParentTable	nvarchar(100),   -- Mandatory
    @pnTableType int                -- Mandatory	
)
as
-- PROCEDURE:	ipw_ListAttributeTypeData
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get the Attribute Type for the PARENTTABLE and TABLETYPE combination.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2009	DV	RFC8016	1	Procedure created 
-- 04 Feb 2010	DL	18430	2	Grant stored procedure to public
-- 01 Dec 2014	DV	R25316	3	Return MODIFYBYSERVICE 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0 
Begin
	Set @sSQLString = "Select
	Cast(ST.PARENTTABLE as nvarchar(40))+ '^'+ Cast(ST.TABLETYPE as nvarchar(10)) as RowKey,
	Cast(ST.PARENTTABLE as nvarchar(40))+ '^'+ Cast(ST.TABLETYPE as nvarchar(10)) as AttributeKey,
	ST.PARENTTABLE		as ParentTable,"+char(10)+
	dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"			as TableName,
	ST.TABLETYPE as TableType,
	ST.MINIMUMALLOWED as MinimumAllowed,
	ST.MAXIMUMALLOWED as MaximumAllowed,
	ST.MODIFYBYSERVICE as ModifyByService
	from SELECTIONTYPES ST
	join TABLETYPE TT on (TT.TABLETYPE = ST.TABLETYPE)
	where ST.PARENTTABLE = @psParentTable
	and ST.TABLETYPE = @pnTableType"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@psParentTable	nvarchar(100),
			@pnTableType int',
			@psParentTable	= @psParentTable,
			@pnTableType    = @pnTableType
End

Return @nErrorCode
GO

grant execute on dbo.ipw_ListAttributeTypeData to public
GO




