-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ScreenCriteriaNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ScreenCriteriaNameTypes') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fn_ScreenCriteriaNameTypes.'
	Drop function [dbo].[fn_ScreenCriteriaNameTypes]
End
Print '**** Creating Function dbo.fn_ScreenCriteriaNameTypes...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_ScreenCriteriaNameTypes
(
	@pnScreenCriteriaKey int
	
)
RETURNS TABLE

AS
-- FUNCTION:	fn_ScreenCriteriaNameTypes
-- VERSION :	5
-- SCOPE:	CPAStart
-- DESCRIPTION:	A table of distinct Name Type keys that are referenced 
--		by screen control rules matching the supplied parameters.
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	-----------------------------------------------------------------------------------
-- 09 MAY 2006	SW	1	Function created
-- 03 NOV 2006	DR	2	SQA12300 - Add EDE Case Review names screen (frmEDECaseResolutionNames).
-- 18 Jul 2008	AT	3	Filter additional internal names types site control from CRM.
-- 15 Jan 2009	AT	4	17136 Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 18 Mar 2009	JC	5	RFC7756 Remove UPPER in CONTROLID

-- populate the table with distinct name types 
RETURN
	
	Select 	distinct NAMETYPE 
	from 	SCREENCONTROL 
	where 	SCREENNAME = 'frmNames'
	and	CRITERIANO = @pnScreenCriteriaKey
	union
	Select 	distinct G.NAMETYPE
	from	SCREENCONTROL S
	join GROUPMEMBERS G	on (G.NAMEGROUP = S.NAMEGROUP)
	where 	S.SCREENNAME = 'frmNameGrp'
	and	CRITERIANO = @pnScreenCriteriaKey
	union
	-- Staff field on instructor tab is not hidden
	Select 'EMP'
	from 	SCREENCONTROL S
	where 	S.SCREENNAME = 'frmInstructor'
	and	S.CRITERIANO = @pnScreenCriteriaKey
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
	Select 'SIG'
	from 	SCREENCONTROL S
	where 	S.SCREENNAME = 'frmInstructor'
	and	S.CRITERIANO = @pnScreenCriteriaKey
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
	Select 'I'
	from 	SCREENCONTROL S
	where 	S.SCREENNAME = 'frmInstructor'
	and	S.CRITERIANO = @pnScreenCriteriaKey
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
	Select 'A'
	from 	SCREENCONTROL S
	where 	S.SCREENNAME = 'frmInstructor'
	and	S.CRITERIANO = @pnScreenCriteriaKey
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
	Select	S.COLCHARACTER
	from	SITECONTROL S
	join 	NAMETYPE N ON (N.NAMETYPE = S.COLCHARACTER)
	where	S.CONTROLID = 'Additional Internal Staff'
	and not exists (select 1 from CRITERIA 
			where CRITERIANO = @pnScreenCriteriaKey 
			and CASETYPE in (SELECT CASETYPE FROM CASETYPE WHERE CRMONLY = 1))
	union
	-- 12300 - Add EDE Case Review names
	Select 	distinct G.NAMETYPE
	from	SCREENCONTROL S
	join	GROUPMEMBERS G	on (G.NAMEGROUP = S.NAMEGROUP)
	where 	S.SCREENNAME = 'frmEDECaseResolutionNames'
	and	CRITERIANO = @pnScreenCriteriaKey

go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ScreenCriteriaNameTypes to public
go