-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListNameText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListNameText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListNameText'
	drop procedure [dbo].[wa_ListNameText]
	print '**** Creating procedure dbo.wa_ListNameText...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListNameText]
	@pnNameNo	int

-- PROCEDURE :	wa_ListNameText
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of Text for a given Name passed as a parameter.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 21/07/2001	AF	Procedure created
-- 31/07/2001	MF	Only display details if the user has the correct access rights

as 
begin
	-- disable row counts
	set nocount on
	
	-- declare variables

	declare @ErrorCode	int

	-- Check that external users have access to see the details of the Name.

	Execute @ErrorCode=wa_CheckSecurityForName @pnNameNo
	
	if  @ErrorCode=0
	Begin
	
		select	DESCRIPTION = TT.TEXTDESCRIPTION, 
				NT.TEXT
		from	NAMETEXT NT
		join	TEXTTYPE TT
		on		NT.TEXTTYPE 	= TT.TEXTTYPE
		where	NT.NAMENO = @pnNameNo
		AND		exists (select 0 from USERS
				where USERID = user
				AND (EXTERNALUSERFLAG < 2 or EXTERNALUSERFLAG is null ))
		ORDER BY  TT.TEXTDESCRIPTION

		select @ErrorCode=@@Error
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListNameText] to public
go
