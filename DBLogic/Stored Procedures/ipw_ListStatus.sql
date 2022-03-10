---------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListStatus
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListStatus.'
	drop procedure [dbo].[ipw_ListStatus]
	Print '**** Creating Stored Procedure dbo.ipw_ListStatus...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListStatus
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbIsPending 		bit		= null,
	@pbIsRenewal  		bit		= null,
	@pbIsRegistered		bit		= null,
	@pbIsDead			bit		= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListStatus
-- VERSION:	9
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Statuses.

-- MODIFICATIONS :
-- Date         Who  	Number	Version  Change
-- ------------ ---- 	------	-------- ------------------------------------------- 
-- 05 Feb 2004  TM	RFC642	1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jul 2010	AT	RFC7278	4	Return StatusCode as int.
-- 18 Oct 2010	LP	RFC9321	5	Return ConfirmRequired (bit) column.
--						Return status flags.
-- 08 Feb 2011	ASH	RFC8878	6	Filter result set according to status value.
-- 08 Mar 2011  LP  RFC10085 		7 	 Re-instated 'ConfirmRequired' column as it seems to have been removed by a merge.
-- 12 Jun 2012	SW	RFC12381 	8	Default 'ConfirmRequired' column to false if null.
-- 17 July 2012	SW	RFC12381 	9	Default 'ConfirmRequired' column to false if null.

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
	Select 	
		CAST(S.STATUSCODE as int)	as 'StatusKey',
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'StatusDescription',
		S.CONFIRMATIONREQ as 'ConfirmRequired',
		CASE WHEN S.RENEWALFLAG = 1 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsRenewal',
		CASE WHEN S.LIVEFLAG = 1 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsPending',
		CASE WHEN S.REGISTEREDFLAG = 1 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsRegistered',
		CASE WHEN S.LIVEFLAG = 0 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsDead'
	from 	STATUS S where 1=1"
	
	If @pbIsRenewal is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) + " and   S.RENEWALFLAG = @pbIsRenewal"					
	End

	If  ((@pbIsPending = @pbIsDead and @pbIsDead = @pbIsRegistered) or (@pbIsPending is null and @pbIsDead is null and @pbIsRegistered is null))
	Begin
		Set @sSQLString = @sSQLString + char(10) + " and   1=1 "
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + char(10) + " and (S.LIVEFLAG = isnull(@pbIsPending,0) or S.LIVEFLAG = isnull(@pbIsDead,0)) and S.REGISTEREDFLAG = isnull(@pbIsRegistered,0)"
	End


	Set @sSQLString = @sSQLString + char(10) + "order by StatusDescription"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pbIsPending	bit,
					  @pbIsDead    bit,
					  @pbIsRegistered    bit,
					  @pbIsRenewal      bit',
					  @pbIsPending  = @pbIsPending,
					  @pbIsDead  =  @pbIsDead,
					  @pbIsRegistered  =  @pbIsRegistered,
					  @pbIsRenewal   =  @pbIsRenewal 
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.ipw_ListStatus to public
GO
