-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListImageSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListImageSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListImageSummary.'
	Drop procedure [dbo].[ipw_ListImageSummary]
	Print '**** Creating Stored Procedure dbo.ipw_ListImageSummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListImageSummary
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnImageKey		int,
	@pbCalledFromCentura	bit 		= 0		
)
AS
-- PROCEDURE:	ipw_ListImageSummary
-- VERSION:	2
-- DESCRIPTION:	Returns a result set for the supplied image key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 28-Mar-2006	IB	RFC3388	1	Procedure created
-- 16-Mar-2010  PS	RFC6319	2	Add columns ImageStatusKey, ImageStatus, ImageTimeStamp, ImageDetailTimeStamp in the output request.

-- set server options
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@nErrorCode		int
Declare @nRowCount		int

Declare @tXMLOutputRequests	nvarchar(4000)	-- hard coded XMLOutputRequests value for ipw_ListImage call
Declare @tXMLFilterCriteria	nvarchar(4000)	-- hard coded XMLFilterCriteria value for ipw_ListImage call
Declare @sSQLString				nvarchar(4000)

-- initialise variables	

Set @nErrorCode			= 0
Set @nRowCount			= 0

Set @tXMLOutputRequests		= N'<OutputRequests>
			    		<Column ID="ImageKey" PublishName="ImageKey"/>
			    		<Column ID="NetworkLocation" PublishName="NetworkLocation"/>
			    		<Column ID="IsScanned" PublishName="IsScanned"/>
			    		<Column ID="ImageDescription" PublishName="ImageDescription" SortOrder="1" SortDirection="A"/>	
			    		<Column ID="ImageStatusKey" PublishName="ImageStatusKey"/>
			    		<Column ID="ImageStatus" PublishName="ImageStatus"/>
			    		<Column ID="ImageTimeStamp" PublishName="ImageTimeStamp"/>
			    		<Column ID="ImageDetailTimeStamp" PublishName="ImageDetailTimeStamp"/>			
			 	  </OutputRequests>'

Set @tXMLFilterCriteria		= N'<ipw_ListImage>
					<FilterCriteria>
						<ImageKey Operator="0">' + cast(@pnImageKey as nvarchar(12)) + '</ImageKey> 
					</FilterCriteria>
				  </ipw_ListImage>'

If @nErrorCode = 0
Begin
	exec dbo.ipw_ListImage
		  @pnRowCount		= @nRowCount	output,
		  @pnUserIdentityId	= @pnUserIdentityId,
		  @psCulture		= @psCulture,
		  @ptXMLOutputRequests	= @tXMLOutputRequests, 
		  @ptXMLFilterCriteria	= @tXMLFilterCriteria,
		  @pbCalledFromCentura	= @pbCalledFromCentura	
	
	Set @nErrorCode = @@Error
End

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_ListImageSummary to public
GO
