-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_GetDeliveryMethod
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_GetDeliveryMethod]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_GetDeliveryMethod.'
	Drop procedure [dbo].[dg_GetDeliveryMethod]
End
Print '**** Creating Stored Procedure dbo.dg_GetDeliveryMethod...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.dg_GetDeliveryMethod
	@pnDeliveryID		int
AS
-- Procedure :	dg_GetDeliveryMethod
-- VERSION :	1
-- DESCRIPTION:	This stored procedure will return a Delivery Method details
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 16 Dec 2011	PK	RFC11035	1	Initial creation

-- Declare variables
Declare	@nErrorCode			int
Declare @sSQLString 		nvarchar(4000)

-- Initialise
-- Prevent row counts
Set	NOCOUNT on
Set	CONCAT_NULL_YIELDS_NULL off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Initialize internal variables
Set	@nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	dm.DELIVERYID as DeliveryID,
			dm.DELIVERYTYPE as DeliveryType,
			dm.DESCRIPTION as Description,
			dm.MACRO as Macro,
			dm.FILEDESTINATION as FileDestination,
			dm.RESOURCENO as ResourceNo,
			dm.DESTINATIONSP as DestinationSP,
			dm.DIGITALCERTIFICATE as DigitalCertificate,
			dm.EMAILSP as EmailSP,
			dm.NAMETYPE as NameType
		From	DELIVERYMETHOD dm
		Where	dm.DELIVERYID = @pnDeliveryID
		"
		
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnDeliveryID		int',
			@pnDeliveryID		= @pnDeliveryID
		
	Set @nErrorCode = @@error
End

Return @nErrorCode
go

Grant execute on dbo.dg_GetDeliveryMethod to Public
go
