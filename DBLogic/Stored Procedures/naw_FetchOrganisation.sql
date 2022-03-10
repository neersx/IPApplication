-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchOrganisation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchOrganisation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchOrganisation.'
	Drop procedure [dbo].[naw_FetchOrganisation]
End
Print '**** Creating Stored Procedure dbo.naw_FetchOrganisation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchOrganisation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	naw_FetchOrganisation
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Organisation business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 10 Apr 2006	AU	RFC3505	1	Procedure created
-- 10 May 2010	PA	RFC9097	2	Remove the fetched column VATNO as the TAXNO column of NAME table will be used.
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

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
	Set @sSQLString =
	"Select " +
	"CAST(O.NAMENO 	as nvarchar(11))	as 'RowKey'," 		+char(10)+
	"O.NAMENO				as 'NameKey'," 		+char(10)+
	"O.REGISTRATIONNO			as 'RegistrationNo',"	+char(10)+
	dbo.fn_SqlTranslatedColumn('ORGANISATION','INCORPORATED',null,'O',@sLookupCulture,@pbCalledFromCentura)+
	"					as 'Incorporated',"	+char(10)+
	"O.PARENT				as 'ParentNameKey',"	+char(10)+
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)"		+char(10)+
	"					as 'ParentName',"	+char(10)+
	"N.NAMECODE				as 'ParentNameCode'"	+char(10)+
	"from ORGANISATION O"						+char(10)+
	"left join NAME N on (N.NAMENO = O.PARENT)"			+char(10)+
	"where O.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey	int',
			@pnNameKey	= @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchOrganisation to public
GO