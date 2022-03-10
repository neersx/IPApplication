-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_PrepareName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_PrepareName') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_PrepareName'
	Drop function [dbo].[fn_PrepareName]
End
Print '**** Creating Function dbo.fn_PrepareName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_PrepareName
(
	@psName			nvarchar(254),		-- lastname
	@psFirstName		nvarchar(50),	
	@psTitle		nvarchar(20),
	@pnNameStyle		int		=7101,	-- 7101 = Surname last, 7102 = Surname first
	@psPrepareFor		nchar(1)		-- Possible values: 'F' - Formal Salutation, 'I' - Informal Salutation, 'S' - Sign Off Name
) 
RETURNS nvarchar(254)
AS
-- Function :	fn_PrepareName
-- VERSION :	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Prepares a name for uses in various contexts; 
--		e.g. as an informal salutation.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Apr 2006	SW	RFC3503		1	Function created
-- 21 Aug 2006	PG	RFC4179 	2 	Remove trailing space
-- 31 Oct 2018	vql	DR-45102	3	remove control characters from functions.

Begin
	Declare @sResult nvarchar(254)

	Set 	@sResult = N''
	Set 	@psName = ltrim(rtrim(@psName))
	Set 	@psFirstName = ltrim(rtrim(@psFirstName))

	-- @psTitle <space> @psName
	If @psPrepareFor = 'F'
	Begin
		If @psTitle is not null
		Begin
			Set @sResult = @psTitle + space(1)
		End

		If @psName is not null
		Begin
			Set @sResult = @sResult + @psName
		End
	End

	-- First word of @psFirstName
	If @psPrepareFor = 'I'
	Begin
		If (@psFirstName is not null and @psFirstName <> '')
		Begin
			Set @sResult = left(@psFirstName, charindex(' ', @psFirstName + ' '))
		End
	End

	If @psPrepareFor = 'S'
	Begin
		-- 7102 - @psName <space> First word of @psFirstName
		If @pnNameStyle = 7102
		Begin
			If @psName is not null
			Begin
				Set @sResult = @psName + space(1)
			End

			If (@psFirstName is not null and @psFirstName <> '')
			Begin

				Set @sResult = @sResult + left(@psFirstName, charindex(' ', @psFirstName + ' '))
			End
 		End
		Else -- 7101 - First word of @psFirstName <space> @psName
		Begin
			If (@psFirstName is not null and @psFirstName <> '')
			Begin
				If(charindex(' ', @psFirstName)=0)
				Begin
					Set @psFirstName = @psFirstName +' ';
				End
				Set @sResult = left(@psFirstName, charindex(' ', @psFirstName));
			End

			If @psName is not null
			Begin
				Set @sResult = @sResult + @psName
			End
		End
	End
		
	return rtrim(@sResult)
End
GO

grant execute on dbo.fn_PrepareName to public
go
