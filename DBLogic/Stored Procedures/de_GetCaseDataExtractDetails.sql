-----------------------------------------------------------------------------------------------------------------------------
-- Creation of de_GetCaseDataExtractDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[de_GetCaseDataExtractDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.de_GetCaseDataExtractDetails.'
	Drop procedure [dbo].[de_GetCaseDataExtractDetails]
End
Print '**** Creating Stored Procedure dbo.de_GetCaseDataExtractDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.de_GetCaseDataExtractDetails
(
	@pnDataExtractID	tinyint		= null	output, -- The identifier necessary to call the case data extract module for this system.
	@psCountryCode		nvarchar(3)	= null	output, -- The country code of the case.
	@psApplicationNumber	nvarchar(36)	= null	output, -- The application number for the case (if any).
	@psPublicationNumber	nvarchar(36)	= null	output,	-- The publication number for the case (if any).
	@psRegistrationNumber	nvarchar(36)	= null	output,	-- The registration number for the case (if any).
	@psSystemCode		nvarchar(20)	= null	output, -- The system code of the external system.
	@pnUserIdentityId	int,		-- Mandatory
	@pnSourceSystemKey	int,		-- Mandatory.	   The key of the system that data is being extracted from.
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	de_GetCaseDataExtractDetails
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the parameters necessary to look a case up in the CaseDataExtract module.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Sep 2005	TM	RFC1342	1	Procedure created
-- 29 Sep 2005	TM	RFC1342	2	Official numbers (not their codes) need to be returned.
-- 03 Apr 2006	JEK	RFC3692	3	Map country code.
-- 13 Dec 2011	JC	RFC6271	4	Add System Code output parameter.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Map implemented country code back to source value from input system
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	SELECT  @psCountryCode=
		Substring(
		max (	CASE WHEN M.INPUTCODE  	is NULL THEN '0' ELSE '1' END+ -- Source data -> implementation
			CASE WHEN MC.INPUTCODE 	is NULL THEN '0' ELSE '1' END+ -- Source data -> common encoding -> implementation
			CASE WHEN V.CODE	is NULL THEN '0' ELSE '1' END+ -- Encoding -> implementation (direct then via common encoding)
			coalesce(M.INPUTCODE, MC.INPUTCODE, V.CODE, C.COUNTRYCODE) -- Case code default if unmapped
			), 4,3)
	from CASES C
	left join EXTERNALSYSTEM EX	on (EX.DATAEXTRACTID=@pnSourceSystemKey)
	left join DATASOURCE DS		on (DS.SYSTEMID=EX.SYSTEMID)
	left join MAPSCENARIO MS	on (MS.SYSTEMID=EX.SYSTEMID
					and MS.STRUCTUREID=4) -- Country
	-- Mapping
	left join MAPPING M		on (M.OUTPUTVALUE=C.COUNTRYCODE
					and M.STRUCTUREID=MS.STRUCTUREID)
	-- Mapped from an encoding
	left join MAPPING MC		on (MC.OUTPUTCODEID=M.INPUTCODEID
					and MC.STRUCTUREID=MS.STRUCTUREID)
	-- Encoded value to implementation/via standard encoding
	left join ENCODEDVALUE V	on (V.STRUCTUREID=MS.STRUCTUREID
					and V.SCHEMEID=isnull(MS.SCHEMEID,-1)
					and V.CODEID=isnull(MC.INPUTCODEID,M.INPUTCODEID))
	where C.CASEID = @pnCaseKey"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@psCountryCode	nvarchar(3)		output,
					  @pnSourceSystemKey	int,
					  @pnCaseKey		int',
					  @psCountryCode	= @psCountryCode	output,
					  @pnSourceSystemKey	= @pnSourceSystemKey,
					  @pnCaseKey		= @pnCaseKey		

End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  @pnDataExtractID 	= EX.DATAEXTRACTID,
		@psApplicationNumber	= OA.OFFICIALNUMBER,
		@psRegistrationNumber	= RO.OFFICIALNUMBER,
		@psPublicationNumber	= OP.OFFICIALNUMBER
	from CASES C
	left join EXTERNALSYSTEM EX	on (EX.SYSTEMID = @pnSourceSystemKey)
	-- NumberType data structure to get the official numbers
	left join MAPSTRUCTURE S	on (S.STRUCTUREID = 1)
	-- Locate 'Application Number' number type in standard CPA Inpro encoding:
	left join ENCODEDVALUE VA	on (VA.STRUCTUREID = S.STRUCTUREID
					and VA.SCHEMEID = -1 -- CPA Inpro Standard
					and VA.CODE = N'A') -- Application Number
	-- Locate implementation of the 'Application Number' at this site
	left join MAPPING MA		on (MA.INPUTCODEID = VA.CODEID
					and MA.STRUCTUREID = S.STRUCTUREID
					and MA.DATASOURCEID is null
					and MA.OUTPUTVALUE  is not null)
	left join OFFICIALNUMBERS OA	on (OA.CASEID = C.CASEID
					and OA.ISCURRENT = 1
					and OA.NUMBERTYPE = isnull(MA.OUTPUTVALUE,VA.CODE))
	-- Locate 'Registration Number' number type in standard CPA Inpro encoding:
	left join ENCODEDVALUE VR	on (VR.STRUCTUREID = S.STRUCTUREID
					and VR.SCHEMEID = -1 -- CPA Inpro Standard
					and VR.CODE = N'R') -- Registration Number
	-- Locate implementation of the 'Registration Number' at this site
	left join MAPPING MR		on (MR.INPUTCODEID = VR.CODEID
					and MR.STRUCTUREID = S.STRUCTUREID
					and MR.DATASOURCEID is null
					and MR.OUTPUTVALUE  is not null)
	left join OFFICIALNUMBERS RO	on (RO.CASEID = C.CASEID
					and RO.ISCURRENT = 1
					and RO.NUMBERTYPE = isnull(MR.OUTPUTVALUE,VR.CODE))
	-- Locate 'Publication Number' number type in standard CPA Inpro encoding:
	left join ENCODEDVALUE VP	on (VP.STRUCTUREID = S.STRUCTUREID
					and VP.SCHEMEID = -1 -- CPA Inpro Standard
					and VP.CODE = N'P') -- Publication Number
	-- Locate implementation of the 'Publication Number' at this site
	left join MAPPING MP		on (MP.INPUTCODEID = VP.CODEID
					and MP.STRUCTUREID = S.STRUCTUREID
					and MP.DATASOURCEID is null
					and MP.OUTPUTVALUE  is not null)	
	left join OFFICIALNUMBERS OP	on (OP.CASEID = C.CASEID
					and OP.ISCURRENT = 1
					and OP.NUMBERTYPE = isnull(MP.OUTPUTVALUE,VP.CODE))
	where C.CASEID = @pnCaseKey"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnDataExtractID	tinyint			output,
					  @psApplicationNumber	nvarchar(36)		output,
					  @psRegistrationNumber	nvarchar(36)		output,
					  @psPublicationNumber	nvarchar(36)		output,
					  @pnSourceSystemKey	int,
					  @pnCaseKey		int',
					  @pnDataExtractID	= @pnDataExtractID	output,
					  @psApplicationNumber	= @psApplicationNumber	output,
					  @psRegistrationNumber	= @psRegistrationNumber	output,
					  @psPublicationNumber	= @psPublicationNumber	output,
					  @pnSourceSystemKey	= @pnSourceSystemKey,
					  @pnCaseKey		= @pnCaseKey		
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  @psSystemCode		= EX.SYSTEMCODE
	from DATAEXTRACTMODULE DEM
	join EXTERNALSYSTEM EX	on (EX.SYSTEMID = DEM.SYSTEMID)
	where DEM.DATAEXTRACTID = @pnSourceSystemKey"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@psSystemCode		nvarchar(20)		output,
					  @pnSourceSystemKey	int',
					  @psSystemCode		= @psSystemCode		output,
					  @pnSourceSystemKey	= @pnSourceSystemKey	
End


Return @nErrorCode
GO

Grant execute on dbo.de_GetCaseDataExtractDetails to public
GO
