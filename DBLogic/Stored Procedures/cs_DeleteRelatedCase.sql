-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteRelatedCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_DeleteRelatedCase.'
	drop procedure [dbo].[cs_DeleteRelatedCase]
end
print '**** Creating Stored Procedure dbo.cs_DeleteRelatedCase...'
print ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create  procedure dbo.cs_DeleteRelatedCase
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 
	@pnRelationshipSequence		int = null,
	@psRelationshipKey		varchar(3) = null,
	@psRelationshipDescription	varchar(50) = null,
	@psRelatedCaseKey		varchar(11) = null,
	@psRelatedCaseReference		nvarchar(20) = null,
	@psCountryKey			nvarchar(3) = null,
	@psCountryName			nvarchar(60) = null,
	@psOfficialNumber		nvarchar(36) = null,
	@psPropertyTypeDescription	nvarchar(50) = null,
	@psCaseTypeDescription		nvarchar(50) = null,
	@psStatusDescription		nvarchar(50) = null
)
as
-- VERSION:	6
-- DESCRIPTION:	Deletes a related case row from CaseData dataset.
-- SCOPE:	CPA.net
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 05/08/2002	SF			procedure created
-- 15/11/2002	SF		4	Updated Version Number
-- 12/07/2005	TM	RFC2848	5	Incorrect handling of reciprocal relationships.
-- 25 Nov 2011	ASH	R100640	6	Change the size of Case Key and Related Case key to 11.

begin

	declare @nErrorCode int
	declare @nCaseId int

	set @nCaseId = cast(@psCaseKey as int)
	set @nErrorCode = @@error

	print @nErrorCode

	-- Remove Reciprocal relationship
	if @nErrorCode = 0
	begin
		delete 	RELATEDCASE 
		where	RELATEDCASEID = @nCaseId
		and 	CASEID = @psRelatedCaseKey
		and	RELATIONSHIP in (
				select	RECIPRELATIONSHIP
				from	VALIDRELATIONSHIPS VR, CASES C
				where	C.CASEID = @nCaseId
				and	VR.PROPERTYTYPE = C.PROPERTYTYPE
				and	VR.RELATIONSHIP = @psRelationshipKey
				and	VR.COUNTRYCODE = (	
						select 	min(COUNTRYCODE)
						from	VALIDRELATIONSHIPS VR1
						where	VR1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE)
						and	VR1.PROPERTYTYPE = C.PROPERTYTYPE))

		set @nErrorCode = @@error
	end

	-- Remove Relationship
	if @nErrorCode = 0
	begin
		delete	RELATEDCASE
		where	CASEID = @nCaseId
		and	RELATIONSHIPNO = @pnRelationshipSequence

		set @nErrorCode = @@error
	end
	return @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_DeleteRelatedCase to public
go
