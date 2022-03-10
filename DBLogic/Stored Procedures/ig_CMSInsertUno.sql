-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_CMSInsertUno
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_CMSInsertUno]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_CMSInsertUno.'
	Drop procedure [dbo].[ig_CMSInsertUno]
End
Print '**** Creating Stored Procedure dbo.ig_CMSInsertUno...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ig_CMSInsertUno
(
	@pnIntegrationItemID	int,		-- Mandatory
	@psLabel		nvarchar(30),	-- Mandatory
	@psType 		nvarchar(255),	-- Mandatory	
	@psUniqueNumber		nvarchar(36),	-- Mandatory
	@psIntegrationType	nchar(1) = null	-- N for Names and C for Client and null for Case - Optional
)
as
-- PROCEDURE:	ig_CMSInsertUno
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts or updates the Unique CMS ID only for a Case or a Name returned from CMS.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Nov 2005	TM	11022	1	Procedure created
-- 19 Oct 2006	PK	4528	2	Require Owners NameType to be interfaced to CMS
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	4	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @nRowCount	int
Declare @nUnoExists	int

-- Initialise variables
Set @nErrorCode 	= 0
Set @nRowCount 		= 0

If  @psLabel <> 'Case'
and @psLabel <> 'Name'
Begin
	Raiserror ('Type is NOT ''Name'' or ''Case''.',16,1)		
	Set @nErrorCode = @@Error
End

If  @nErrorCode = 0
and (@psLabel = 'Case')
Begin
	-- If row already exists for the CaseId and Type = Resync then update MatterUno 
	If @psType = 'Resync'
	Begin
		Set @sSQLString = "
		Update OFFICIALNUMBERS
		Set    OFFICIALNUMBER = @psUniqueNumber
		from   INTEGRATIONHISTORY IH
		join   OFFICIALNUMBERS O	on (O.CASEID = IH.INTKEY)
		join   SITECONTROL SC		on (SC.CONTROLID = 'CMS Unique Matter Number Type'
						and SC.COLCHARACTER = O.NUMBERTYPE)
		where  IH.INTEGRATIONID = @pnIntegrationItemID"
		
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnIntegrationItemID	int,
						  @psUniqueNumber	nvarchar(36)',
						  @pnIntegrationItemID	= @pnIntegrationItemID,
						  @psUniqueNumber	= @psUniqueNumber	
		Set @nRowCount = @@Rowcount
	End
	Else
	-- Check if MatterUno exists for this Case
	Begin
		Set @nUnoExists =
		(Select 1
		from   INTEGRATIONHISTORY IH
		join   OFFICIALNUMBERS O	on (O.CASEID = IH.INTKEY)
		join   SITECONTROL SC		on (SC.CONTROLID = 'CMS Unique Matter Number Type'
						and SC.COLCHARACTER = O.NUMBERTYPE)
		where  IH.INTEGRATIONID = @pnIntegrationItemID)

		Set @nRowCount = ISNULL(@nUnoExists,0)
	End

	If @nErrorCode = 0 and @nRowCount = 0
	-- If no row exists for the CaseKey then insert one:	
	Begin
		Set @sSQLString = "
		Insert 	into OFFICIALNUMBERS (CASEID, OFFICIALNUMBER, NUMBERTYPE)
		Select	IH.INTKEY, @psUniqueNumber, SC.COLCHARACTER 
		from   INTEGRATIONHISTORY IH
		join   SITECONTROL SC	on (SC.CONTROLID = 'CMS Unique Matter Number Type')
		where  IH.INTEGRATIONID = @pnIntegrationItemID"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIntegrationItemID	int,
					  @psUniqueNumber	nvarchar(36)',
					  @pnIntegrationItemID	= @pnIntegrationItemID,
					  @psUniqueNumber	= @psUniqueNumber
	End

	-- If a MatterUno exists and Type is not Resync raise and error
	If @nErrorCode = 0 and @nRowCount > 0 and @psType <> 'Resync'
	Begin
		Raiserror ('MatterUno already exists for this Case. MatterUno can only be updated with a Resync.',16,1)		
		Set @nErrorCode = @@Error
	End
