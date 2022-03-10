-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateOfficialNumber									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateOfficialNumber.'
	Drop procedure [dbo].[csw_UpdateOfficialNumber]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateOfficialNumber...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateOfficialNumber
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@psOfficialNumber		nvarchar(36),	-- Mandatory
	@psNumberTypeCode		nvarchar(3),	-- Mandatory
	@pbIsCurrent			bit		= null,
	@pdtDateEntered			datetime	= null,
	@psOldOfficialNumber		nvarchar(36)	= null,		
	@psOldNumberTypeCode		nvarchar(3)	= null,		
	@pbOldIsCurrent			bit		= null,
	@pdtOldDateEntered		datetime	= null,
	@pbIsOfficialNumberInUse	bit		= 0,	-- deprecated.
	@pbIsNumberTypeCodeInUse	bit		= 0,	-- deprecated.
	@pbIsCurrentInUse		bit	 	= 0,	-- deprecated.
	@pbIsDateEnteredInUse		bit		= 0,	-- deprecated.
	@pdtLastModifiedDate		datetime	= null output
)
as
-- PROCEDURE:	csw_UpdateOfficialNumber
-- VERSION:	6
-- DESCRIPTION:	Update an official number if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Sep 2005	TM		1	Procedure created
-- 30 Nov 2005	TM	RFC3193	2	Adjusted standard parameters to include both old and current versions 
--							of NumberTypeCode and OfficialNumber.
-- 04 Aug 2010  DV	RFC9524	3	Update ISCURRENT to 0 if a NUMBERTYPE equal to @psNumberTypeCode exists 
--							and if @pbIsCurrentInUse = 1
-- 27 Oct 2011	SF	R10553	4	Adapt procedure for use in Silverlight Official Number tab
-- 03 Sep 2017	DV	DR49780 5	Check for Iscurrent should be called everytime if the @pbIsCurrent is 1.
-- 19 May 2020	DL	DR-58943 6	Ability to enter up to 3 characters for Number type code via client server	

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update OFFICIALNUMBERS
				   set	OFFICIALNUMBER = @psOfficialNumber,
					NUMBERTYPE = @psNumberTypeCode,
					ISCURRENT = @pbIsCurrent,
					DATEENTERED = @pdtDateEntered
				"

	Set @sWhereString = @sWhereString+CHAR(10)+"
		    CASEID = @pnCaseKey 
		and OFFICIALNUMBER = @psOldOfficialNumber
		and NUMBERTYPE = @psOldNumberTypeCode
		"

	If @pdtLastModifiedDate is not null
	Begin
		Set @sWhereString = @sWhereString+" and LOGDATETIMESTAMP = @pdtLastModifiedDate"
	End

	Set @sWhereString = @sWhereString+"

		Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
		from	OFFICIALNUMBERS
		where	CASEID			= @pnCaseKey
		and	NUMBERTYPE		= @psNumberTypeCode
		and	OFFICIALNUMBER		= @psOfficialNumber
	"
	
	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pdtLastModifiedDate	datetime output,
			@pnCaseKey		int,
			@psOfficialNumber	nvarchar(36),
			@psNumberTypeCode	nvarchar(3),
			@pbIsCurrent		bit,
			@pdtDateEntered		datetime,
			@psOldOfficialNumber	nvarchar(36),
			@psOldNumberTypeCode	nvarchar(3),
			@pbOldIsCurrent		bit,
			@pdtOldDateEntered	datetime',
			@pdtLastModifiedDate	= @pdtLastModifiedDate output,
			@pnCaseKey	 	= @pnCaseKey,
			@psOfficialNumber	= @psOfficialNumber,
			@psNumberTypeCode	= @psNumberTypeCode,
			@pbIsCurrent	 	= @pbIsCurrent,
			@pdtDateEntered	 	= @pdtDateEntered,
			@psOldOfficialNumber	= @psOldOfficialNumber,
			@psOldNumberTypeCode	= @psOldNumberTypeCode,
			@pbOldIsCurrent	 	= @pbOldIsCurrent,
			@pdtOldDateEntered	= @pdtOldDateEntered
	
	If @nErrorCode = 0
	Begin
		If(@pbIsCurrent = 1)
		Begin
		 if exists (Select 1 from OFFICIALNUMBERS Where NUMBERTYPE = @psNumberTypeCode 
			and ISCURRENT = 1 and CASEID = @pnCaseKey and OFFICIALNUMBER <> @psOfficialNumber)
			Begin
				Update  OFFICIALNUMBERS set ISCURRENT = 0 Where NUMBERTYPE = @psNumberTypeCode 
				and ISCURRENT = 1 and CASEID = @pnCaseKey and OFFICIALNUMBER <> @psOfficialNumber
			End
		End
	End

End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateOfficialNumber to public
GO