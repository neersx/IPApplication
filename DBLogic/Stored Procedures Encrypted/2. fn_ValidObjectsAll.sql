-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ValidObjectsAll
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ValidObjectsAll') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ValidObjectsAll.'
	drop function dbo.fn_ValidObjectsAll
	print '**** Creating function dbo.fn_ValidObjectsAll...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_ValidObjectsAll
(
	@psObjectTable	nvarchar(30)	= null,	-- An optional parameter to filter the list of objects to those 
						-- for a particular object table; e.g. TASK.
	@pdtToday	datetime
)
RETURNS  TABLE
 
With ENCRYPTION
AS
-- FUNCTION :	fn_ValidObjectsAll
-- VERSION :	2
-- DESCRIPTION:	Extracts a list of distinct licensed objects from the encrypted ValidObject database table
--		for all users of the system.
--		The function itself is encrypted.
--
--		If information is required for a single user, use fn_ValidObjects() instead.

-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Aug 2006	JEK	RFC3828	1	Function created
-- 01 Jul 2014  MF	R34759  2	Performance improvement by restructure of code to handle
--					external and internal users in separate SELECT

Return
	-------------------------
	-- Unlimited User License
	-------------------------
	Select  UI.IDENTITYID						as IdentityKey,
		case TYPE
			 when 10
				then N'MODULE'
			 when 20
				then N'TASK'
			 when 30
				then N'DATATOPIC'
			 end						as ObjectTable,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10) 	as ObjectIntegerKey,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30)	as ObjectStringKey
	from dbo.fn_Modules(@pdtToday) L
	join USERIDENTITY UI	on (UI.ISVALIDWORKBENCH = 1)	
	-- Locate web parts/tasks/subjects available to users
	join VALIDOBJECT VO	on (SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 1, 3) = L.MODULEID
	                        and (VO.TYPE =	case (@psObjectTable)
			                                 when N'MODULE'
				                                then 10
			                                 when N'TASK'
				                                then 20
			                                 when N'DATATOPIC'
				                                then 30
						end
		                                or @psObjectTable is null)
				and (VO.TYPE in (10,20) or (VO.TYPE = 30 
							-- If a data topic (subject), ensure site has access to any prerequisite license
                                                        and exists 
                                                        (Select VO2.ObjectIntegerKey 
                                                         from dbo.fn_ValidObjects(null, 'DATATOPICREQUIRES', @pdtToday) VO2
                                                         where VO2.ObjectIntegerKey = SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10)))))

	where	L.PRICINGMODEL=1
	and  ((UI.ISEXTERNALUSER = 0 and L.INTERNALUSE = 1) or (UI.ISEXTERNALUSER = 1 and L.EXTERNALUSE = 1))
	UNION
	-------------------------------------
	-- Explicitly licensed internal users
	-------------------------------------
	Select  UI.IDENTITYID						as IdentityKey,
		case TYPE
			 when 10
				then N'MODULE'
			 when 20
				then N'TASK'
			 when 30
				then N'DATATOPIC'
			 end						as ObjectTable,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10) 	as ObjectIntegerKey,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30)	as ObjectStringKey
	from dbo.fn_Modules(@pdtToday) L
	join USERIDENTITY UI	on (UI.ISVALIDWORKBENCH = 1)	
	-- Locate web parts/tasks/subjects available to users
	join VALIDOBJECT VO	on (SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 1, 3) = L.MODULEID
	                        and (VO.TYPE =	case (@psObjectTable)
			                                 when N'MODULE'
				                                then 10
			                                 when N'TASK'
				                                then 20
			                                 when N'DATATOPIC'
				                                then 30
						end
		                                or @psObjectTable is null)
				and (VO.TYPE in (10,20) or (VO.TYPE = 30 
							-- If a data topic (subject), ensure site has access to any prerequisite license
                                                        and exists 
                                                        (Select VO2.ObjectIntegerKey 
                                                         from dbo.fn_ValidObjects(null, 'DATATOPICREQUIRES', @pdtToday) VO2
                                                         where VO2.ObjectIntegerKey = SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10)))))
	-- Internal users are licensed directly
	join LICENSEDUSER LU		on (LU.MODULEID = L.MODULEID
					AND LU.USERIDENTITYID = UI.IDENTITYID)	
	where L.MODULEUSERS > 0 
	AND   L.INTERNALUSE = 1
	and  UI.ISEXTERNALUSER = 0	
	UNION
	-------------------------------------
	-- Explicitly licensed external users
	-------------------------------------
	Select  UI.IDENTITYID						as IdentityKey,
		case TYPE
			 when 10
				then N'MODULE'
			 when 20
				then N'TASK'
			 when 30
				then N'DATATOPIC'
			 end						as ObjectTable,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10) 	as ObjectIntegerKey,
		SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30)	as ObjectStringKey
	from dbo.fn_Modules(@pdtToday) L
	join USERIDENTITY UI	on (UI.ISVALIDWORKBENCH = 1)	
	-- Locate web parts/tasks/subjects available to users
	join VALIDOBJECT VO	on (SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 1, 3) = L.MODULEID
	                        and (VO.TYPE =	case (@psObjectTable)
			                                 when N'MODULE'
				                                then 10
			                                 when N'TASK'
				                                then 20
			                                 when N'DATATOPIC'
				                                then 30
						end
		                                or @psObjectTable is null)
				and (VO.TYPE in (10,20) or (VO.TYPE = 30 
							-- If a data topic (subject), ensure site has access to any prerequisite license
                                                        and exists 
                                                        (Select VO2.ObjectIntegerKey 
                                                         from dbo.fn_ValidObjects(null, 'DATATOPICREQUIRES', @pdtToday) VO2
                                                         where VO2.ObjectIntegerKey = SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10)))))

	-- External users are licensed via their access account.
	join LICENSEDACCOUNT LA		on (LA.MODULEID = L.MODULEID
						and LA.ACCOUNTID = UI.ACCOUNTID)	
	where	UI.ISEXTERNALUSER = 1 
	and     L.EXTERNALUSE = 1
	group by UI.IDENTITYID, TYPE, SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 4, 10), SUBSTRING(dbo.fn_Clarify(VO.OBJECTDATA), 15, 30)

GO

grant REFERENCES, SELECT on dbo.fn_ValidObjectsAll to public
GO
