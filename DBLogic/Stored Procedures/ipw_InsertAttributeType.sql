-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertAttributeType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertAttributeType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertAttributeType.'
	Drop procedure [dbo].[ipw_InsertAttributeType]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertAttributeType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE [dbo].[ipw_InsertAttributeType]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,	
	@psParentTable				nvarchar(50),	-- Mandatory	
	@pnTableType				smallint,	-- Mandatory
	@pnMaximumAllowed			smallint	= null,
	@pnMinimumAllowed			smallint	= null,
	@pbModifyByService			bit		= 0,
	@pbUpdateAllAttributes			bit		= 0,
	@pbCalledFromCentura			bit		= 0
)
as
-- PROCEDURE :	ipw_InsertAttributeType
-- VERSION :	4
-- DESCRIPTION:	Procedure to insert or update Attribute type
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2009	DV	RFC8016	1	Procedure created 
-- 09 Oct 2009	SF	RFC8522	2	Fix "String or binary data would be truncated." sql error
-- 04 Feb 2010	DL	18430	3	Grant stored procedure to public
-- 01 Dec 2014	DV	R25316	4	Insert and Update MODIFYBYSERVICE column


Declare @nErrorCode		int

-- Initialise variables
Set @nErrorCode = 0
Declare @sSQLString nvarchar(4000)

If @nErrorCode = 0
Begin
	If exists (Select 1 from SELECTIONTYPES 
			   where PARENTTABLE = @psParentTable AND TABLETYPE = @pnTableType)
	Begin		
		Set @sSQLString = "
				Update  SELECTIONTYPES 
				Set MAXIMUMALLOWED = @pnMaximumAllowed, 
				MINIMUMALLOWED = @pnMinimumAllowed,
				MODIFYBYSERVICE = @pbModifyByService
				where PARENTTABLE = @psParentTable 
				And TABLETYPE = @pnTableType"
	End
	Else
	Begin
	
		Set @sSQLString = "
				Insert into SELECTIONTYPES 
					(PARENTTABLE,
					TABLETYPE,
					MAXIMUMALLOWED,
					MINIMUMALLOWED,
					MODIFYBYSERVICE)
				values 
					(@psParentTable,
					@pnTableType,
					@pnMaximumAllowed,
					@pnMinimumAllowed,
					@pbModifyByService)"
		
	End
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psParentTable		nvarchar(50),
					@pnTableType			int,
					@pnMinimumAllowed		int,
					@pnMaximumAllowed		int,
					@pbModifyByService		bit',					
					@psParentTable	 		= @psParentTable,
					@pnTableType	 		= @pnTableType,
					@pnMinimumAllowed		= @pnMinimumAllowed,
					@pnMaximumAllowed		= @pnMaximumAllowed,
					@pbModifyByService		= @pbModifyByService		
End
If @nErrorCode = 0 and @pbUpdateAllAttributes = 1
Begin		
	Set @sSQLString = "
			Update  SELECTIONTYPES 
			Set MODIFYBYSERVICE = @pbModifyByService 
			where TABLETYPE = @pnTableType
			And PARENTTABLE in ('INDIVIDUAL','EMPLOYEE','ORGANISATION','NAME/LEAD') "
			
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTableType			int,
					@pbModifyByService		bit',					
					@pnTableType	 		= @pnTableType,
					@pbModifyByService		= @pbModifyByService
End

Return @nErrorCode
GO

grant execute on dbo.ipw_InsertAttributeType to public
GO


