---------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListImportanceLevel
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListImportanceLevel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListImportanceLevel.'
	drop procedure [dbo].[ipw_ListImportanceLevel]
	Print '**** Creating Stored Procedure dbo.ipw_ListImportanceLevel...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListImportanceLevel
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psControlId		nvarchar(30)	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListImportanceLevel
-- VERSION:	8
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Importance Levels for an Event.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Jan 2004  TM		1	Procedure created
-- 29 Mar 2004	TM	RFC951	2	Add new optional parameter @psControlId	nvarchar(30) and new column IsDefault. 
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
-- 31 Jan 2005	TM	RFC2254	4	The entries should be shown in level of importance; i.e. IMPORTANCELEVEL DESC.
-- 31 Jan 2005	TM	RFC2254	5	Sort in ImportanceLevelKey DESCENDING sequence.
-- 15 May 2005	JEK	RFC2508	6	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 25 Sep 2009  LP      RFC8047 7       Limit the Importance Levels according to user's profile, if available.
-- 09 Mar 2010  LP      RFC8970 8       Limit the Importance Levels returned if requested by an external user.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @nProfileKey    int
Declare @nProfileImportance int
Declare @bIsExternalUser  bit

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

-- Get the current user's profile
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID,
        @bIsExternalUser = convert(bit,ISNULL(ISEXTERNALUSER,0))
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
End

-- Get the Minimum Importance Level for the profile
If @nErrorCode = 0
and @nProfileKey is not null
Begin
        Select @nProfileImportance = convert(int, ATTRIBUTEVALUE)
        from PROFILEATTRIBUTES
        where PROFILEID = @nProfileKey
        and ATTRIBUTEID = 1
        
        Set @nErrorCode = @@ERROR
End


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	I.IMPORTANCELEVEL	 as ImportanceLevelKey,
		"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as ImportanceLevelDescription,"

        If @bIsExternalUser = 0
        Begin
	        If @psControlId is not null
	        Begin
	                -- user profile default or site control default
		        Set @sSQLString = @sSQLString + char(10) + "
		        CASE WHEN I.IMPORTANCELEVEL = ISNULL(@nProfileImportance,SC.COLINTEGER)
	      	              THEN cast(1 as bit) 
	                      ELSE cast(0 as bit) 
		         END 	as IsDefault
		         from 	IMPORTANCE I
		         left join SITECONTROL SC on (UPPER(SC.CONTROLID) = UPPER(@psControlId)) 		
		         order by ImportanceLevelKey DESC"  		
	        End
	        Else Begin
                        -- user profile default or minimum level
		        Set @sSQLString = @sSQLString + char(10) + "
		        CASE WHEN I.IMPORTANCELEVEL = ISNULL(@nProfileImportance,1)
	      	              THEN cast(1 as bit) 
	                      ELSE cast(0 as bit) 
		         END 	as IsDefault
		        from 	IMPORTANCE I		
		        order by ImportanceLevelKey DESC" 
	        End	
	End
	Else
	Begin
	        -- for External Users, limit to Client Importance Levels
	        -- set the default to lowest possible level
	        Set @sSQLString = @sSQLString + char(10) + "
                        CASE WHEN I.IMPORTANCELEVEL = ISNULL(SC.COLINTEGER,1)
                        THEN cast(1 as bit) 
                        ELSE cast(0 as bit) 
                        END 	as IsDefault
                        from 	IMPORTANCE I		
                        left join SITECONTROL SC on (SC.CONTROLID = 'Client Importance')
                        where I.IMPORTANCELEVEL >= SC.COLINTEGER
                        order by ImportanceLevelKey DESC" 
	End
	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@psControlId	nvarchar(30),
					  @nProfileImportance int',
					  @psControlId	= @psControlId,
					  @nProfileImportance     = @nProfileImportance
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.ipw_ListImportanceLevel to public
GO
