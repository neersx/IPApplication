-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_GenerateSearchKey
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_GenerateSearchKey]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_GenerateSearchKey.'
	Drop procedure [dbo].[na_GenerateSearchKey]
	Print '**** Creating Stored Procedure dbo.na_GenerateSearchKey...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_GenerateSearchKey
(
	@psSearchKey1		nvarchar(20) 	output,	
	@psSearchKey2		nvarchar(20) 	output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psName			nvarchar(254),	-- Mandatory
	-- For an individual only.
	@psGivenNames		nvarchar(50)	= null,
	@psInitials		nvarchar(10)	= null,
	@psMiddleName		nvarchar(50)	= null,
	@psSuffix		nvarchar(20)	= null

)
-- PROCEDURE:	na_GenerateSearchKey
-- VERSION :	5
-- DESCRIPTION:	A search key is an encoded version of a name that can be used during searching.  
-- This procedure potentially generates two search keys for the supplied name information.  
-- The first is the standard key.  The second key is generated after stop words have been suppressed.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 21-OCT-2002  JB		1	Procedure created
-- 30 Oct 2002	JB		2	Now returns NULL for SearchKey 2 if there are no stop words
-- 08 Nov 2002	JB		3	Search key 1 should have the stop words removed
--					Removed leading and trailing spaces
-- 06 Apr 2006	SW	RFC3503	4	Adjust handling of initials
-- 27 Oct 2015	vql	R53909	5	Add middle name and suffix.

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sFullName nvarchar(400)

Set @nErrorCode   = 0
Set @psMiddleName = ltrim(rtrim(upper(@psMiddleName)))
Set @psSuffix     = ltrim(rtrim(upper(@psSuffix)))
Set @psName       = ltrim(rtrim(upper(@psName)))
Set @psGivenNames = ltrim(rtrim(upper(@psGivenNames)))
Set @psInitials   = ltrim(rtrim(upper(@psInitials)))

Set @psName = rtrim(@psName + ' ' + @psSuffix)
Set @psGivenNames = rtrim(@psGivenNames + ' ' +@psMiddleName)

Set @sFullName = @psName

If @psGivenNames is not null and len(@psGivenNames) > 0
	Set @sFullName = @sFullName + ', ' + @psGivenNames

Else If @psInitials is not null and len(@psInitials) > 0
	Set @sFullName = @sFullName+ ', ' + @psInitials

-- Search key 2 has the stop words in it
Set @psSearchKey2 = rtrim(upper(left(@sFullName, 20)))


-- We are now going to clear up the parameters
Set @psName = dbo.fn_RemoveStopWords(@psName)
Set @psGivenNames = dbo.fn_RemoveStopWords(@psGivenNames)
Set @psInitials = dbo.fn_RemoveStopWords(@psInitials)


-- And rebuild for the 2nd search key
Set @sFullName = @psName

If @psGivenNames is not null and len(@psGivenNames) > 0
	Set @sFullName = @sFullName + ', ' + @psGivenNames

Else If @psInitials is not null and len(@psInitials) > 0
	Set @sFullName = @sFullName+ ', ' + @psInitials

-- Note that after they have been cleaned we cannot assume any are populated.
If left(@sFullName, 2) = ', '
	Set @sFullName = substring(@sFullName, 3, 20)

-- Search key 1 has the stop words removed
Set @psSearchKey1 = rtrim(left(@sFullName, 20))

-- If no difference (i.e. no stop words have been removed nullify it!
If @psSearchKey2 = @psSearchKey1
	Set @psSearchKey2 = null

Return @nErrorCode
GO

Grant execute on dbo.na_GenerateSearchKey to public
GO
