-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertTableCode									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertTableCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertTableCode.'
	Drop procedure [dbo].[ipw_InsertTableCode]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertTableCode...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertTableCode
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnTableCode			int		= null,	
	@pnTableType			smallint	= null,
	@psDescription			nvarchar(80)	= null,
	@psUserCode			nvarchar(50)	= null
)
as
-- PROCEDURE:	ipw_InsertTableCode
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert TableCodes.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Oct 2008	SF	RFC6510	1	Procedure created
-- 09 Aug 2010	DV	RFC8384 2	Restrict duplicate table code from getting inserted
-- 15 Feb 2011  MS	RFC8363 3	Updated UserCode field length to 50
-- 26 May 2016	MF	61941	4	LASTINTERNALCODE must be updated when new TABLECODE is allocated.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	        nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		        nchar(1)
Declare @sAlertXML		nvarchar(500)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin	
	if (@psDescription is not null and
		exists(select 1 from TABLECODES where upper(DESCRIPTION) = upper(@psDescription) and TABLETYPE = @pnTableType))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP119', 'Description already exists for the List Name.', null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin

	Set @sSQLString="
	Update LASTINTERNALCODE
	set INTERNALSEQUENCE=T.TABLECODE+1,
	    @pnTableCode    =T.TABLECODE+1
	from LASTINTERNALCODE L
	cross join (select max(isnull(TABLECODE,0)) as TABLECODE
		    from TABLECODES) T
	where L.TABLENAME='TABLECODES'"
						
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnTableCode		int		output',
				  @pnTableCode		= @pnTableCode output
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into TABLECODES(TABLECODE,TABLETYPE,DESCRIPTION,USERCODE)
			   values (@pnTableCode,@pnTableType,@psDescription,@psUserCode)"

	
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnTableCode		int,
				  @pnTableType		smallint,
				  @psDescription	nvarchar(80),
				  @psUserCode		nvarchar(50)',
				  @pnTableCode		= @pnTableCode,
				  @pnTableType		= @pnTableType,
				  @psDescription	= @psDescription,
				  @psUserCode		= @psUserCode
	
	Select @pnTableCode as TableCode

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertTableCode to public
GO
