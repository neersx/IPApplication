-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListNameType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameType.'
	Drop procedure [dbo].[naw_ListNameType]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[naw_ListNameType]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbNameType 	nvarchar(10) 	
)
AS
-- PROCEDURE:	[naw_ListNameType]
-- VERSION:	3

-- DESCRIPTION:	Returns restriction for creating New Name according to Name Type Key.

-- MODIFICATIONS :
--- Date	Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 26 Mar 2009  ashish	RFC7254	1	Procedure created
-- 31 Mar 2009  ashish	RFC7254	2	Check for the null values.
-- 04 Feb 2010	DL	18430	3	Grant stored procedure to public



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)


Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	NAMETYPE 	as NameTypeKey,
		DESCRIPTION 	as NameTypeDescription,PICKLISTFLAGS,
		case when isnull(PICKLISTFLAGS,0) & 0 = 0 then 0 end,
		
		cast(case when isnull(PICKLISTFLAGS,0) & 1 = 1 then 1 else 0 end as bit) AS 'IsApplicableForIndividual',
		cast(case when isnull(PICKLISTFLAGS,0) & 2 = 2 then 1 else 0 end as bit) AS 'IsApplicableForStaffMember',
		cast(case when isnull(PICKLISTFLAGS,0) & 4 = 4 then 1 else 0 end as bit) AS 'IsApplicableForClient',
		cast(case when isnull(PICKLISTFLAGS,0) & 8 = 8 then 1 else 0 end as bit) AS 'IsApplicableForOrganisation'
	from  NAMETYPE"
	+ char(10) + "where NAMETYPE=@pbNameType order by DESCRIPTION" 

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @pbNameType 	nvarchar(10) ',
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @pbNameType	= @pbNameType
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameType to public
GO
