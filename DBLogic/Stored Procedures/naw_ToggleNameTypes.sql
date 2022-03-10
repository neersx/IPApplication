If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ToggleNameTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ToggleNameTypes.'
	Drop procedure [dbo].[naw_ToggleNameTypes]
End
Print '**** Creating Stored Procedure dbo.naw_ToggleNameTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ToggleNameTypes
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura	        bit		= 0,
	@psNameKeys			nvarchar(4000),	-- Mandatory; comma-separated list of name keys
	@psNameTypeKeys			nvarchar(4000),	-- Mandatory; comma-separated list of name type keys
	@pbIsAllowed			bit			= 1
)
as
-- PROCEDURE:	naw_ToggleNameTypes
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts or deletes NAMETYPECLASSIFICATION entries for single or multiple names.
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Aug 2008	LP		RFC4342	      1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode			int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	If @pbIsAllowed = 1
	Begin
		-- Update existing name type classifications
		UPDATE NAMETYPECLASSIFICATION
		SET ALLOW = 1
		where NAMENO in (SELECT NM.[Parameter] from dbo.fn_Tokenise(@psNameKeys,',') NM)
		and NAMETYPE in (SELECT NT.[Parameter] from dbo.fn_Tokenise(@psNameTypeKeys,',') NT)
		
		set @nErrorCode = @@Error
		
		-- Insert new name type classifications
		If @nErrorCode = 0
		Begin	
			INSERT INTO NAMETYPECLASSIFICATION(NAMENO,NAMETYPE,ALLOW)
			SELECT NM.[Parameter], NT.[Parameter], @pbIsAllowed
			from dbo.fn_Tokenise(@psNameKeys,',') NM
			left join dbo.fn_Tokenise(@psNameTypeKeys, ',') NT on (NT.[Parameter] is not null)
			left join NAMETYPECLASSIFICATION NC on (NC.NAMENO = NM.[Parameter] and NC.NAMETYPE = NT.[Parameter])
			where NC.NAMENO IS NULL
		End
		
	End
	Else
	-- Disable existing name type classifications
	Begin
		UPDATE NAMETYPECLASSIFICATION
		SET ALLOW = 0
		where NAMENO in (SELECT NM.[Parameter] from dbo.fn_Tokenise(@psNameKeys,',') NM)
		and NAMETYPE in (SELECT NT.[Parameter] from dbo.fn_Tokenise(@psNameTypeKeys,',') NT)		
	End

	set @nErrorCode = @@Error

End

Return @nErrorCode
GO

Grant execute on dbo.naw_ToggleNameTypes to public
GO