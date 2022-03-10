-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCheckDigit
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCheckDigit') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetCheckDigit.'
	drop function dbo.fn_GetCheckDigit
	print '**** Creating function dbo.fn_GetCheckDigit...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function  dbo.fn_GetCheckDigit
(
  @psReferenceString	nvarchar(30)
)
Returns Nchar(1)
-- FUNCTION: fn_GetCheckDigit
-- VERSION: 1
-- SCOPE: CPA.net
-- DESCRIPTION: Returns a single character that is arithmetically related to the supplied Case Reference content
-- MODIFICATIONS :
-- Date  	Who 	Version 	Change
-- ------------ ------- ------- ----------------------------------------------- 
-- 12-Jun-2003  TM 	1 		Function created

as
Begin

Declare @sCheckDigit	Nchar(1)

-- Calculate a distinct and repeatable numeric value for the supplied string and then 
-- convert that to a single character derived as check digit.

Set @sCheckDigit = CAST(CASE 
			    WHEN (CHECKSUM(@psReferenceString)%11 = 0 OR ABS(CHECKSUM(@psReferenceString)%11) = 1 ) THEN 0
			    ELSE (11-ABS(CHECKSUM(@psReferenceString))%11)
     		        END as Nchar(1))
					
Return @sCheckDigit
End	

GO

Grant execute on dbo.fn_GetCheckDigit to public
GO







	



