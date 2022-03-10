-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListInstructions.'
	Drop procedure [dbo].[ipw_ListInstructions]
	Print '**** Creating Stored Procedure dbo.ipw_ListInstructions...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListInstructions
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsExternalUser	bit		= null
)
AS
-- PROCEDURE:	ipw_ListInstructions
-- VERSION:	6
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Return InstructionKey, InstructionDescription from Instructions table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Mar 2006	TM	RFC3215	4	For external users, limit standing instructions returned to instruction types 
--					specified in the Client Instruction Types site control. 
-- 28 Mar 2006	IB	RFC3378	5	Return an additional InstructionTypeKey column.
-- 04 Dec 2006	PG	RFC3646	6	Add @pbIsExternalUser parameter


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

-- Determine if the user is internal or external
If @nErrorCode=0 and @pbIsExternalUser is null
Begin		
	Set @sSQLString="
	Select	@pbIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"
	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser		bit	OUTPUT,
				  @pnUserIdentityId		int',
				  @pbIsExternalUser=@pbIsExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End

If  @nErrorCode = 0
and @pbIsExternalUser = 0
Begin	
	Set @sSQLString = "
	Select 	I.INSTRUCTIONCODE	as 'InstructionKey', 
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " 	as 'InstructionDescription',
		I.INSTRUCTIONTYPE	as 'InstructionTypeKey'		
	from INSTRUCTIONS I
	order by InstructionDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End
Else If  @nErrorCode = 0
and @pbIsExternalUser = 1
Begin	
	Set @sSQLString = "
	Select 	I.INSTRUCTIONCODE		as 'InstructionKey', 
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'InstructionDescription'		
	from INSTRUCTIONS I
	join dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId, 1, @sLookupCulture, @pbCalledFromCentura) IT
						on (IT.INSTRUCTIONTYPE = I.INSTRUCTIONTYPE)
	order by InstructionDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @sLookupCulture	= @sLookupCulture,
				  @pbCalledFromCentura	= @pbCalledFromCentura

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListInstructions to public
GO
