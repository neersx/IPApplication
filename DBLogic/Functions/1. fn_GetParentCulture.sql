-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetParentCulture
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetParentCulture') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetParentCulture'
	Drop function [dbo].[fn_GetParentCulture]
End
Print '**** Creating Function dbo.fn_GetParentCulture...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetParentCulture
(
	@psCulture	nvarchar(10)
) 

RETURNS nvarchar(10)
AS
-- Function :	fn_GetParentCulture
-- VERSION :	1
-- DESCRIPTION:	Return the (neutral) parent culture for the supplied Culture; i.e.
--		the language without the region portion.
--		If the culture is already a parent cutlure, returns null.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Sep 2004	JEK	RFC1695	1	Function created

Begin

declare @sParentCulture nvarchar(10)

-- Cultures are generally formatted as ll-rr
-- where ll is the two character language identifier and rr is the region identifier.
-- However, there are some exceptions where the first two characters does not
-- identify the parent.

set @psCulture = upper(@psCulture)

select @sParentCulture = 
	case	@psCulture
	when 	'ZH-HK' 	then 'ZH-CHT' 	-- Traditional Chinese
	when 	'ZH-TW' 	then 'ZH-CHT'
	when 	'ZH-MO' 	then 'ZH-CHS' 	-- Simplified Chinese
	when 	'ZH-CN' 	then 'ZH-CHS'
	when 	'ZH-SG' 	then 'ZH-CHS'
	when	'ZH-CHT'	then null
	when	'ZH-CHS'	then null
	when	'NB-NO'		then 'NO'	-- Norwegian
	when	'NN-NO'		then 'NO'
	else 	case when patindex('%-%',@psCulture)>0
		then substring(@psCulture, 1, patindex('%-%',@psCulture)-1)
		end
	end
	
return @sParentCulture

End
GO

grant execute on dbo.fn_GetParentCulture to public
go
