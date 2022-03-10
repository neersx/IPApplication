-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_DeleteCase.'
	Drop procedure [dbo].[cs_DeleteCase]
End
Print '**** Creating Stored Procedure dbo.cs_DeleteCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_DeleteCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psCaseKey			nvarchar(11)	-- Mandatory
)
as
-- PROCEDURE :	cs_DeleteCase
-- VERSION :	11
-- DESCRIPTION:	See CaseData.doc 
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16/07/2002	SF			Procedure created
-- 23 Oct 2002	JB		4	Implemented row level security 
-- 25 Oct 2002	JB		5	Now using cs_GetSecurityForCase for Row level security
-- 08 Nov 2002	JEK		6	Delete Case before Family.
-- 19 Nov 2002	SF		9	Delete CostTrackLine before Case
-- 10 Mar 2003	JEK	RFC82	10	Localise stored procedure errors.
-- 25 Nov 2011	ASH	R100640	11	Change the size of Case Key and Related Case key to 11.

SET CONCAT_NULL_YIELDS_NULL OFF		-- just to make sure!

Declare @nErrorCode 		int
Declare @sCaseFamilyReference 	varchar(20)
Declare @nCaseKey 		int
Declare @bHasDeleteRights	bit
declare @sAlertXML 		nvarchar(400)
Set @nErrorCode = 0
Set @nCaseKey = CAST(@psCaseKey as int)

-- -------------------
-- Row level security
-- -------------------
-- Row level security
If @nErrorCode = 0
Begin
	Exec @nErrorCode = cs_GetSecurityForCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnCaseKey = @nCaseKey,
		@pbCanDelete = @bHasDeleteRights output

	If @nErrorCode = 0 and @bHasDeleteRights = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS4', 'User has insufficient security to delete this case.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End


if @nErrorCode = 0 
begin
	select 	@sCaseFamilyReference = FAMILY
	from	CASES
	where 	CASEID = @nCaseKey

	set @nErrorCode = @@ERROR
end

if @nErrorCode = 0
begin
	delete
	from COSTTRACKLINE
	where 	CASEID = @nCaseKey

	set @nErrorCode = @@ERROR
end

if @nErrorCode = 0
begin
	delete 
	from	CASES
	where 	CASEID = @nCaseKey

	set @nErrorCode = @@ERROR
end

if @nErrorCode = 0 and @sCaseFamilyReference is not null
begin
	If not exists (select * from CASES where FAMILY = @sCaseFamilyReference)
	begin
		delete 
		from	CASEFAMILY
		where	FAMILY = @sCaseFamilyReference
	
		set @nErrorCode = @@ERROR
	end
end

RETURN @nErrorCode
GO

Grant execute on dbo.cs_DeleteCase to public
GO
