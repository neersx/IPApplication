-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ScreenCriteriaNameTypesDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ScreenCriteriaNameTypesDetails') and xtype in ('IF','TF'))
begin
	print '**** RFC6732 Drop function dbo.fn_ScreenCriteriaNameTypesDetails.'
	drop function dbo.fn_ScreenCriteriaNameTypesDetails
end
print '**** RFC6732 Creating function dbo.fn_ScreenCriteriaNameTypesDetails...'
print ''
go

set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_ScreenCriteriaNameTypesDetails(@pnScreenCriteriaKey int)			
RETURNS TABLE

-- FUNCTION :	fn_ScreenCriteriaNameTypesDetails
-- VERSION :	1
-- DESCRIPTION:	Returns all of the NameTypes that are associated with a screen control Criteria.
--		If a specific Screen Control Criteria is not supplied then all Criteria name types
--		will be returned.
--		

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Dec 2010	MF	9688	1	Function created
AS
RETURN
	Select 	S.CRITERIANO, NT.NAMETYPEID, NT.NAMETYPE, NT.COLUMNFLAGS, NT.PICKLISTFLAGS 
	from 	SCREENCONTROL S
	join	NAMETYPE NT on (NT.NAMETYPE=S.NAMETYPE)
	where 	S.SCREENNAME = 'frmNames'
	and    (S.CRITERIANO = @pnScreenCriteriaKey or @pnScreenCriteriaKey is null)
	union
	Select 	S.CRITERIANO, NT.NAMETYPEID, NT.NAMETYPE, NT.COLUMNFLAGS, NT.PICKLISTFLAGS 
	from	SCREENCONTROL S
	join	GROUPMEMBERS G	on (G.NAMEGROUP = S.NAMEGROUP)
	join	NAMETYPE NT	on (NT.NAMETYPE = G.NAMETYPE)
	where 	S.SCREENNAME in ('frmNameGrp','frmEDECaseResolutionNames')
	and    (S.CRITERIANO = @pnScreenCriteriaKey or @pnScreenCriteriaKey is null)
	union
	-- Staff field on instructor tab is not hidden
	Select S.CRITERIANO, NT.NAMETYPEID, NT.NAMETYPE, NT.COLUMNFLAGS, NT.PICKLISTFLAGS 
	from 	SCREENCONTROL S
	join	NAMETYPE NT	on (NT.NAMETYPE = 'EMP')
	where 	S.SCREENNAME = 'frmInstructor'
	and    (S.CRITERIANO = @pnScreenCriteriaKey or @pnScreenCriteriaKey is null)
	AND 	(EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfEmpCode' AND
			 -- Not hidden
			 FC.ATTRIBUTES&32=0)
		OR
		NOT EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfEmpCode')
		)
	union
	-- Signatory field on instructor tab is not hidden
	Select S.CRITERIANO, NT.NAMETYPEID, NT.NAMETYPE, NT.COLUMNFLAGS, NT.PICKLISTFLAGS 
	from 	SCREENCONTROL S
	join	NAMETYPE NT	on (NT.NAMETYPE = 'SIG')
	where 	S.SCREENNAME = 'frmInstructor'
	and    (S.CRITERIANO = @pnScreenCriteriaKey or @pnScreenCriteriaKey is null)
	AND 	(EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfSignatoryCode' AND
			 -- Not hidden
			 FC.ATTRIBUTES&32=0)
		OR
		NOT EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfSignatoryCode')
		)
	union
	-- Instructor field on instructor tab is not hidden
	Select S.CRITERIANO, NT.NAMETYPEID, NT.NAMETYPE, NT.COLUMNFLAGS, NT.PICKLISTFLAGS 
	from 	SCREENCONTROL S
	join	NAMETYPE NT	on (NT.NAMETYPE = 'I')
	where 	S.SCREENNAME = 'frmInstructor'
	and    (S.CRITERIANO = @pnScreenCriteriaKey or @pnScreenCriteriaKey is null)
	AND 	(EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfInstrCode' AND
			 -- Not hidden
			 FC.ATTRIBUTES&32=0)
		OR
		NOT EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfInstrCode')
		)
	union
	-- Agent field on instructor tab is not hidden
	Select S.CRITERIANO, NT.NAMETYPEID, NT.NAMETYPE, NT.COLUMNFLAGS, NT.PICKLISTFLAGS 
	from 	SCREENCONTROL S
	join	NAMETYPE NT	on (NT.NAMETYPE = 'A')
	where 	S.SCREENNAME = 'frmInstructor'
	and    (S.CRITERIANO = @pnScreenCriteriaKey or @pnScreenCriteriaKey is null)
	AND 	(EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfAgentCode' AND
			 -- Not hidden
			 FC.ATTRIBUTES&32=0)
		OR
		NOT EXISTS
			(SELECT * FROM FIELDCONTROL FC
			 WHERE S.CRITERIANO = FC.CRITERIANO AND
			 S.SCREENNAME = FC.SCREENNAME AND
			 FC.FIELDNAME = 'dfAgentCode')
		)

	union
	-- Additional internal staff
	Select 	S.CRITERIANO, NT.NAMETYPEID, NT.NAMETYPE, NT.COLUMNFLAGS, NT.PICKLISTFLAGS 
	from 	SCREENCONTROL S
	join	CRITERIA C	on (C.CRITERIANO=S.CRITERIANO)
	join	SITECONTROL SC	on (SC.CONTROLID='Additional Internal Staff')
	join	NAMETYPE NT	on (NT.NAMETYPE=SC.COLCHARACTER)
	where 	S.SCREENNAME = 'frmInstructor'
	and    (S.CRITERIANO = @pnScreenCriteriaKey or @pnScreenCriteriaKey is null)
	and not exists(	select 1 from CASETYPE CT
			where CT.CASETYPE=C.CASETYPE
			and CT.CRMONLY=1)
go


grant REFERENCES, SELECT on dbo.fn_ScreenCriteriaNameTypesDetails to public
go