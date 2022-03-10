-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xl_ListTranslationData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xl_ListTranslationData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xl_ListTranslationData.'
	Drop procedure [dbo].[xl_ListTranslationData]
End
Print '**** Creating Stored Procedure dbo.xl_ListTranslationData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.xl_ListTranslationData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@pnTID			int,		-- Mandatory
	@psForCulture 		nvarchar(10)	= null, 	-- filters the results
	@pbCalledFromCentura	bit		-- Mandatory
)
as
-- PROCEDURE:	xl_ListTranslationData
-- VERSION:	7
-- DESCRIPTION:	Populates the TranslationData dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Sep 2004	TM	RFC1695	1	Procedure created
-- 14 Sep 2004	TM	RFC1695	2	Correct the source column logic (it can contain both long and short data).
-- 14 Sep 2004	TM	RFC1695	3	Remove the 'CAST' from the code:
--					"ISNULL("+@sLongColumn+" ,CAST("+@sShortColumn+" as ntext))" as the ISNULL 
--					and COALESCE take the type of the output as the type of the first parameter.
-- 22 Sep 2004	JEK	RFC1695	4	Implement db_name()
-- 24 Sep 2004	TM	RFC1695	5	Add new LanguageDescription column.
-- 24 Sep 2004	TM	RFC1695	6	Make join to TableCodes an upper() on the UserCode. Use full joins for both 
--					Culture and TableCodes.
-- 24 Sep 2004	TM	RFC1860	7	Provide separate stored procedures to populate TranslationData.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Extract the table and columns names to be able to construct 
-- the required SQl to be executed:
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.xl_ListTranslationSource
		@pnUserIdentityId	= @pnUserIdentityId,
		@pnTID			= @pnTID,
		@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Populating SourceText result set
If @nErrorCode = 0 
Begin
	exec @nErrorCode = dbo.xl_ListTIDTranslation
		@pnRowCount		= @pnRowCount OUTPUT,
		@pnUserIdentityId	= @pnUserIdentityId,
		@pnTID			= @pnTID,
		@psForCulture		= @psForCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura
End

Return @nErrorCode
GO

Grant execute on dbo.xl_ListTranslationData to public
GO
