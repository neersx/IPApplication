-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertOfficialNumber.'
	Drop procedure [dbo].[csw_InsertOfficialNumber]
End
Print '**** Creating Stored Procedure dbo.csw_InsertOfficialNumber...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertOfficialNumber
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory	
	@psOfficialNumber		nvarchar(36),	-- Mandatory	
	@psNumberTypeCode		nvarchar(3),	-- Mandatory	
	@pbIsCurrent			bit		= null,
	@pdtDateEntered			datetime	= null,
	@pbIsCurrentInUse		bit		= 0,
	@pbIsDateEnteredInUse		bit		= 0,
	@pdtLastModifiedDate		datetime	= null output,
	@psRowKey			nvarchar(50)	= null output
)
as
-- PROCEDURE:	csw_InsertOfficialNumber
-- VERSION:	5
-- DESCRIPTION:	Insert new official number.

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	------- --------------------------------------- 
-- 28 Sep 2005	TM			1	Procedure created
-- 04 Aug 2010  DV		RFC9524	2	Update ISCURRENT to 0 if a NUMBERTYPE equal to @psNumberTypeCode exists 
--						and if @pbIsCurrentInUse = 1
-- 27 OCT 2011	SF		R10553	3	Return @pdtLastModifiedDate	
-- 09 Nov 2011	SF		R10553	4	Return @psRowKey
-- 19 May 2020	DL		DR-58943	5	Ability to enter up to 3 characters for Number type code via client server	

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @sLegacySQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	
	Set @sSQLString = " 
	insert 	into OFFICIALNUMBERS
		(CASEID, 
		 OFFICIALNUMBER, 		 
		 NUMBERTYPE,
		 ISCURRENT,
		 DATEENTERED)
	values	(@pnCaseKey,
		 @psOfficialNumber, 		
		 @psNumberTypeCode,
		 @pbIsCurrent,
		 @pdtDateEntered)
		 
	Select	@pdtLastModifiedDate = LOGDATETIMESTAMP,
		@psRowKey = CAST(CHECKSUM(CAST(CASEID as nvarchar(11))+'^'+
		OFFICIALNUMBER+'^'+
		NUMBERTYPE) as nvarchar)
	from	OFFICIALNUMBERS
	where	CASEID			= @pnCaseKey
	and	NUMBERTYPE		= @psNumberTypeCode
	and	OFFICIALNUMBER		= @psOfficialNumber"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pdtLastModifiedDate	datetime output,
					  @psRowKey		nvarchar(50) output,
					  @pnCaseKey		int,
					  @psOfficialNumber	nvarchar(36),
					  @psNumberTypeCode	nvarchar(3),					 
					  @pbIsCurrent		bit,
					  @pdtDateEntered	datetime',
					  @pdtLastModifiedDate	= @pdtLastModifiedDate output,
					  @psRowKey		= @psRowKey output,
					  @pnCaseKey		= @pnCaseKey,
					  @psOfficialNumber	= @psOfficialNumber,
					  @psNumberTypeCode	= @psNumberTypeCode,					 
					  @pbIsCurrent		= @pbIsCurrent,
					  @pdtDateEntered	= @pdtDateEntered	
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

Grant execute on dbo.csw_InsertOfficialNumber to public
GO