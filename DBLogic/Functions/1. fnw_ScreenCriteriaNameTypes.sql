-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fnw_ScreenCriteriaNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fnw_ScreenCriteriaNameTypes') and xtype='IF')
Begin
	Print '**** Drop Function dbo.fnw_ScreenCriteriaNameTypes.'
	Drop function [dbo].[fnw_ScreenCriteriaNameTypes]
End
Print '**** Creating Function dbo.fnw_ScreenCriteriaNameTypes...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fnw_ScreenCriteriaNameTypes
(
	@pnScreenCriteriaKey int
	
)
RETURNS TABLE

AS
-- FUNCTION:	fnw_ScreenCriteriaNameTypes
-- VERSION :	7
-- SCOPE:	CPAStart
-- DESCRIPTION:	A table of distinct Name Type keys that are not referenced 
--		by screen and field control rules.
--
-- MODIFICATIONS :
-- Date		Who	No.		Version	Change
-- ------------	-------	-----------	-------	----------------------------------------------- 
-- 16 MAR 2009	JC	RFC7362		1	Function created
-- 27 Jul 2009	KR	RFC8239		2	Exclude Name Types with COLUMNFLAGS 0
-- 15 Jun 2012	LP	R12391		3	Do not exclude Staff Name Types belonging to Staff Names topic
--						i.e. Single-Name Staff Member Name Type with no details displayed
-- 02 Jul 2013	AT	RFC13607	4	Fix Staff Name Type filtering to allow for null rows (assume null means not hidden).
-- 22 Jan 2014  MS      R100845         5       Exclude Name Type whose FILTERNAME and FILTERVALUE is null and ISHIDDEN is 1
-- 02 Nov 2016  vql     R65086		6       New name types not hidden in screen designer but unavailable to add name (DR-23658)
-- 09 Oct 2019	DL		DR-52871 7	Case errors after updating database compatibility level
      
-- populate the table with distinct name types 
RETURN
	
	SELECT NT.NAMETYPE
	FROM NAMETYPE NT
	WHERE NT.NAMETYPE NOT IN (
		-- Return all NAMETYPEs for Single Name and Multiples Name topics
		SELECT TC.FILTERVALUE FROM TOPICCONTROL TC
			JOIN WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND WC.CRITERIANO=@pnScreenCriteriaKey AND WC.WINDOWNAME='CaseNameMaintenance')
			WHERE TC.FILTERNAME='NameTypeCode'
			  AND TC.FILTERVALUE IS NOT NULL
			  AND TC.ISHIDDEN=1 
		UNION
		-- Return all NAMETYPEs for Staff Topic
		SELECT NT.NAMETYPE 
			FROM TOPICCONTROL TC
			JOIN NAMETYPE NT on (NT.NAMETYPEID = RIGHT(TC.TOPICNAME, (LEN(TC.TOPICNAME) - CHARINDEX('_', TC.TOPICNAME))))
			JOIN WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND WC.CRITERIANO=@pnScreenCriteriaKey AND WC.WINDOWNAME='CaseNameMaintenance')
			WHERE TC.FILTERNAME IS NULL
			  AND TC.FILTERVALUE IS NULL
			  AND TC.ISHIDDEN=1 
			  AND TC.TOPICNAME <> 'Case_StaffTopic'
			  AND (NT.PICKLISTFLAGS&2=0 OR NT.COLUMNFLAGS<>0 OR NT.MAXIMUMALLOWED <> 1)
			  AND ISNUMERIC(RIGHT(TC.TOPICNAME, (LEN(TC.TOPICNAME) - CHARINDEX('_', TC.TOPICNAME))))=1		-- DR-52871 - filter out non numberic entries
		UNION
		-- Return name types that have been hidden
		SELECT EC.FILTERVALUE FROM ELEMENTCONTROL EC
			JOIN TOPICCONTROL TC on (EC.TOPICCONTROLNO = TC.TOPICCONTROLNO) 
			JOIN WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND WC.CRITERIANO=@pnScreenCriteriaKey AND WC.WINDOWNAME='CaseNameMaintenance')
			WHERE EC.FILTERNAME='NameTypeCode'
			  AND EC.FILTERVALUE IS NOT NULL
			  AND EC.ISHIDDEN=1 
		UNION
		-- Return all NAMETYPEs if the Staff Topic is hidden
		SELECT N.NAMETYPE 
			FROM NAMETYPE N
			JOIN WINDOWCONTROL WC on (WC.CRITERIANO=@pnScreenCriteriaKey AND WC.WINDOWNAME='CaseNameMaintenance')
			JOIN TOPICCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND TC.TOPICNAME = 'Case_StaffTopic' AND TC.ISHIDDEN=1)
			WHERE Cast(N.COLUMNFLAGS & 4 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 1 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 2 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 16 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 32 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 8 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 128 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 64 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 512 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 1024 as bit) = 0
			  AND Cast(N.COLUMNFLAGS & 2048 as bit) = 0
			  AND Cast(N.PICKLISTFLAGS & 2 as bit) = 1
		-- Do not exclude Staff Name Types belonging to Staff Names topic
		EXCEPT
		SELECT TC.FILTERVALUE FROM TOPICCONTROL TC
			JOIN WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND WC.CRITERIANO=@pnScreenCriteriaKey AND WC.WINDOWNAME='CaseNameMaintenance')
			WHERE TC.FILTERNAME='NameTypeCode'
			  AND TC.FILTERVALUE IN (SELECT NTX.NAMETYPE from NAMETYPE NTX 
							where NTX.NAMETYPE = TC.FILTERVALUE 
							AND NTX.PICKLISTFLAGS&2=2 
							AND NTX.COLUMNFLAGS=0 
							AND NTX.MAXIMUMALLOWED = 1)
			AND NOT EXISTS (SELECT 1 from TOPICCONTROL where WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND TOPICNAME = 'Case_StaffTopic' and ISHIDDEN = 1)	
		)
	AND NT.COLUMNFLAGS is not null
	

go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fnw_ScreenCriteriaNameTypes to public
go