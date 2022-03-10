-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListTableTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListTableTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListTableTypes.'
	Drop procedure [dbo].[ipw_ListTableTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListTableTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListTableTypes
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbModifiable bit			= 0,
	@pbCalledFromCentura bit	= 0,
	@psDatabaseTables	nvarchar(1000) = null
)
as
-- PROCEDURE:	ipw_ListTableTypes
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns all table types available for maintenance in the .Net module.
--				If @psDatabaseTables is not specified, all TABLETYPE where MODIFIABLE is returned
--				If @psDatabaseTables is specified (comma separated list of TABLETYPE.DATABASETABLE), then it is further filtered by the DATABASETABLEs.

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 OCT 2008	SF	RFC6510	1	Procedure created
-- 22 AUG 2009	DV	RFC8016	2	Added one more parameter @pbModifiable which decides whether all TableTypes 
--								need to be returned or not

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	TT.TABLETYPE		as TableTypeKey,"+
			dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)+ 
			"		as TableName,
			TT.DATABASETABLE			as DatabaseTable
		from TABLETYPE TT
		where 1 = 1
		" + CASE WHEN @pbModifiable = 0 THEN "and TT.MODIFIABLE = 1"
			END 
		 + CASE WHEN @psDatabaseTables is not null THEN "and DATABASETABLE" +
				dbo.fn_ConstructOperator(0,'S',@psDatabaseTables, null,@pbCalledFromCentura) 
			END + "
		order by TableName"

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListTableTypes to public
GO
