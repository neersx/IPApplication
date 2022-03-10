-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xl_ListTranslationSource
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_ListTranslationSource]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_ListTranslationSource.'
	Drop procedure [dbo].[xl_ListTranslationSource]
End
Print '**** Creating Stored Procedure dbo.xl_ListTranslationSource...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.xl_ListTranslationSource
(
	@pnUserIdentityId	int,		-- Mandatory
	@pnTID			int,		-- Mandatory
	@pbCalledFromCentura	bit		-- Mandatory
)
as
-- PROCEDURE:	xl_ListTranslationSource
-- VERSION:	1
-- DESCRIPTION:	Populates the SourceText result set

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Sep 2004	TM	RFC1890	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

Declare @sTableName	nvarchar(30)
Declare @sShortColumn	nvarchar(30)
Declare @sLongColumn	nvarchar(30)
Declare @sTIDColumn	nvarchar(30)


-- Initialise variables
Set @nErrorCode = 0

-- Extract the table and columns names to be able to construct 
-- the required SQl to be executed:
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select @sTableName 	= TABLENAME,
		@sShortColumn	= SHORTCOLUMN,
		@sLongColumn	= LONGCOLUMN,
		@sTIDColumn	= TIDCOLUMN
	from TRANSLATIONSOURCE TS
	join TRANSLATEDITEMS TI	on (TI.TRANSLATIONSOURCEID = TS.TRANSLATIONSOURCEID)
	where TI.TID = @pnTID"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sTableName	nvarchar(30)	output,
					  @sShortColumn nvarchar(30)	output,
				          @sLongColumn	nvarchar(30)	output,
					  @sTIDColumn	nvarchar(30)	output,
					  @pnTID	int',
					  @sTableName	= @sTableName	output,
					  @sShortColumn	= @sShortColumn	output,
					  @sLongColumn	= @sLongColumn	output,
					  @sTIDColumn	= @sTIDColumn	output,
					  @pnTID	= @pnTID
End

-- Populating SourceText result set
If @nErrorCode = 0 
Begin
	Select
	@sSQLString = 
	"Select  @pnTID	as 'TID',"
	-- The source text should be returned as a long string:
	+CASE 	WHEN @sShortColumn is null 	THEN @sLongColumn
		WHEN @sLongColumn  is null 	THEN "CAST("+@sShortColumn+" as ntext)"
		WHEN(@sLongColumn  is not null 
		 and @sShortColumn is not null) THEN "ISNULL("+@sLongColumn+" , "+@sShortColumn+")"
	END+
	"		as 'SourceText'
	from "+@sTableName+char(10)+"
	where "+@sTIDColumn+" = @pnTID"		

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTID	int',
					  @pnTID	= @pnTID
End

Return @nErrorCode
GO

Grant execute on dbo.xl_ListTranslationSource to public
GO
