---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListMenu
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListMenu]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListMenu.'
	drop procedure [dbo].[p_ListMenu]
	Print '**** Creating Stored Procedure dbo.p_ListMenu...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.p_ListMenu
	@pnUserIdentityId	int = null,
	@psCulture		nvarchar(10) = null,
	@pbCalledFromCentura	bit = 0
	
AS
-- PROCEDURE :	p_ListMenu
-- VERSION :	10
-- DESCRIPTION:	A procedure to return the items for a menu hierarchy. A number of result sets are returned
--				indicating the various levels in the hierarchy according to the menuhierarchy dataset
-- Date			MODIFICATION HISTORY
-- ====         ====================
-- 11 Nov 2002	SF	4	Added href hyperlink as part of selection to headings.
-- 21 Feb 2003	JEK	7	RFC70 Implemented fn_TranslateText
-- 09 Sep 2004	JEK	8	RFC1695 Implement new version of translation.
-- 15 May 2005	JEK	RFC2508	9	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 15 Apr 2013	DV	R13270	10	Increase the length of nvarchar to 11 when casting or declaring integer


set nocount on
set concat_null_yields_null off

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise the errorcode and then set it after each SQL Statement
Set @nErrorCode   = 0

-- Get the top level i.e. groups
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select"+char(10)+
"		P.MENUID as menugroup_id"+char(10)+
"	from"+char(10)+
"		PORTALMENU P"+char(10)+
"	where"+char(10)+
"		HEADER = 1"+char(10)+
"		and"+char(10)+
"		PARENTID is null"+char(10)+
"		and"+char(10)+
"		(	(	@pnUserIdentityId is null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=1)"+char(10)+
"			or"+char(10)+
"			(	P.IDENTITYID = @pnUserIdentityId"+char(10)+
"				and	P.ANONYMOUSUSER=0)"+char(10)+
"			or"+char(10)+
"			(	@pnUserIdentityId is not null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=0"+char(10)+
"				and not exists (select * from PORTALMENU P1 "+char(10)+
"								where P1.IDENTITYID=@pnUserIdentityId "+char(10)+
"								and   P1.ANONYMOUSUSER=0))"+char(10)+
"		)"+char(10)+
"	order by SEQUENCE"+char(10)

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int',
				  @pnUserIdentityId	= @pnUserIdentityId
end

-- Get the next level i.e headings
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select"+char(10)+
"		MENUID as menugroup_id,"+char(10)+
"		"+dbo.fn_SqlTranslatedColumn('PORTALMENU','LABEL',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as label,"+char(10)+
"		HREF as href"+char(10)+
"	from"+char(10)+
"		PORTALMENU P"+char(10)+
"	where"+char(10)+
"		HEADER = 1"+char(10)+
"		and"+char(10)+
"		PARENTID is null"+char(10)+
"		and"+char(10)+
"		(	(	@pnUserIdentityId is null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=1)"+char(10)+
"			or"+char(10)+
"			(	P.IDENTITYID = @pnUserIdentityId"+char(10)+
"				and	P.ANONYMOUSUSER=0)"+char(10)+
"			or"+char(10)+
"			(	@pnUserIdentityId is not null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=0"+char(10)+
"				and not exists (select * from PORTALMENU P1"+char(10)+
"							where P1.IDENTITYID=@pnUserIdentityId"+char(10)+
"							and   P1.ANONYMOUSUSER=0))"+char(10)+
"		)"+char(10)+
"	order by [SEQUENCE]"+char(10)

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int',
				  @pnUserIdentityId	= @pnUserIdentityId
end

-- Get the next level i.e submenus. These will not have a grandparent. If a submenu has no 'children' then the handle
-- should be empty. This will ensure the submenu behaves as an 'item' underneath the group
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select"+char(10)+
"		P.PARENTID as menugroup_id,"+char(10)+
"		P.MENUID as submenu_Id,"+char(10)+
"		CASE"+char(10)+
"			WHEN (	select COUNT(C.MENUID)"+char(10)+
"					from	PORTALMENU C"+char(10)+
"					where	C.PARENTID = P.MENUID"+char(10)+
"					and		C.HEADER = 0) > 0"+char(10)+
"			THEN	cast(P.MENUID as nvarchar(11))"+char(10)+
"			ELSE	''"+char(10)+
"		END as handle,"+char(10)+
"		"+dbo.fn_SqlTranslatedColumn('PORTALMENU','LABEL',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as label,"+char(10)+
"		P.HREF as href"+char(10)+
"	from"+char(10)+
"		PORTALMENU P"+char(10)+
"	where"+char(10)+
"		P.HEADER = 0"+char(10)+
"		and"+char(10)+
"		P.PARENTID is not null"+char(10)+
"		and"+char(10)+
"		(select COUNT(MENUID)"+char(10)+
"					from	PORTALMENU G"+char(10)+
"					where	P.PARENTID = G.MENUID"+char(10)+
"					and		G.PARENTID is null)> 0"+char(10)+
"		and"+char(10)+
"		(	(	@pnUserIdentityId is null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=1)"+char(10)+
"			or"+char(10)+
"			(	P.IDENTITYID = @pnUserIdentityId"+char(10)+
"				and	P.ANONYMOUSUSER=0)"+char(10)+
"			or"+char(10)+
"			(	@pnUserIdentityId is not null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=0"+char(10)+
"				and not exists (select * from PORTALMENU P1 "+char(10)+
"							where P1.IDENTITYID=@pnUserIdentityId "+char(10)+
"							and   P1.ANONYMOUSUSER=0))"+char(10)+
"		)"+char(10)+
"	order by [SEQUENCE]"+char(10)

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int',
				  @pnUserIdentityId	= @pnUserIdentityId

end

-- Get the next level i.e items. These will have a grandparent
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select"+char(10)+
"		P.PARENTID as submenu_Id,"+char(10)+
"		"+dbo.fn_SqlTranslatedColumn('PORTALMENU','LABEL',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as label,"+char(10)+
"		isnull(P.HREF, '') as href"+char(10)+	-- ref must always contain a value
"	from"+char(10)+
"		PORTALMENU P"+char(10)+
"	where"+char(10)+
"		P.HEADER = 0"+char(10)+
"		and"+char(10)+
"		P.PARENTID is not null"+char(10)+
"		and"+char(10)+
"		(select COUNT(P2.MENUID)"+char(10)+
"					from	PORTALMENU P2"+char(10)+
"					where	P.PARENTID = P2.MENUID"+char(10)+
"					and		P2.HEADER = 0) > 0"+char(10)+
"		and"+char(10)+
"		(	(	@pnUserIdentityId is null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=1)"+char(10)+
"			or"+char(10)+
"			(	P.IDENTITYID = @pnUserIdentityId"+char(10)+
"				and	P.ANONYMOUSUSER=0)"+char(10)+
"			or"+char(10)+
"			(	@pnUserIdentityId is not null"+char(10)+
"				and	P.IDENTITYID is null"+char(10)+
"				and	P.ANONYMOUSUSER=0"+char(10)+
"				and not exists (select * from PORTALMENU P1 "+char(10)+
"							where P1.IDENTITYID=@pnUserIdentityId "+char(10)+
"							and   P1.ANONYMOUSUSER=0))"+char(10)+
"		)"+char(10)+
"	order by [SEQUENCE]"+char(10)

end

return @nErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.p_ListMenu to public
go
