-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchExemptCharges
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchExemptCharges]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchExemptCharges.'
	Drop procedure [dbo].[naw_FetchExemptCharges]
End
Print '**** Creating Stored Procedure dbo.naw_FetchExemptCharges...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchExemptCharges
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@pbNewRow		bit		= 0,
	@pnRateNo		int	= null
)
as
-- PROCEDURE:	naw_FetchExemptCharges
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the ExemptCharges business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Feb 2010	MS	RFC7281	1	Procedure created
-- 11 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @nRateNo	int
Declare @sRateDesc	nvarchar(50)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin	
	If @pbNewRow = 1
	Begin
		Set @sSQLString = "Select	
			@nRateNo = EC.RATENO,
			@sRateDesc = "+dbo.fn_SqlTranslatedColumn('RATES','RATEDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)+"
		from NAMEEXEMPTCHARGES EC
		join RATES R	on (R.RATENO = EC.RATENO)
		where 	EC.RATENO = @pnOriginalRateNo"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nRateNo		int output,
				@sRateDesc		nvarchar(50) output,
				@pnOriginalRateNo	int',
				@nRateNo		= @nRateNo output,
				@sRateDesc		= @sRateDesc output,				
				@pnOriginalRateNo	= @pnRateNo

		If @nErrorCode = 0
		Begin
			Select 	null		as RowKey,
				@pnNameKey	as NameKey,
				@nRateNo	as RateKey,
				@sRateDesc	as RatesDescription,
				null		as Notes
		End

	End
	Else
	Begin
		Set @sSQLString = "Select	
		CAST(EC.NAMENO as nvarchar(11)) + '^' + CAST(EC.RATENO as nvarchar(11)) as 'RowKey',
		EC.NAMENO	    as 'NameKey',
		EC.RATENO	    as RateKey,
		"+dbo.fn_SqlTranslatedColumn('RATES','RATEDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'RateDescription',
		"+dbo.fn_SqlTranslatedColumn('NAMEEXEMPTCHARGES','NOTES',null,'EC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Notes'
		from NAMEEXEMPTCHARGES EC
		join RATES R	on (R.RATENO = EC.RATENO)
		where EC.NAMENO = @pnNameKey
		order by 'RateDescription', 'Notes' "

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int,
				@pnUserIdentityId	int,
				@sLookupCulture		nvarchar(10),
				@pbCalledFromCentura	bit',
				@pnNameKey		= @pnNameKey,
				@pnUserIdentityId 	= @pnUserIdentityId,
				@sLookupCulture		= @sLookupCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura

	End
	

End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchExemptCharges to public
GO
