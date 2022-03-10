-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListMultipleNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[naw_ListMultipleNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.naw_ListMultipleNames.'
	drop procedure dbo.naw_ListMultipleNames
	print '**** Creating procedure dbo.naw_ListMultipleNames...'
	print ''
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_ListMultipleNames
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psNameKeys			nvarchar(4000)

)		
-- PROCEDURE :	naw_ListMultipleNames
-- VERSION :	2
-- DESCRIPTION:	Given a list of comma delimited nameKeys, return matching names as a result set.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 29 Mar 2006	SW	RFC3220	1	Initial creation.
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString nvarchar(4000)

Set @nErrorCode = 0

Set @sSQLString='
Select	N.NAMENO 					as NameKey,
	N.NAMECODE 					as NameCode,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)	as DisplayName
from	[NAME] N
where	N.[NAMENO] in ('

Exec  (@sSQLString + @psNameKeys + ')')
select	@nErrorCode =@@Error

RETURN @nErrorCode
GO

Grant execute on dbo.naw_ListMultipleNames  to public
GO



