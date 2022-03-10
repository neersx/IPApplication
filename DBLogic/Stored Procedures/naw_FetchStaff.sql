-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchStaff									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchStaff]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchStaff.'
	Drop procedure [dbo].[naw_FetchStaff]
End
Print '**** Creating Stored Procedure dbo.naw_FetchStaff...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchStaff
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	naw_FetchStaff
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Staff business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 03 Apr 2006	AU	RFC3501	1	Procedure created
-- 13 Oct 2008	PA	RFC5866	2	Change Proc to add WIP Entity.
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
	CAST(E.EMPLOYEENO as nvarchar(11)) 	as RowKey,
	E.EMPLOYEENO				as NameKey,
	E.ABBREVIATEDNAME			as AbbreviatedName,
	E.STAFFCLASS				as StaffClassificationKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura)+"
						as StaffClassification,
	"+dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFTITLE',null,'E',@sLookupCulture,@pbCalledFromCentura)+"
						as SignOffTitle,
	"+dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFNAME',null,'E',@sLookupCulture,@pbCalledFromCentura)+"
						as SignOffName,
	E.STARTDATE				as DateCommenced,
	E.ENDDATE				as DateCeased,
	E.CAPACITYTOSIGN			as CapacityToSignKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)+"
						as CapacityToSign,
	E.PROFITCENTRECODE			as ProfitCentreCode,
	"+dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura)+"
						as ProfitCentreDescription,
	E.DEFAULTENTITYNO				as DefaultEntityKey,
	"+dbo.fn_FormatName('NAME', 'NAME', null, null)+"
						as DefaultEntityName,
	E.RESOURCENO				as DefaultPrinterKey,
	"+dbo.fn_SqlTranslatedColumn('RESOURCE','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)+"
						as DefaultPrinterDescription
	from EMPLOYEE E
	left join TABLECODES 	TC1 	on (TC1.TABLECODE 	= E.STAFFCLASS)
	left join TABLECODES 	TC2 	on (TC2.TABLECODE 	= E.CAPACITYTOSIGN)
	left join PROFITCENTRE 	PC 	on (PC.PROFITCENTRECODE = E.PROFITCENTRECODE)
	left join SPECIALNAME S on (S.NAMENO=E.DEFAULTENTITYNO AND S.ENTITYFLAG = 1)
	left join NAME N on (N.NAMENO = S.NAMENO)
	left join RESOURCE 	R 	on (R.RESOURCENO 	= E.RESOURCENO)
	where 
	E.EMPLOYEENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey	int',
			@pnNameKey	= @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchStaff to public
GO