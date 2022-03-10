-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RegisterAccess
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_RegisterAccess]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_RegisterAccess.'
	Drop procedure [dbo].[ip_RegisterAccess]
	Print '**** Creating Stored Procedure dbo.ip_RegisterAccess...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ip_RegisterAccess
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psDatabaseTable	nvarchar(30),	-- Mandatory
	@pnIntegerKey		int		= null,
	@psCharacterKey		nvarchar(100)	= null
)
AS
-- PROCEDURE :	ip_RegisterAccess
-- VERSION :	4
-- DESCRIPTION:	This procedure updates any Quick Indexes for the current user to reflect 
--		the fact that a database table has been accessed.
--		This may involve no changes, the additional of any entry to the user's Quick Index, 
--		or update of information on an existing index.
-- CALLED BY :	Data Access Layer

-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15/08/2002	SF			Procedure created
-- 24/03/2004	TM	RFC399	4	Rewrite the procedure to make it more efficient.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @sDataType 		varchar(1)
Declare @nCurrentIndex 		int
Declare @dtLastAccessed 	datetime

Declare @nMaxEntries 		int		
Declare @nCounter 		int
Declare @nRowCount 		int
Declare @nCurrentEntry 		int

Declare @tRecentlyAddedIndexes 	table ( IDENT 		int 	identity(1,1), 
					INDEXID 	int 	not null,
					MAXENTRIES 	tinyint not null)

-- Initialise variables
Set @nErrorCode = 0
Set @nCounter = 1	
Set @dtLastAccessed = getdate()
	
-- Update existing entries
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Update 	IDENTITYINDEX
	set	IDENTITYINDEX.LASTACCESSED = @dtLastAccessed
	from	QUICKINDEX X
	where	IDENTITYINDEX.IDENTITYID = @pnUserIdentityId
	and	X.INDEXFORTABLE = @psDatabaseTable
	and	X.INDEXID = IDENTITYINDEX.INDEXID"
	
	-- If the key of the database table row passed (@pnIntegerKey) is integer compare it to 
	-- an IDENTITYINDEX.COLINTEGER, otherwise (@psCharacterKey) compare it to the IDENTITYINDEX.COLCHARACTER  
	If @pnIntegerKey is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) + "and IDENTITYINDEX.COLINTEGER = @pnIntegerKey"
	End
	Else Begin
		Set @sSQLString = @sSQLString + char(10) + "and IDENTITYINDEX.COLCHARACTER = @psCharacterKey"
	End

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@dtLastAccessed	datetime,
					  @pnUserIdentityId 	int,
					  @psDatabaseTable	nvarchar(30),
					  @pnIntegerKey		int,
					  @psCharacterKey	nvarchar(100)',
					  @dtLastAccessed	= @dtLastAccessed, 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @psDatabaseTable	= @psDatabaseTable,
					  @pnIntegerKey		= @pnIntegerKey,
					  @psCharacterKey	= @psCharacterKey
					  	
End		
	
-- Locate any auto-generated indexes for this database table,
-- where the entry does not already exist for this user.
-- For each index, add an entry into the IdentityIndex.
If @nErrorCode = 0
Begin	
	Set @sSQLString = 
	"insert into IDENTITYINDEX ("+char(10)+
	"		INDEXID,"+char(10)+ 
	"		IDENTITYID,"+char(10)+ 
	"		COLINTEGER,"+char(10)+ 
	"		COLCHARACTER,"+char(10)+ 
	"		LASTACCESSED )"+char(10)+
	"select 	X.INDEXID,"+char(10)+
	"		@pnUserIdentityId,"
	
	-- If the key of the database table row passed (@pnIntegerKey) is integer compare it to 
	-- an IDENTITYINDEX.COLINTEGER, otherwise (@psCharacterKey) compare it to the IDENTITYINDEX.COLCHARACTER 
	If @pnIntegerKey is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) +
				 "		@pnIntegerKey,"+char(10)+
				 "		null,"+char(10)+ 
				 "		@dtLastAccessed"+char(10)+
		"from	QUICKINDEX X"+char(10)+
		"where	X.AUTOPOPULATEFLAG = 1"+char(10)+
		"and	X.INDEXFORTABLE = @psDatabaseTable"+char(10)+
		"and not exists (select * from IDENTITYINDEX I"+char(10)+
		"		where	I.INDEXID = X.INDEXID"+char(10)+
		"		and	I.IDENTITYID = @pnUserIdentityId"+char(10)+
		"		and 	I.COLINTEGER = @pnIntegerKey)"
	End
	Else Begin

		Set @sSQLString = @sSQLString + char(10) + 
				"		null,"+char(10)+
				"		@psCharacterKey,"+char(10)+ 							 	
			"		@dtLastAccessed"+char(10)+
			"from	QUICKINDEX X"+char(10)+
			"where	X.AUTOPOPULATEFLAG = 1"+char(10)+
			"and	X.INDEXFORTABLE = @psDatabaseTable"+char(10)+
			"and not exists (select * from IDENTITYINDEX I"+char(10)+
			"		where	I.INDEXID = X.INDEXID"+char(10)+
			"		and	I.IDENTITYID = @pnUserIdentityId"+char(10)+
			"		and 	I.COLCHARACTER = @psCharacterKey)"	
	End

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@dtLastAccessed	datetime,
					  @pnUserIdentityId 	int,
					  @psDatabaseTable	nvarchar(30),
					  @pnIntegerKey		int,
					  @psCharacterKey	nvarchar(100)',
					  @dtLastAccessed	= @dtLastAccessed, 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @psDatabaseTable	= @psDatabaseTable,
					  @pnIntegerKey		= @pnIntegerKey,
					  @psCharacterKey	= @psCharacterKey	

