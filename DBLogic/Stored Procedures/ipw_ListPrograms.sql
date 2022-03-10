-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListPrograms
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListPrograms]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListPrograms.'
	Drop procedure [dbo].[ipw_ListPrograms]
End
Print '**** Creating Stored Procedure dbo.ipw_ListPrograms...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_ListPrograms
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnProgramFilterKey	int		= NULL
)
AS
-- PROCEDURE:	ipw_ListPrograms
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates data in Program PickList for Case Windows

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Nov 2008	Neha	RFC6921	1	Return programs suitable for case screen control criteria maintenance in WB
-- 30 Jun 2009	Meetu	RFC7085	2	Return programs suitable for name screen control criteria maintenance in WB
-- 16 Dec 2009	LP	RFC8450	3	Extend to return all Case or Name programs depending on filter key
--					i.e. NULL = Cases, 1 = Names, 2 = CRM Names
-- 05 Jan 2010	KR	RFC8171 4	Return all programs with parent CASE as logical program is now allowed in WB
-- 27 May 2010	LP	RFC9323	5	Also check for new Marketing Module license when returning CRM programs.
-- 24 Apr 2014	DV	R30899	6	Return Programs based on PROGRAMGROUP

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(500)
Declare @sLookupCulture		nvarchar(10)
Declare @sCRMCaseProgram	nvarchar(10)
Declare @sCRMNameProgram	nvarchar(10)

-- Initialise variables
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

-- Fetch Case Programs
If @nErrorCode = 0 and @pnProgramFilterKey is null
Begin
	Select @sCRMCaseProgram = COLCHARACTER 
	from SITECONTROL 
	where CONTROLID = 'CRM Screen Control Program'
			
	Set @sSQLString = "
	Select 	distinct
		P.PROGRAMID		as 'ProgramKey',
		"+dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ProgramNameDesc'
	from 	PROGRAM P" +char(10)+ 
	"Where (P.PROGRAMGROUP = 'C'" + char(10)+
	"OR exists (SELECT 1 FROM PROGRAM PP where P.PARENTPROGRAM = PP.PROGRAMID and PP.PROGRAMGROUP = 'C'))" +char(10)+
	CASE WHEN dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, 25, getdate())<>1 
			and dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, 32, getdate())<>1 
			and @sCRMCaseProgram is not null 
	THEN char(10)+
	"AND (P.PROGRAMID <> @sCRMCaseProgram" +char(10)+
	"AND P.PARENTPROGRAM <> @sCRMCaseProgram)" END

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@sCRMCaseProgram	nvarchar(10)',
						@sCRMCaseProgram=@sCRMCaseProgram
	
	Set @pnRowCount = @@Rowcount
End

-- Fetch Name Programs
Else if @nErrorCode = 0 and @pnProgramFilterKey = 1 -- NAME
Begin
	Select @sCRMNameProgram = COLCHARACTER 
	from SITECONTROL 
	where CONTROLID = 'CRM Name Screen Program'
	 	
	Set @sSQLString = "
	Select 	distinct
		P.PROGRAMID as 'ProgramKey',
		"+dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'ProgramNameDesc'
	From 	PROGRAM P" +char(10)+ 
	"Where (P.PROGRAMGROUP = 'N'" + char(10)+
	"OR exists (SELECT 1 FROM PROGRAM PP where P.PARENTPROGRAM = PP.PROGRAMID and PP.PROGRAMGROUP = 'N'))" +char(10)+
	CASE WHEN dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, 25, getdate())<>1 
			and dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, 32, getdate())<>1
			and @sCRMNameProgram is not null 
	THEN char(10)+
	"AND (P.PROGRAMID <> @sCRMNameProgram" +char(10)+
	"AND P.PARENTPROGRAM <> @sCRMNameProgram)" END
	print @sSQLString
	Exec @nErrorCode = sp_executesql @sSQLString,
						N'@sCRMNameProgram	nvarchar(10)',
						@sCRMNameProgram=@sCRMNameProgram
	
	Set @pnRowCount = @@Rowcount
End
-- Fetch Programs for Name Criteria with CRM only licence
Else if @nErrorCode = 0 and @pnProgramFilterKey = 2 -- CRM NAME
Begin
	Set @sSQLString = "
	Select 	distinct
		P.PROGRAMID as 'ProgramKey',
		"+dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'ProgramNameDesc'
	From 	PROGRAM P" +char(10)+ 
	"Where P.PROGRAMID in" +char(10)+ 
	"(Select COLCHARACTER From SITECONTROL Where CONTROLID = 'CRM Name Screen Program')"
	
	Exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListPrograms to public
GO

