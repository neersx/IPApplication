---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListConfig
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListConfig]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListConfig.'
	drop procedure [dbo].[p_ListConfig]
	Print '**** Creating Stored Procedure dbo.p_ListConfig...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.p_ListConfig
    @pnUserIdentityId		int 		= null,
    @psCulture			nvarchar(10) 	= null,
    @pnNameNo			int 			output, -- Mandatory
    @psNameCode			nvarchar(10)	= null	output,
    @psFullName			nvarchar(256) 		output, -- Mandatory
    @pnIsExternalUser		bit 		= null	output,
    @pnIsAdministrator		bit 		= null	output,
    @psEmailAddress		nvarchar(100)    = null  output, 
    @pbIsIncompleteWorkBench	bit		= null  output,
    @pbIsIncompleteInprostart   bit		= null	output, 
    @pnTabID			int 		= null,
    @pbCalledFromCentura	bit		= 0
    
AS
-- PROCEDURE :	p_ListConfig
-- VERSION :	19
-- DESCRIPTION:	A procedure to return
--				the personalised information for a user, including
--				their internal name number, fullname, preferences/settings,
--				the personalised tabs and the modules for the requested tab
--				The names of the tabs and modules are given in the requested language (TO DO)
--				then modules for the requested tab are returned
--				If no UesrIdentity is provided then the default is returned

-- MODIFICATIONS :
-- Date  	Who 	RFC# 	Version Change
-- ------------ ------- ---- 	------- ----------------------------------------------- 
-- 13-Oct-2003  TM  	RFC524	5	List Modules not returning data for other tabs.
--					Add a new @pnTabID int parameter, default it to NULL and pass it 
--					to the p_ListModules.
-- 12-Dec-2003	AWF		6	Return output params to indicate whether the user is External
--					and an admininstrator 
-- 04-Feb-2004	TM	RFC783	7	Temporary solution to return an Email. It will be replaced 
--					after RFC868 is implemented.
-- 25-Feb-2004	TM	RFC867	8	Modify the logic extracting the 'Main Email' to use new Name.MainEmail column. 
-- 27-Feb-2004	TM	RFC622	9	Add two new optional output parameters: @pbIsIncompleteWorkBench (bit) and 
--					@pbIsIncompleteInprostart (bit). Use the fn_FormatName function to format 
--					the full name. 
-- 03-Mar-2004	TM	RFC622	10	Add NameNo to the where clause when extracting the Main Email.
-- 27-Jul-2004	TM	RFC1201	11	Return the settings as the third result set calling p_ListModuleConfigSettings.
-- 15 Sep 2004	JEK	RFC886	3	Implement @pbCalledFromCentura.
-- 02 Nov 2004	TM	RFC390	13	Return new result set that returns PortalSettings held against the Module 
--					that the user is permitted to see for the Tab.
-- 04 Dec 2009	LP	RFC8450	14	Return new result set containing Logical Programs available to the user.
-- 14 Jan 2010	LP	RFC8450	15	Fix logic to return Logical Programs result set using Union.
-- 03 Mar 2010	JCLG	RFC8953	16	Use p_ListPrograms to return the logical programs
-- 17 Mar 2010	SF	RFC7267	17	Return additional details about the user identity
-- 02 Nov 2015	vql	R53910	18	Adjust formatted names logic (DR-15543).
-- 04 Sep 2019	DV	D23442	19	Increased the email output parameter length to 100.

set nocount on
set concat_null_yields_null off
DECLARE		@ErrorCode		int

Declare 	@sSQLString		nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement
Set @ErrorCode   = 0

-- TODO Get the user's preferred culture and use it
if (@pnUserIdentityId is not null)
begin
	select
			@pnNameNo=UI.NAMENO,
			@pnIsExternalUser=UI.ISEXTERNALUSER,
			@pnIsAdministrator=UI.ISADMINISTRATOR,
			@psNameCode			= N.NAMECODE,
			@psFullName = dbo.fn_FormatNameUsingNameNo(N.NAMENO, 7101),
			@pbIsIncompleteWorkBench=CASE WHEN UI.ISVALIDWORKBENCH=0 THEN cast(1 as bit) ELSE cast(0 as bit) END,
			@pbIsIncompleteInprostart=CASE WHEN UI.ISVALIDINPROSTART=0 THEN cast(1 as bit) ELSE cast(0 as bit) END
	from	USERIDENTITY UI
			left join NAME N on (N.NAMENO = UI.NAMENO)
	where
			UI.IDENTITYID = @pnUserIdentityId
end	

-- Extract the Main Email of the Name.
if @ErrorCode = 0
begin
	Set @sSQLString = 
	'Select @psEmailAddress = dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION)
	 from NAME N
	 join TELECOMMUNICATION T on (T.TELECODE = N.MAINEMAIL)
	 where N.NAMENO = @pnNameNo'

	exec @ErrorCode = sp_executesql @sSQLString,
					N'@pnNameNo   		int,
					  @psEmailAddress 	nvarchar(100)	  output',
					  @pnNameNo		= @pnNameNo,
					  @psEmailAddress	= @psEmailAddress output 						
end

-- Get Tabs list
If  @ErrorCode=0 
begin
	execute @ErrorCode = p_ListTabs
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture, 
		@pbCalledFromCentura	=@pbCalledFromCentura
end

-- Then, get the modules for the first tab
If  @ErrorCode=0 and @@Rowcount>0
begin
	execute @ErrorCode = p_ListModules 
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture, 
		@pnTabID		=@pnTabID,
		@pbCalledFromCentura	=@pbCalledFromCentura
end

-- Get the settings that match the CONFIGURATIONIDs returned by p_ListModules above:
If  @ErrorCode=0 
and @@Rowcount>0
Begin
	execute @ErrorCode = p_ListModuleConfigSettings 
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture, 
		@pnTabID		=@pnTabID
End

-- Get the PortalSettings held against the Module that the user is permitted to see for the Tab:
If  @ErrorCode=0 
Begin
	execute @ErrorCode = p_ListModuleSettings 
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture, 
		@pnTabID		=@pnTabID
End

-- Get the LogicalPrograms available to the user based on user roles
If @ErrorCode= 0
Begin
	execute @ErrorCode = p_ListPrograms
		@pnUserIdentityId	=@pnUserIdentityId, 
		@psCulture		=@psCulture
End

return @ErrorCode
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.p_ListConfig to public
go
