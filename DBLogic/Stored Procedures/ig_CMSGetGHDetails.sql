-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_CMSGetGHDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_CMSGetGHDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_CMSGetGHDetails.'
	Drop procedure [dbo].[ig_CMSGetGHDetails]
End
Print '**** Creating Stored Procedure dbo.ig_CMSGetGHDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ig_CMSGetGHDetails
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@psIntegrationType 	nvarchar(255),		-- Mandatory
	@ptXMLMessage		ntext
)
as
-- PROCEDURE:	ig_CMSGetGHDetails
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure is a wrapper stored procedure to call all other 
--		Griffith Hack specific stored procedures for CMS Integration.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Nov 2005	TM	11022 	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @idoc 		int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

Declare @nCaseKey	int
Declare @nNameKey	int
Declare @nEntityNo	int
Declare @nTransNo	int
Declare @nWIPSeqNo	smallint

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML		
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLMessage

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
and @psIntegrationType = 'Case'
Begin
	Set @sSQLString = 	
	"Select @nCaseKey = CaseId"+CHAR(10)+
	"from	OPENXML (@idoc, '//Message/Item/Case',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseId	int	'CaseId/text()'"+CHAR(10)+	
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc		int,
				  @nCaseKey 	int		output',
				  @idoc		= @idoc,
				  @nCaseKey 	= @nCaseKey	output

	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.ig_CMSGetGHCaseDetail
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey		= @nCaseKey
	End	
End
Else 
If @nErrorCode = 0
and @psIntegrationType = 'Name'
Begin
	Set @sSQLString = 	
	"Select @nNameKey = case when NameId is not null then NameId else ClientId end"+CHAR(10)+
	"from	OPENXML (@idoc, '//Message/Item',1)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      NameId	int	'Name/NameId/text()',"+CHAR(10)+	
	"	      ClientId	int	'Client/ClientId/text()'"+CHAR(10)+	
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc		int,
				  @nNameKey 	int		output',
				  @idoc		= @idoc,
				  @nNameKey 	= @nNameKey	output

	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.ig_CMSGetGHNameDetails
			@pnNameKey	= @nNameKey
	End
End
Else 
If @nErrorCode = 0
and @psIntegrationType = 'WIP'
Begin
	Set @sSQLString = 	
	"Select @nEntityNo 	= EntityNo,"+CHAR(10)+
	"	@nTransNo 	= TransNo,"+CHAR(10)+
	"	@nWIPSeqNo	= WIPSeqNo"+CHAR(10)+
	"from	OPENXML (@idoc, '//Message/Item/WIP',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      EntityNo	int		'EntityNo/text()',"+CHAR(10)+	
	"	      TransNo	int		'TransNo/text()',"+CHAR(10)+	
	"	      WIPSeqNo	smallint 	'WIPSeqNo/text()'"+CHAR(10)+	
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc		int,
				  @nEntityNo 	int		output,
				  @nTransNo	int		output,
				  @nWIPSeqNo	smallint	output',
				  @idoc		= @idoc,
				  @nEntityNo 	= @nEntityNo	output,
				  @nTransNo	= @nTransNo	output,
				  @nWIPSeqNo	= @nWIPSeqNo	output 

	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.ig_CMSGetGHWIPDetail
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnEntityNo		= @nEntityNo,
			@pnTransNo		= @nTransNo,
			@pnWIPSeqNo		= @nWIPSeqNo
	End
End

-- deallocate the xml document handle when finished.
exec sp_xml_removedocument @idoc

Return @nErrorCode
GO

Grant execute on dbo.ig_CMSGetGHDetails to public
GO
