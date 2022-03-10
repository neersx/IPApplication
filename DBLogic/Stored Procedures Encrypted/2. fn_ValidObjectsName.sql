-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ValidObjectsName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ValidObjectsName') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ValidObjectsName.'
	drop function dbo.fn_ValidObjectsName
	print '**** Creating function dbo.fn_ValidObjectsName...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_ValidObjectsName
(
	@pnNameKey	int,		-- The name for whom the user licenses are to be checked.
	@psObjectTable	nvarchar(30),	-- A mandatory parameter to filter the list of objects to those 
					-- for a particular object table; e.g. TASK.
	@pdtToday	datetime
)
RETURNS  TABLE
 
With ENCRYPTION
AS
-- FUNCTION :	fn_ValidObjectsName
-- VERSION :	2
-- DESCRIPTION:	Extracts a list of list of distinct licensed objects for the supplied name.


-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Sep 2005	TM	RFC2952	1	Function created
-- 12 Jul 2006	SW	RFC3828	2	Add new param @pdtToday

-- NOTE: If the function is changed, the corresponding fn_ValidObjects function needs to be changed.

Return
	
	Select  LM.IDENTITYID						as IdentityKey,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10) 	as ObjectIntegerKey,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30)	as ObjectStringKey,
		cast( sum(LM.INTERNALUSE) as bit) 			as InternalUse,
		cast( sum(LM.EXTERNALUSE) as bit) 			as ExternalUse
	from VALIDOBJECT VO
	left join fn_LicensedModulesName(@pnNameKey, @pdtToday) LM		
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
	group by SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10), SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30), LM.IDENTITYID
	
GO

grant REFERENCES, SELECT on dbo.fn_ValidObjectsName to public
GO
