-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_DisplayBoolean
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_DisplayBoolean]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop function dbo.fn_DisplayBoolean.'
	drop function [dbo].[fn_DisplayBoolean]
end
print '**** Creating function dbo.fn_DisplayBoolean...'
print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create Function dbo.fn_DisplayBoolean
			(
			@pbBooleanValue		bit,
			@psCulture		nvarchar(10),	-- Not yet implemented
			@pnResultFormat		tinyint		-- 0=Yes/No; 1=On/Off
			)
Returns nvarchar(30)
as
-- FUNCTION :	fn_DisplayBoolean
-- VERSION :	2
-- DESCRIPTION:	This function accepts a boolean value of 0, 1 or null and returns a string for 
--		display purposes. The @psCulture has been provided for future modification to allow
--		language translation

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 02 Jun 2004	MF		1	Function created
-- 07 Mar 2011	MF	10285	2	If the value of the Boolean is NULL then return NULL.

Begin
	declare @sTransformedString	nvarchar(30)

	If @pnResultFormat=0
	Begin
		If @pbBooleanValue=1
			Set @sTransformedString='Yes'
		Else
		If @pbBooleanValue=0
			Set @sTransformedString='No'
	End
	Else Begin
		If @pbBooleanValue=1
			Set @sTransformedString='On'
		Else
		If @pbBooleanValue=0
			Set @sTransformedString='Off'
	End
	
	Return @sTransformedString
End
go

grant execute on dbo.fn_DisplayBoolean to public
GO
