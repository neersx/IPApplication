-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListClientNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListClientNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListClientNames.'
	Drop procedure [dbo].[naw_ListClientNames]
End
Print '**** Creating Stored Procedure dbo.naw_ListClientNames...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListClientNames
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListClientNames
-- VERSION:	7
-- DESCRIPTION:	List all the names a staff member is responsible for

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2003	JEK	RFC621	1	Procedure created
-- 10 Mar 2004	TM	RFC868	2	Modify the logic extracting the 'Email' column to use new Name.MainEmail column. 
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
-- 29 Oct 2004	TM	RFC1158	4	Add new RowKey column.
-- 15 May 2005	JEK	RFC2508	5	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 11 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	7	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0


If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select 
	CAST(AN.NAMENO as varchar(11))+'^'+
	AN.RELATIONSHIP+'^'+
	CAST(AN.RELATEDNAME as varchar(11))+'^'+
	CAST(AN.SEQUENCE as varchar(5))
				as 'RowKey',
	AN.RELATEDNAME		as 'NameKey',
	AN.NAMENO		as 'AssociatedNameKey',
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
				as 'AssociatedName',
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Role',
	"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyType',
	C.NAMENO		as 'MainContactKey',
	dbo.fn_FormatNameUsingNameNo(C.NAMENO, null) 
				as 'MainContactName',
	dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION)
				as 'Phone',
	dbo.fn_FormatTelecom(F.TELECOMTYPE, F.ISD, F.AREACODE, F.TELECOMNUMBER, F.EXTENSION)
				as 'Fax',
	dbo.fn_FormatTelecom(M.TELECOMTYPE, M.ISD, M.AREACODE, M.TELECOMNUMBER, M.EXTENSION) 
				as 'Email'
	from ASSOCIATEDNAME AN
	join NAME N			on (N.NAMENO = AN.NAMENO)
	left join PROPERTYTYPE P 	on (P.PROPERTYTYPE = AN.PROPERTYTYPE)
	left join TABLECODES R		on (R.TABLECODE = AN.JOBROLE)
	left join NAME C 		on (C.NAMENO=N.MAINCONTACT)
	left join TELECOMMUNICATION T 	on (T.TELECODE= isnull(C.MAINPHONE, N.MAINPHONE) )
	left join TELECOMMUNICATION F	on (F.TELECODE= isnull(C.FAX, N.FAX) )
	left join TELECOMMUNICATION M	on (M.TELECODE= isnull(C.MAINEMAIL, N.MAINEMAIL) )	
	where 	AN.RELATEDNAME = @pnNameKey
	and	AN.RELATIONSHIP = 'RES'
	and    (AN.CEASEDDATE is null or AN.CEASEDDATE>getdate())
	order by AssociatedName, AssociatedNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
	Set @pnRowCount = @@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListClientNames to public
GO
