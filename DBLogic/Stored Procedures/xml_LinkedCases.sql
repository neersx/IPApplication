-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_LinkedCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_LinkedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_LinkedCases.'
	drop procedure dbo.xml_LinkedCases
	print '**** Creating procedure dbo.xml_LinkedCases...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create PROCEDURE dbo.xml_LinkedCases
	@psCaseIds			nvarchar(2000)		-- the comma separated CaseIds whose data is being retrieved
AS

-- PROCEDURE :	xml_LinkedCases
-- VERSION :	2.3.0
-- DESCRIPTION:	Collects info for the case to be displayed in the Multi Cases tab

-- Date		MODIFICATION HISTORY
-- ====         ===================
-- February 2003 Anna van der Aa   Procedure created
-- 19/03/03	IB	
--		7975	Used LEFT JOIN for CASECATEGORY table
-- 16/04/03	IB
--		7975	Now returns STATUS.INTERNALDESC and APPLICATIONBASIS.BASISDESCRIPTION

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode	int
declare	@sSQLString	nvarchar(4000)

set @ErrorCode = 0
begin
	set @sSQLString="
		SELECT 1 AS TAG, 
		   	NULL AS PARENT,
			CASES.IRN AS [Case!1!IRN!element],
			COUNTRY.COUNTRY AS [Case!1!Country!element],
			PROPERTYTYPE.PROPERTYNAME AS [Case!1!PropertyType!element],
			CASETYPE.CASETYPEDESC AS [Case!1!CaseType!element],
			STATUS.INTERNALDESC AS [Case!1!Status!element],
			TITLE AS [Case!1!Title!element],
			CASECATEGORYDESC AS [Case!1!Category!element],
			SUBTYPEDESC AS [Case!1!SubType!element],
			BASISDESCRIPTION AS [Case!1!Basis!element],
			null as [OfficialNumbers!2!OfficialNumber!element],
			null AS [OfficialNumbers!2!Description],
			null AS [OfficialNumbers!2!Number]
		FROM CASES 
		JOIN COUNTRY ON CASES.COUNTRYCODE = COUNTRY.COUNTRYCODE
		JOIN PROPERTYTYPE ON CASES.PROPERTYTYPE = PROPERTYTYPE.PROPERTYTYPE
		JOIN CASETYPE ON CASES.CASETYPE = CASETYPE.CASETYPE
		LEFT JOIN STATUS ON CASES.STATUSCODE = STATUS.STATUSCODE
		LEFT JOIN CASECATEGORY ON CASES.CASETYPE = CASECATEGORY.CASETYPE 
			AND CASES.CASECATEGORY = CASECATEGORY.CASECATEGORY
		LEFT JOIN SUBTYPE ON CASES.SUBTYPE = SUBTYPE.SUBTYPE
		LEFT JOIN PROPERTY ON CASES.CASEID = PROPERTY.CASEID
		LEFT JOIN APPLICATIONBASIS ON APPLICATIONBASIS.BASIS = PROPERTY.BASIS
		WHERE CASES.CASEID in (" + @psCaseIds + ")
		UNION
		SELECT 2 AS TAG, 
			1 AS PARENT,
			CASES.IRN ,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			DESCRIPTION, 
			OFFICIALNUMBER   
		FROM  CASES
		JOIN OFFICIALNUMBERS ON CASES.CASEID = OFFICIALNUMBERS.CASEID
		JOIN NUMBERTYPES ON OFFICIALNUMBERS.NUMBERTYPE = NUMBERTYPES.NUMBERTYPE
		AND OFFICIALNUMBERS.CASEID in (" + @psCaseIds + ")
		ORDER BY [Case!1!IRN!element],1,2,[OfficialNumbers!2!Description]
		FOR XML EXPLICIT"
	Exec(@sSQLString)
	set @ErrorCode=@@error
end
RETURN @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.xml_LinkedCases to public
go
