---------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListPriority 
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListPriority]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListPriority.'
	drop procedure [dbo].[ipw_ListPriority]
	Print '**** Creating Stored Procedure dbo.ipw_ListPriority...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListPriority
(
	@pnRowCount		int		= null  output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListPriority
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists File Request Priority

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 31 Mar 2011  MS	1	Procedure created
-- 02 Dec 2011  MS      2       Remove hardcoded table type

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(500)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0	


If @nErrorCode = 0
Begin
	Set @sSQLString = "Select 	T.TABLECODE 	as 'Key',"+char(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description' 
		from TABLECODES T
		join TABLETYPE TT on (T.TABLETYPE = TT.TABLETYPE)   
		where TT.TABLENAME = 'File Request Priority'
                order by 1 desc"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End	

Return @nErrorCode
GO

Grant exec on dbo.ipw_ListPriority to public
GO
