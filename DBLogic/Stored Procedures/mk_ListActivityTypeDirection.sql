---------------------------------------------------------------------------------------------
-- Creation of dbo.mk_ListActivityTypeDirection
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_ListActivityTypeDirection]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_ListActivityTypeDirection.'
	drop procedure [dbo].[mk_ListActivityTypeDirection]
	Print '**** Creating Stored Procedure dbo.mk_ListActivityTypeDirection...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.mk_ListActivityTypeDirection
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	mk_ListActivityTypeDirection
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Activity Types.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10 Feb 2005  TM	RFC1743	1	Procedure created
-- 16 Feb 2005	TM	RFC1743	2	Sort by IsOutgoing first and then by the ActivityType. 
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture

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
	Set @sSQLString = "
	Select  TC.TABLECODE	as 'ActivityTypeKey',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
			     +" as 'ActivityType',
		CASE 	WHEN TC.TABLECODE in (5801,5802,5804,5805)
			THEN 1
			ELSE NULL
		END 		as 'IsOutgoing'			
	from TABLECODES TC
	where TC.TABLETYPE = 58
	UNION ALL
	Select  TC.TABLECODE	as 'ActivityTypeKey',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
			     +" as 'ActivityType',
		0		as 'IsOutgoing'			
	from TABLECODES TC
	where TABLECODE in (5801,5802,5804,5805)
	order by 'IsOutgoing' desc, 'ActivityType' asc"

	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.mk_ListActivityTypeDirection to public
GO
