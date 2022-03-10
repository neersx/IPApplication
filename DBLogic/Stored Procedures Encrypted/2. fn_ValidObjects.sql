-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ValidObjects
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ValidObjects') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ValidObjects.'
	drop function dbo.fn_ValidObjects
	print '**** Creating function dbo.fn_ValidObjects...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_ValidObjects
(
	@pnIdentityKey	int,		-- The user for whom licenses are to be checked. If not supplied, 
					-- the firm-wide licenses are checked.
	@psObjectTable	nvarchar(30),	-- A mandatory parameter to filter the list of objects to those 
					-- for a particular object table; e.g. TASK.
	@pdtToday	datetime
)
RETURNS  TABLE
 
With ENCRYPTION
AS
-- FUNCTION :	fn_ValidObjects
-- VERSION :	6
-- DESCRIPTION:	Extracts a list of distinct licensed objects from the encrypted ValidObject database table.
--		The function itself is encrypted.


-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2004	TM	RFC869	1	Function created
-- 18 Nov 2004	TM	RFC869	2	If the ModuleId = 999 the object is always considered valid.
-- 01 Dec 2004	JEK	RFC2079	3	Add InternalUse and ExternalUse output flags
-- 14 May 2005	JEK	RFC2594		Replace fn_Decrypt() with fn_Clarify()
--			RFC2549	4	Remove checksum on TYPE.
-- 02 Sep 2005 	TM	RFC2952	5	Update the comments.
-- 12 Jul 2006	SW	RFC3828	6	Add new param @pdtToday

-- NOTE: If the function is changed, the corresponding fn_ValidObjectsName function needs to be changed.

Return
	
	Select  SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10) 	as ObjectIntegerKey,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30)	as ObjectStringKey,
		cast( sum(LM.INTERNALUSE) as bit) 			as InternalUse,
		cast( sum(LM.EXTERNALUSE) as bit) 			as ExternalUse
	from VALIDOBJECT VO
	left join fn_LicensedModules(@pnIdentityKey, @pdtToday) LM		
			on (LM.MODULEID = SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 1, 3))
	where TYPE = case upper(@psObjectTable)
			 when N'LICENSEMODULE'
				then 40
			 when N'MODULE'
				then 10
			 when N'TASK'
				then 20
			 when N'DATATOPIC'
				then 30
			 when N'DATATOPICREQUIRES'
				then 35
			 end
	and (LM.MODULEID is not null
	or   SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 1, 3) = 999)
	group by SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10), SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30)
	
GO

grant REFERENCES, SELECT on dbo.fn_ValidObjects to public
GO
