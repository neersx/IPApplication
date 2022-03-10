-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetDataLength
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetDataLength]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetDataLength.'
	Drop procedure [dbo].[cs_GetDataLength]
End
Print '**** Creating Stored Procedure dbo.cs_GetDataLength...'
Print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_GetDataLength
(
	@pnUserIdentityId		int		,	
	@psCulture			nvarchar(10)	= null,
	@psText varchar(1000)
) 

As
-- PROCEDURE:	cs_GetDataLength
-- VERSION :	1
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get the length of a string in bytes
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 24/02/06	DL	12254	1	Created

Begin
	Select datalength( @psText)
	return @@Error
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Grant execute on dbo.cs_GetDataLength to public
GO
