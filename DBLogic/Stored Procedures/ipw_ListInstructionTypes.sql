-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListInstructionTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListInstructionTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipw_ListInstructionTypes.'
	drop procedure [dbo].[ipw_ListInstructionTypes]
	print '**** Creating Stored Procedure dbo.ipw_ListInstructionTypes...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListInstructionTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsExternalUser	bit		= null
)
-- PROCEDURE:	ipw_ListInstructionTypes
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of instruction types.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2005  TM	RFC3144	1	Procedure created
-- 06 Mar 2006	TM	RFC3215	2	For external users, use new fn_FilterUserInstructionTypes to only return 
--					instruction types specified in the Client Instruction Types site control.
-- 04 Dec 2006  PG	RFC3646	3	Add @pbIsExternalUser parameter
-- 19 Nov 2007	AT	RFC3502	4	Add RestrictedByTypeDesc to output
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(4000)
Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

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
	Select 	I.INSTRUCTIONTYPE	as InstructionTypeCode, 
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as InstructionDescription,
		NT.DESCRIPTION		as RestrictedByTypeDesc
	from INSTRUCTIONTYPE I
	LEFT JOIN NAMETYPE NT ON (NT.NAMETYPE = I.RESTRICTEDBYTYPE)
	order by InstructionDescription"

	exec @nErrorCode=sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount	
End
Else If  @nErrorCode = 0
     and @pbIsExternalUser = 1
Begin	
	Set @sSQLString = "
	Select 	I.INSTRUCTIONTYPE	as InstructionTypeCode, 
		I.INSTRTYPEDESC		as InstructionDescription,
		NT.DESCRIPTION		as RestrictedByTypeDesc
	from dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId, 1, @sLookupCulture, @pbCalledFromCentura) I
	LEFT JOIN NAMETYPE NT ON (NT.NAMETYPE = I.RESTRICTEDBYTYPE)
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
go

grant execute on dbo.ipw_ListInstructionTypes  to public
go
