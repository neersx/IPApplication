-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_MaintainFilter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_MaintainFilter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_MaintainFilter.'
	Drop procedure [dbo].[qr_MaintainFilter]
End
Print '**** Creating Stored Procedure dbo.qr_MaintainFilter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_MaintainFilter
(
	@pnFilterKey		int		= null output,	-- Required for update
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnContextKey		int,		-- Mandatory
	@pnAdoptFromQueryKey	int	 	= null,		-- Indicates that the filter on the identified query should be used
	@ptXMLFilterCriteria	ntext		= null,
	@ptOldXMLFilterCriteria	ntext		= null
)
as
-- PROCEDURE:	qr_MaintainFilter
-- VERSION:	5
-- DESCRIPTION:	Insert/update/adopt a query filter.

-- MODIFICATIONS :
-- Date		Who	Change	    Version	Description
-- -----------	-------	------	    -------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC398	    1		Procedure created
-- 15 Apr 2004	TM	RFC917	    2		Use fn_IsNtextEqual() to compare ntext strings.
-- 15 Sep 2004	TM	RFC1822	    3		Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	    4		Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--						SQL string executed by sp_executesql.
-- 14 Jul 2008	vql	SQA16490    5		SCOPE_IDENT( ) to retrieve an identity value cannot be used with tables that have an INSTEAD OF trigger present.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

-- Reuse from another query
If @nErrorCode = 0
and @pnAdoptFromQueryKey is not null
Begin
	Set @sSQLString = " 
	select	@pnFilterKey=F.FILTERID
	from	QUERY Q
	join	QUERYFILTER F	on (F.FILTERID = Q.FILTERID)
	where	Q.QUERYID = @pnAdoptFromQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnFilterKey		int	output,
					  @pnAdoptFromQueryKey	int',
					  @pnFilterKey		= @pnFilterKey	output,
					  @pnAdoptFromQueryKey	= @pnAdoptFromQueryKey
End
-- Insert
Else If @nErrorCode = 0
and @ptXMLFilterCriteria is not null
and @ptOldXMLFilterCriteria is null
Begin
	Set @sSQLString = " 
	insert	QUERYFILTER
		(PROCEDURENAME, XMLFILTERCRITERIA)
	select	PROCEDURENAME, @ptXMLFilterCriteria
	from	QUERYCONTEXT
	where	CONTEXTID = @pnContextKey

	Set @pnFilterKey = IDENT_CURRENT('QUERYFILTER')"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnFilterKey		int		OUTPUT,
					  @pnContextKey		int,
					  @ptXMLFilterCriteria	ntext',
					  @pnFilterKey		= @pnFilterKey 	OUTPUT,
					  @pnContextKey		= @pnContextKey,
					  @ptXMLFilterCriteria	= @ptXMLFilterCriteria	

End
-- Update
Else If @nErrorCode = 0
and @ptXMLFilterCriteria is not null
and @ptOldXMLFilterCriteria is not null
and @pnFilterKey is not null
Begin
	Set @sSQLString = " 
	update	QUERYFILTER
	set	XMLFILTERCRITERIA = @ptXMLFilterCriteria
	where	FILTERID = @pnFilterKey
	-- Use the fn_IsNtextEqual() function to compare ntext strings
	and     dbo.fn_IsNtextEqual(XMLFILTERCRITERIA, @ptOldXMLFilterCriteria) = 1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnFilterKey			int,
					  @ptXMLFilterCriteria		ntext,
					  @ptOldXMLFilterCriteria	ntext',
					  @pnFilterKey			= @pnFilterKey,
					  @ptXMLFilterCriteria		= @ptXMLFilterCriteria,
					  @ptOldXMLFilterCriteria	= @ptOldXMLFilterCriteria

End

Return @nErrorCode
GO

Grant execute on dbo.qr_MaintainFilter to public
GO