End
Else If  @nErrorCode = 0
and (@psLabel = 'Name' and @psIntegrationType = 'N')
Begin
	-- If row already exists for the NameNo and Type = Resync then update ClientUno
	If @psType = 'Resync'
	Begin
		Set @sSQLString = "
		Update NAMEALIAS
		Set    ALIAS = @psUniqueNumber
		from   INTEGRATIONHISTORY IH
		join   NAMEALIAS A	on (A.NAMENO = IH.INTKEY)
		join   SITECONTROL SC	on (SC.CONTROLID = 'CMS Unique Name Alias Type'
					and SC.COLCHARACTER = A.ALIASTYPE)
		where  IH.INTEGRATIONID = @pnIntegrationItemID
		and A.COUNTRYCODE  is null
		and A.PROPERTYTYPE is null"
		
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnIntegrationItemID	int,
						  @psUniqueNumber	nvarchar(36)',
						  @pnIntegrationItemID	= @pnIntegrationItemID,
						  @psUniqueNumber	= @psUniqueNumber	
		Set @nRowCount = @@Rowcount
	End
	Else
	-- Check if NameUno exists for this Name
	Begin
		Set @nUnoExists =
		(Select 1
		from   INTEGRATIONHISTORY IH
			join   NAMEALIAS A	on (A.NAMENO = IH.INTKEY
						and A.COUNTRYCODE  is null
						and A.PROPERTYTYPE is null)
			join   SITECONTROL SC	on (SC.CONTROLID = 'CMS Unique Name Alias Type'
						and SC.COLCHARACTER = A.ALIASTYPE)
			where  IH.INTEGRATIONID = @pnIntegrationItemID)

		Set @nRowCount = isnull(@nUnoExists,0)
	End

	-- If no row exists for the NameKey then insert one:	
	If  @nErrorCode = 0 and @nRowCount = 0
	Begin
		Set @sSQLString = "
		Insert 	into NAMEALIAS (NAMENO, ALIAS, ALIASTYPE)
		Select	IH.INTKEY, @psUniqueNumber, SC.COLCHARACTER 
		from   INTEGRATIONHISTORY IH
		join   SITECONTROL SC	on (SC.CONTROLID = 'CMS Unique Name Alias Type')
		where  IH.INTEGRATIONID = @pnIntegrationItemID"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIntegrationItemID	int,
					  @psUniqueNumber	nvarchar(36)',
					  @pnIntegrationItemID	= @pnIntegrationItemID,
					  @psUniqueNumber	= @psUniqueNumber
	End


	-- If a NameUno exists and Type is not Resync raise and error
	If @nErrorCode = 0 and @nRowCount > 0 and @psType <> 'Resync'
	Begin
		Raiserror ('NameUno already exists for this Name. NameUno can only be updated with a Resync.',16,1)		
		Set @nErrorCode = @@Error
	End
End
Else If  @nErrorCode = 0
and (@psLabel = 'Name' and @psIntegrationType = 'C')
Begin
	-- If row already exists for the NameNo and Type = Resync then update ClientUno
	If @psType = 'Resync'
	Begin
		Set @sSQLString = "
		Update NAMEALIAS
		Set    ALIAS = @psUniqueNumber
		from   INTEGRATIONHISTORY IH
		join   NAMEALIAS A		on (A.NAMENO = IH.INTKEY)
		join   SITECONTROL SC	on (SC.CONTROLID = 'CMS Unique Client Alias Type'
					and SC.COLCHARACTER = A.ALIASTYPE)
		where  IH.INTEGRATIONID = @pnIntegrationItemID"
		
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnIntegrationItemID	int,
						  @psUniqueNumber	nvarchar(36)',
						  @pnIntegrationItemID	= @pnIntegrationItemID,
						  @psUniqueNumber	= @psUniqueNumber	
		Set @nRowCount = @@Rowcount
	End
	Else
	-- Check if ClientUno exists for this Name
	Begin
		Set @nUnoExists =
		(Select 1
		from   INTEGRATIONHISTORY IH
			join   NAMEALIAS A		on (A.NAMENO = IH.INTKEY)
			join   SITECONTROL SC	on (SC.CONTROLID = 'CMS Unique Client Alias Type'
						and SC.COLCHARACTER = A.ALIASTYPE)
			where  IH.INTEGRATIONID = @pnIntegrationItemID)

		Set @nRowCount = isnull(@nUnoExists,0)
	End

	-- If no row exists for the NameKey then insert one:	
	If  @nErrorCode = 0 and @nRowCount = 0
	Begin
		Set @sSQLString = "
		Insert 	into NAMEALIAS (NAMENO, ALIAS, ALIASTYPE)
		Select	IH.INTKEY, @psUniqueNumber, SC.COLCHARACTER 
		from   INTEGRATIONHISTORY IH
		join   SITECONTROL SC	on (SC.CONTROLID = 'CMS Unique Client Alias Type')
		where  IH.INTEGRATIONID = @pnIntegrationItemID"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIntegrationItemID	int,
					  @psUniqueNumber	nvarchar(36)',
					  @pnIntegrationItemID	= @pnIntegrationItemID,
					  @psUniqueNumber	= @psUniqueNumber
	End


	-- If a NameUno exists and Type is not Resync raise and error
	If @nErrorCode = 0 and @nRowCount > 0 and @psType <> 'Resync'
	Begin
		Raiserror ('ClientUno already exists for this Name. ClientUno can only be updated with a Resync.',16,1)		
		Set @nErrorCode = @@Error
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ig_CMSInsertUno to public
GO
