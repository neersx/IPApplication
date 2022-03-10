-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ModuleDetails 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ModuleDetails ') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ModuleDetails .'
	drop function dbo.fn_ModuleDetails 
	print '**** Creating function dbo.fn_ModuleDetails ...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_ModuleDetails()
RETURNS  TABLE
 
With ENCRYPTION
AS
-- FUNCTION :	fn_ModuleDetails 
-- VERSION :	3
-- DESCRIPTION:	Returns all the information about the license

-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Nov 2004	TM	RFC869	1	Function created
-- 18 Nov 2004	TM	RFC869	2	Add 'N' prefix to the 'LICENSEMODULE'.
-- 14 May 2005	JEK	RFC2594		Replace fn_Clarify() with fn_Clarify()
--			RFC2549	3	Remove checksum logic on Type.
Return
	
	Select  SUBSTRING(dbo.fn_Clarify(OBJECTDATA), 1, 3) 	as ModuleID,
		SUBSTRING(dbo.fn_Clarify(OBJECTDATA), 4, 1) 	as ExternalUse,
		SUBSTRING(dbo.fn_Clarify(OBJECTDATA), 5, 1) 	as InternalUse,
		SUBSTRING(dbo.fn_Clarify(OBJECTDATA), 6, 10) 	as ModuleFlag
	from VALIDOBJECT
	where TYPE = 40
GO

grant REFERENCES, SELECT on dbo.fn_ModuleDetails  to public
GO
