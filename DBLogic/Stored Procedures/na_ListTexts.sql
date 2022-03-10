----------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListTexts
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListTexts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListTexts'
	drop procedure [dbo].[na_ListTexts]
	Print '**** Creating Stored Procedure dbo.na_ListTexts...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create    PROCEDURE dbo.na_ListTexts

-- PROCEDURE :	na_ListTexts
-- VERSION :	4
-- DESCRIPTON:	Populate the NameText table in the NameDetails typed dataset.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 18/06/2002	SF	Procedure created	

	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo			int
AS
begin
	-- disable row counts
	set nocount on
	set concat_null_yields_null off

	-- declare variables
	declare	@ErrorCode	int

	select @ErrorCode=0
	
	If @ErrorCode=0
	begin
		select 
		TT.TEXTDESCRIPTION	as 'TextTypeDescription',
		NT.TEXT			as 'Text'
		from NAMETEXT NT
		left join TEXTTYPE TT on NT.TEXTTYPE = TT.TEXTTYPE
		where NT.NAMENO = @pnNameNo
		
	End

	
	RETURN @ErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_ListTexts to public
go
