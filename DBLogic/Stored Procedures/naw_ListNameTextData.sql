-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameTextData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameTextData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameTextData.'
	Drop procedure [dbo].[naw_ListNameTextData]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameTextData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameTextData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int
)
as
-- PROCEDURE:	naw_ListNameTextData
-- VERSION:	15
-- DESCRIPTION:	Populates the NameTextData dataset 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Sep 2004	TM	RFC1811	1	Procedure created.
-- 01 Oct 2004	TM	RFC1811	2	Correct the AvailableTextTypes filtering logic.
-- 04 Nov 2004	TM	RFC1811	3	Correct the AvailableTextTypes filtering logic.
-- 26 Nov 2004	TM	RFC2055	4	Extended Name should not be shown in Name Notes Maintenance.
-- 21 Feb 2004	TM	RFC2344	5	Correct the Name.UsedAsFlag filtering logic.
-- 02 Mar 2005	JEK	RFC2344	6	Text Type Used as flag mapping incorrect.  Should match on any bit.
-- 15 May 2005  JEK	RFC2508	7	Pass @sLookupCulture to fn_FilterUserXxx.
-- 13 Jul 2006	SW	RFC3828	8	Pass getdate() to fn_Permission..
-- 25 Sep 2006	SF	RFC4331 9	Convert to work with XFOP - returning available and existing rows in the same resultset, with rowkey
-- 30 Jun 2008	SF	RFC6535 10	Add Modified Date to NameText result set 
-- 11 Dec 2008	MF	17136	11	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 02 Mar 2010	MS	R100147	12	Added TextType in Order By.
-- 19 May 2011	KR	R10669	13	Added null check in the site control comparison.
-- 11 Apr 2013	DV	R13270	15	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @dtToday = getdate()

-- Initialise variables
Set @nErrorCode = 0

-- Populating Name result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnNameKey 	as NameKey,
	dbo.fn_FormatNameUsingNameNo(@pnNameKey, NULL)	as Name"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey	int',
					  @pnNameKey	= @pnNameKey

End

-- Populating NameText result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select cast(@pnNameKey as nvarchar(11)) + '^' + TT.TEXTTYPE as RowKey,
		@pnNameKey 		as NameKey,
		TT.TEXTTYPE		as TextTypeKey,
		TT.TEXTDESCRIPTION	as TextType,
		CASE WHEN NT.NAMENO=@pnNameKey
			THEN NT.LOGDATETIMESTAMP
			ELSE NULL END	as 'ModifiedDate',
		-- IsPublic is true if the TextTypeKey exists in the Client Text Types site control.
		-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
		-- will match on 'Z' but not on 'ZC'.
		CASE WHEN patindex('%'+','+FTT.TEXTTYPE+','+'%',',' + replace(S.COLCHARACTER, ' ', '') + ',')>0
		     THEN cast(1 as bit)
		     ELSE cast(0 as bit)
		END			as IsPublic,
		CASE WHEN NT.NAMENO=@pnNameKey 
			THEN 0 
			ELSE 1 END	as IsNew,
		CASE WHEN NT.NAMENO=@pnNameKey 
			THEN NT.TEXT
			ELSE NULL END	as Text		
	from TEXTTYPE TT	
	join NAME N 			on (N.NAMENO = @pnNameKey)
	left join NAMETEXT NT		on (NT.TEXTTYPE = TT.TEXTTYPE and NT.NAMENO = @pnNameKey)
	left join dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture, 0,@pbCalledFromCentura) FNT	
					on (FNT.TEXTTYPE = NT.TEXTTYPE)	
	-- TASK.AnnotateName = 26
	left join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', 26, null, @dtToday) PGEXISTING
					on (PGEXISTING.CanUpdate = 1 or PGEXISTING.CanDelete = 1)
	left join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', 26, null, @dtToday) PGNEW
					on (PGNEW.CanInsert = 1)
	left join dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture, 0,@pbCalledFromCentura) FTT	
					on (FTT.TEXTTYPE = TT.TEXTTYPE)
	left join SITECONTROL S 	on (S.CONTROLID='Client Text Types')
	where 
	-- Only text types visible on the client/server Name Text tab should be available 
	-- for maintenance;
	TT.USEDBYFLAG > 0 -- Exclude any case text types
	and 
	(    	cast(N.USEDASFLAG&1 as bit) & cast(TT.USEDBYFLAG&2 as bit) = 1 -- Individual
		or   cast(N.USEDASFLAG&2 as bit) & cast(TT.USEDBYFLAG&1 as bit) = 1 -- Staff
		or   cast((N.USEDASFLAG&1)-1 as bit) & cast(TT.USEDBYFLAG&4 as bit) = 1 -- Organisation (not Individual)
	)
	and
	 (
		NT.NAMENO = @pnNameKey 	-- for existing rows can this be edited or deleted?
		and (PGEXISTING.CanUpdate = 1 or PGEXISTING.CanDelete = 1) or
		(
			PGNEW.CanInsert = 1  -- for new rows, can this user insert at all?
			and NT.NAMENO is null
			and exists (Select 1 
				    from TEXTTYPE TT2
				    left join SITECONTROL S1 on (S1.CONTROLID='HOMENAMENO')
				    left join SITECONTROL S2 on (S2.CONTROLID='Welcome Message - Internal')
				    left join SITECONTROL S3 on (S3.CONTROLID='Welcome Message - Global')
				    where  TT.TEXTTYPE = TT2.TEXTTYPE
				    and   (S1.COLINTEGER = @pnNameKey or
				          ((S1.COLINTEGER <> @pnNameKey and 
					   ((TT2.TEXTTYPE <> S2.COLCHARACTER or S2.COLCHARACTER is null) and 
					   (TT2.TEXTTYPE <> S3.COLCHARACTER or S3.COLCHARACTER is null)))) 
				     or   (S2.COLCHARACTER is null and 
				      	   S3.COLCHARACTER is null)))
		)
	)
	Order By TextType"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @dtToday		datetime',
					  @pnNameKey		= @pnNameKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @dtToday		= @dtToday

End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameTextData to public
GO
