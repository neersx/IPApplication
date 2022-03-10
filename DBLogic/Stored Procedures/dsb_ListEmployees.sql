-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dsb_ListEmployees 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dsb_ListEmployees]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dsb_ListEmployees.'
	Drop procedure [dbo].[dsb_ListEmployees]
End
Print '**** Creating Stored Procedure dbo.dsb_ListEmployees...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.dsb_ListEmployees 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	dsb_ListEmployees 
-- VERSION:	2
-- SCOPE:	Dashboard
-- DESCRIPTION:	Lists Employess for accounting purposes.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Oct-2009	SF	RFC8564	1	Return additional information
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	select  N.NAMENO			as EmployeeKey,
			N.NAMECODE			as EmployeeCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as EmployeeDisplayName,
			N.NATIONALITY		as CountryKey,
			EM.PROFITCENTRECODE	as ProfitCentreCode,
			Cast(Office.GENERICKEY as int)	as OfficeKey,
			NM2.IMAGEID			as ImageKey,
			case when UI.LOGINID is null
				then cast(0 as bit)
				else cast(1 as bit)
			end					as IsMyself
	from NAME N 
	join EMPLOYEE EM on (EM.EMPLOYEENO = N.NAMENO)
	left join TABLEATTRIBUTES Office on (Office.TABLETYPE = 44			
										and PARENTTABLE in ('NAME','EMPLOYEE'))
	left join (select	NM1.NAMENO, MIN(NM1.IMAGESEQUENCE) as IMAGESEQUENCE 
				from	NAMEIMAGE NM1
				group by NAMENO, IMAGESEQUENCE) NM on (NM.NAMENO =N.NAMENO)
	left join NAMEIMAGE NM2 on (NM2.NAMENO = NM.NAMENO 
							and NM2.IMAGESEQUENCE = NM.IMAGESEQUENCE)
	left join USERIDENTITY UI on (N.NAMENO = UI.NAMENO 
				and UI.IDENTITYID = @pnUserIdentityId)"
		
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnUserIdentityId int',
		@pnUserIdentityId = @pnUserIdentityId
		

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.dsb_ListEmployees to public
GO
