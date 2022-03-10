-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsInteger
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsInteger') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsInteger.'
	Drop function [dbo].[fn_IsInteger]
	Print '**** Creating Function dbo.fn_IsInteger...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_IsInteger
(
	@psString	nvarchar(max)
)
RETURNS bit

-- PROCEDURE:	fn_IsInteger
-- VERSION :	2
-- DESCRIPTION:	Tests a string to see if it is a valid INTEGER

-- MODIFICATIONS :
-- Date			Who		Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 05 May 2017  MF		71410	1		Function created.
-- 18 Apr 2018	vql		73831	2		Improve check.

AS
Begin
	 return IsNull(
     (select case when charindex('.', @psString) > 0 
                  then case when convert(int, parsename(@psString, 1)) <> 0
                            then 0
                            else 1
                            end
                  else 1
                  end
      where IsNumeric(@psString + 'e0') = 1), 0)
End
go

Grant execute on dbo.fn_IsInteger to public 
go
