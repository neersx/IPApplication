----------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListNameSupport
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListNameSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListNameSupport'
	drop procedure [dbo].[na_ListNameSupport]
	Print '**** Creating Stored Procedure dbo.na_ListNameSupport...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  PROCEDURE dbo.na_ListNameSupport
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null
)
-- VERSION:	11
-- DESCRIPTION:	Return several tables Supporting Name Maintenance operations
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	6	Update Version Number
-- 18 Nov 2002	SF	7	Remove Country Option
-- 14 JUL 2003	TM	8	RFC69 - State pick list shows the wrong Code
-- 08 Nov 2004	TM	9	RFC1910 Modify the Country.PostalName in the state result set for CountryName.
-- 08 Nov 2004	TM	10	RFC1910 Change the PostalName column name back to CountryName.
-- 15 Apr 2013	DV	11	R13270  Increase the length of nvarchar to 11 when casting or declaring integer

as
	-- set server options
	set NOCOUNT on

	-- declare variables
	declare	@ErrorCode	int

	-- initialise variables
	set @ErrorCode=0

--	SELECT	COUNTRYCODE As CountryKey, COUNTRY As CountryName, COUNTRYADJECTIVE As NationalityDescription
--	FROM	COUNTRY
--	ORDER BY	COUNTRY
	
	SELECT TITLE As TitleKey, TITLE As TitleDescription
	FROM TITLES
	ORDER BY TITLE
	
	SELECT STATE.STATE As StateKey, STATE.STATENAME As StateName, STATE.STATE As StateCode,
	       STATE.COUNTRYCODE As CountryKey, COUNTRY.POSTALNAME As CountryName
	FROM STATE
	left join COUNTRY on (COUNTRY.COUNTRYCODE = STATE.COUNTRYCODE)
	
	SELECT Cast(TABLECODE As Varchar(11)) As "Key",
	       DESCRIPTION As Description
	FROM TABLECODES As Valediction
	WHERE TABLETYPE=40

	SELECT Cast(TABLECODE As Varchar(11)) As "Key",
	       DESCRIPTION As Description
	FROM TABLECODES As EntitySize
	WHERE TABLETYPE=26

	SELECT Cast(TABLECODE As Varchar(11)) As "Key",
	       DESCRIPTION As Description
	FROM TABLECODES As AnalysisCode1
	WHERE TABLETYPE=-1

	SELECT Cast(TABLECODE As Varchar(11)) As "Key",
	       DESCRIPTION As Description
	FROM TABLECODES As AnalysisCode2
	WHERE TABLETYPE=-2

	SELECT TOP 50 Cast(NAMENO As Varchar(11)) "NameKey", NAME "DisplayName", NAMECODE "NameCode"
	FROM NAME	As Name
	
	select @ErrorCode=@@Error

	return @ErrorCode


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT EXEC ON dbo.na_ListNameSupport TO PUBLIC
GO
