-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListGlobalNameChangeCasesWithBillPblm
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListGlobalNameChangeCasesWithBillPblm]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListGlobalNameChangeCasesWithBillPblm.'
	Drop procedure [dbo].[csw_ListGlobalNameChangeCasesWithBillPblm]
End
Print '**** Creating Stored Procedure dbo.csw_ListGlobalNameChangeCasesWithBillPblm...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_ListGlobalNameChangeCasesWithBillPblm]
(	
	@pnRowCount			int		= null output,	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@ptXMLFilterCriteria		nvarchar(max),	-- Mandatory
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	csw_ListGlobalNameChangeCasesWithBillPblm
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns list of Global Name Change Cases with Bill Problem

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 NOV 2008	MS	RFC5698	1	Procedure created
-- 24 Oct 2011	ASH	R11460  2	Cast integer columns as nvarchar(11) data type.
-- 07 Jun 2017	MF	71664	3	Improve performance of query pulling out the OPENXML from the main query.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @tbCases	table (CASEID	int not null)

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(max)
Declare @idoc 		int 	-- Declare a document handle of the XML document 
				-- in memory that is created by sp_xml_preparedocument		

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode=0
Begin
	-----------------------------------------------------
	-- Create an XML document in memory and then retrieve
	-- the information from the rowset using OPENXML
	-----------------------------------------------------
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	-------------------------------------------------------
	-- Load the CaseIds from the XML into a table variable.
	-- This is to resolve a performance issue with the 
	-- next SELELCT
	-------------------------------------------------------
	insert into @tbCases (CASEID)
	select distinct T.CaseKey
	from OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria/SelectedCasesGroup/CaseKey',2) WITH (CaseKey	int 'text()') T

	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin	
	------------------------------------
	-- List of the Cases where a NameType that requires Billing Percentage
	-- does not have a total percentage of 100
	------------------------------------
	;with CTE_CaseNameTotal (CASEID, NAMETYPE, TotalPercentage)
	as (	select CASEID, NAMETYPE, SUM(isnull(BILLPERCENTAGE,0))
		from CASENAME
		where EXPIRYDATE is null or EXPIRYDATE>GETDATE()
		group by CASEID, NAMETYPE)
	select distinct CAST(C.CASEID as nvarchar(11)) + '^' + NT.NAMETYPE as 'RowKey',  
	C.CASEID		as 'CaseKey', 
	C.IRN			as CaseReference, 
	NT.DESCRIPTION		as 'NameType', 
	CN1.TotalPercentage	as 'TotalPercentage', 
	C.CURRENTOFFICIALNO	as 'OfficialNumber', 
	C.TITLE			as 'CaseTitle', 
	CT.CASETYPEDESC		as 'CaseTypeDesc',  
	CY.COUNTRY		as 'Country', 
	PROPERTYNAME		as 'PropertyName'
	from @tbCases T
	join CASES C		on ( C.CASEID=T.CASEID)
	join CASENAME CN	on (CN.CASEID=C.CASEID
				and(CN.EXPIRYDATE is null OR CN.EXPIRYDATE>getdate()))
	join CTE_CaseNameTotal CN1 
				on (CN1.CASEID  =CN.CASEID
				and CN1.NAMETYPE=CN.NAMETYPE)
	join NAMETYPE NT	on (NT.NAMETYPE =CN.NAMETYPE)
	join CASETYPE CT	on (CT.CASETYPE =C.CASETYPE)
	join COUNTRY  CY	on (CY.COUNTRYCODE=C.COUNTRYCODE)
	join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
		                and VP.COUNTRYCODE=(select min(COUNTRYCODE)
		                                        from VALIDPROPERTY VP1
		                                        where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
		                                        and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	where NT.COLUMNFLAGS&64=64
	and (isnull(CN.BILLPERCENTAGE,0)=0 OR CN1.TotalPercentage<>100)
	order by C.IRN, NT.DESCRIPTION

	Select @pnRowCount = @@Rowcount,
	       @nErrorCode = @@Error

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListGlobalNameChangeCasesWithBillPblm to public
GO