End

-- Delete entries if necessary
If @nErrorCode = 0
Begin
	-- Store the Indexes and their max number of entries for rows that have been inserted in the table variable. 
	Insert into @tRecentlyAddedIndexes (INDEXID, MAXENTRIES) 	
	select  distinct 
		II.INDEXID, 
		-- The QuickIndexRule.MaxEntries for the IndexId defines the (optional) maximum
		-- allowed.  Use the rule for this @pnUserIdentityId, but if there is none,
		-- select the default rule (IdentityId is null) 
		ISNULL(IR.MAXENTRIES, IRD.MAXENTRIES)  
	from 	IDENTITYINDEX II			
	left join    QUICKINDEXRULE IR	on (IR.INDEXID = II.INDEXID
					and IR.IDENTITYID = II.IDENTITYID)
	left join    QUICKINDEXRULE IRD	on (IRD.INDEXID = II.INDEXID
					and IRD.IDENTITYID is null) 
	-- Only those Indexes for which rows were inserted need to be examined.
	where 	II.LASTACCESSED = @dtLastAccessed	
	and	II.IDENTITYID = @pnUserIdentityId
	
	Select  @nRowCount = @@rowcount, 
		@nErrorCode = @@error
End

While @nErrorCode = 0 	
and @nCounter <= @nRowCount
Begin		
	Select 	@nCurrentIndex  = INDEXID,
	        @nMaxEntries	= MAXENTRIES 
	from	@tRecentlyAddedIndexes 
	where	IDENT = @nCounter

	Set @sSQLString = "
	Delete IDENTITYINDEX 
	from   IDENTITYINDEX	
	-- Find out the top @nMaxEntries rows with the latest IdentityIndex.LastAccessed.
	left join  (Select top " + cast(@nMaxEntries as varchar(10)) + " II2.LASTACCESSED, II2.ENTRYID 
	       	    from IDENTITYINDEX II2			 
		    where II2.IDENTITYID = @pnUserIdentityId
		    and   II2.INDEXID = @nCurrentIndex
	       	    order by II2.LASTACCESSED DESC) IDENTITYINDEX2 on IDENTITYINDEX2.ENTRYID = IDENTITYINDEX.ENTRYID 
	-- The number of entries is obtained by counting the IdentityIndex table for the @pnUserIdentityId 
	-- and IndexId required. 
	where IDENTITYINDEX.IDENTITYID = @pnUserIdentityId
	and   IDENTITYINDEX.INDEXID = @nCurrentIndex	
	-- Deletion is required if the actual number of entries exceeds the MaxEntries (@nMaxEntries) defined. 
	and not exists (select * from IDENTITYINDEX where IDENTITYINDEX2.ENTRYID = IDENTITYINDEX.ENTRYID)"    

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@dtLastAccessed	datetime,
					  @pnUserIdentityId 	int,					 
					  @nCurrentIndex	int',
					  @dtLastAccessed	= @dtLastAccessed, 
					  @pnUserIdentityId 	= @pnUserIdentityId,					 
					  @nCurrentIndex	= @nCurrentIndex	

	Set @nCounter = @nCounter + 1		
End

	
Return @nErrorCode
GO

Grant execute on dbo.ip_RegisterAccess to public
GO

