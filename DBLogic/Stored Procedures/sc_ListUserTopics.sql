-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_ListUserTopics
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_ListUserTopics]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_ListUserTopics.'
	Drop procedure [dbo].[sc_ListUserTopics]
End
Print '**** Creating Stored Procedure dbo.sc_ListUserTopics...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.sc_ListUserTopics
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey 		int		= null,	-- the key of the user who's permissions are required
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	sc_ListUserTopics
-- VERSION:	5
-- DESCRIPTION:	Returns the list of subjects that the current user has been granted access to.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Aug 2004	TM	RFC1500	1	Procedure created
-- 16 Sep 2004	JEK	RFC886	2	Implement translation.
-- 14 Oct 2004	TM	RFC1898	3	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1' 
--					as a 'join' or 'where' condition. 
-- 14 May 2004	JEK	RFC2594 4	Restrict to topics that have the necessary prerequisites
-- 12 Jul 2006	SW	RFC3828	5	Pass getdate() to fn_Permission..

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
Declare @dtToday	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

-- If the @pnIdentityKey was not supplied then find out tasks 
-- for the current user (@pnUserIdentityId)
Set @pnIdentityKey = ISNULL(@pnIdentityKey, @pnUserIdentityId)

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnIdentityKey		as 'IdentityKey',
		DT.TOPICID		as 'TopicKey',
		"+dbo.fn_SqlTranslatedColumn('DATATOPIC','TOPICNAME',null,'DT',@psCulture,@pbCalledFromCentura)
				+ " as 'TopicName',
		"+dbo.fn_SqlTranslatedColumn('DATATOPIC','DESCRIPTION',null,'DT',@psCulture,@pbCalledFromCentura)
				+ " as 'Description',
		P.CanSelect		as 'CanSelect'
	from DATATOPIC DT
	join dbo.fn_PermissionsGranted(@pnIdentityKey, 'DATATOPIC', null, null, @dtToday) P
			on (P.ObjectIntegerKey = DT.TOPICID
			and P.CanSelect = 1)
	join dbo.fn_ValidObjects(null, 'DATATOPICREQUIRES', @dtToday) VO
				on (VO.ObjectIntegerKey = P.ObjectIntegerKey) 
	order by 3"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @dtToday		datetime',
					  @pnIdentityKey	= @pnIdentityKey,
					  @dtToday		= @dtToday
	Set @pnRowCount = @@ROWCOUNT

End



	


Return @nErrorCode
GO

Grant execute on dbo.sc_ListUserTopics to public
GO
