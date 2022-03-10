-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainCaseFamily
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainCaseFamily]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainCaseFamily.'
	Drop procedure [dbo].[csw_MaintainCaseFamily]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainCaseFamily...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

-- Allow comparison of null values
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_MaintainCaseFamily
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psFamilyKey		nvarchar(40)	= null,
	@psFamilyTitle		nvarchar(508)	= null,
	@pdtLastModifiedDate	datetime	= null
)
as
-- PROCEDURE:	csw_MaintainCaseFamily
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert or Update the checklist item.  Used by the Web version.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 FEB 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	if @psFamilyKey is not null
	Begin
		if exists(Select 1 from CASEFAMILY where FAMILY = @psFamilyKey)
		Begin

			Set @sSQLString = N'
			Update	CASEFAMILY
					Set FAMILYTITLE = @psFamilyTitle
					where	FAMILY = @psFamilyKey and
					LOGDATETIMESTAMP = @pdtLastModifiedDate'
			
			exec @nErrorCode = sp_executesql @sSQLString,
			 				N'@psFamilyKey		nvarchar(40),
			 				@psFamilyTitle		nvarchar(508),
							@pdtLastModifiedDate		datetime',
							@psFamilyKey			= @psFamilyKey,
							@psFamilyTitle			= @psFamilyTitle,
							@pdtLastModifiedDate		= @pdtLastModifiedDate
		End
		Else
		Begin
			Set @sSQLString = "Insert into CASEFAMILY
			(
			FAMILY,
			FAMILYTITLE
			)
			Values
			(
			@psFamilyKey,
			@psFamilyTitle
			)"
			
			exec @nErrorCode=sp_executesql @sSQLString,
			N'@psFamilyKey			nvarchar(40),		
			@psFamilyTitle			nvarchar(508)',
			@psFamilyKey			= @psFamilyKey,
			@psFamilyTitle			= @psFamilyTitle
		End
	End
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainCaseFamily to public
GO
