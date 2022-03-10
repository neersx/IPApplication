-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListReasons
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListReasons]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListReasons.'
	Drop procedure [dbo].[acw_ListReasons]
	Print '**** Creating Stored Procedure dbo.acw_ListReasons...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListReasons
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnUsedByFlag		int		= null
)
AS
-- PROCEDURE:	acw_ListReasons
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available actions.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 26-Oct-2009	AT	RFC3605		1	Procedure created.
-- 03-May-2010	AT	RFC9092		2	Use translations.
-- 27-May-2010	AT	RFC9092		3	Return Reason if ISPROTECTED is null.
-- 23-Aug-2011	AT	RFC10881	4	Return ShowOnDebitNote for bill consolidation.
-- 08-Jul-2013	SF	DR-135		5	Fix bug - ISPROTECTED=0 OR ISPROTECTED IS NULL should be enclosed in brackets.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
		REASONCODE AS 'ReasonKey',
		" + dbo.fn_SqlTranslatedColumn('REASON','DESCRIPTION',null,null,@sLookupCulture,@pbCalledFromCentura) + " as 'ReasonDescription',
		USED_BY as 'UsedByFlag',
		SHOWONDEBITNOTE as 'ShowOnDebitNote'
		From REASON
		Where (ISPROTECTED=0 OR ISPROTECTED IS NULL)"

	if @pnUsedByFlag is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) + "and USED_BY & @pnUsedByFlag = @pnUsedByFlag"
	End
	
		Set @sSQLString = @sSQLString + char(10) + "order by 2"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnUsedByFlag	int',
		  @pnUsedByFlag=@pnUsedByFlag

End


Return @nErrorCode
GO

Grant execute on dbo.acw_ListReasons to public
GO
