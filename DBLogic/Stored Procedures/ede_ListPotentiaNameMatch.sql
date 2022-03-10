-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ListPotentialNameMatch
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_ListPotentialNameMatch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_ListPotentialNameMatch.'
	Drop procedure [dbo].[ede_ListPotentialNameMatch]
	Print '**** Creating Stored Procedure dbo.ede_ListPotentialNameMatch...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ede_ListPotentialNameMatch
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psName			nvarchar(254),  		-- the main name to be matched against
	@psGivenName		nvarchar(50),			-- the first name to be matched against
	@pnRestrictToOffice	int		= null,		-- if supplied then potential matching names must be associated with this office
	@pbUseStreetAddress	bit             = 0,		-- flags whether the street or postal address details are required
	@pbRemoveNoiseChars	bit		= 0,		-- flags whether noise chars are to be removed before comparison. Note that setting this option ON degrades performance.
	@pnRowCount		int	= 0	output,
	@psRestrictByNameType	nvarchar(3) = '~~~'  -- names are restricted to those whose NAMETYPECLASSIFICATION allows this Name Type.
)
as
-- PROCEDURE:	ede_ListPotentialNameMatch
-- VERSION:	8
-- SCOPE:	
-- DESCRIPTION:	The stored procedure returns a result set of potential matching names and details about these names.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14-Sep-2006  Dw	12338	1	Procedure created
-- 03-Oct-2006	Dw	12338	2	Ordered result set putting exact match first
-- 19-Oct-2006	Dw	12338	3	Removing noise characters was degrading performance significantly so made it optional by adding new parameter.
-- 20-Oct-2006  Dw	12338	4	Improved performance of check where noise characters removed.
-- 24-Oct-2006	Dw	12338	5	A small enhancement to noise character check.
-- 31-Oct-2006	Dw	12338	6	Improved sorting logic
-- 08-Apr-2011	Dw	19340	7	Added new parameter @psRestrictByNameType
-- 07 Jul 2011	DL	RFC10830 8	Specify database collation default to temp table columns of type varchar, nvarchar and char

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode 	int
Declare @sGivenName1 	nvarchar(50)	--first character of the given name
Declare @sNameChunk 	nvarchar(254)	--first block of characters of the main name
Declare @sTrimName	nvarchar(254)	--main name trimmed
Declare	@sSQLString	nvarchar(4000)

Declare @tbMatch table (	NAMENO		int,
				NAMECODE	nvarchar(10) collate database_default,
				NAME		nvarchar(254) collate database_default, 
				FIRSTNAME	nvarchar(50) collate database_default, 
				POSTALADDRESS	int,
				STREETADDRESS	int,
				ADDRESSCODE	int,
				SEARCHKEY1	nvarchar(20) collate database_default,
				SEARCHKEY2	nvarchar(20) collate database_default,
				USEDASFLAG	smallint)

Set @ErrorCode = 0

If @ErrorCode = 0
Begin
	If @psRestrictByNameType is null
	Begin	
		set @psRestrictByNameType = '~~~'
	End

	set @sGivenName1=Upper(Left(LTRIM(@psGivenName),1))
	set @sTrimName=Upper(LTRIM(@psName))
	
	If @psGivenName is null
	Begin
		If (@pbRemoveNoiseChars=1)
        	Begin
			set @sNameChunk=Upper(Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(@psName)),8))

			Insert into @tbMatch(NAMENO, NAMECODE, NAME, FIRSTNAME, POSTALADDRESS, STREETADDRESS, ADDRESSCODE, SEARCHKEY1, SEARCHKEY2, USEDASFLAG)
			Select N.NAMENO, N.NAMECODE, N.NAME, N.FIRSTNAME, N.POSTALADDRESS, N.STREETADDRESS, N.POSTALADDRESS, N.SEARCHKEY1, N.SEARCHKEY2, N.USEDASFLAG 
			from NAME N
			where LEFT(Upper(
			replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(N.NAME	,	' ',''),
						'&',''),
						'(',''),
						')',''),
						'-',''),
						'+',''),
						':',''),
						';',''),
						char(34),''),
						char(39),''),
						',',''),
						'.',''),
						'/',''),
						'\',''),
						'^','')),8)=@sNameChunk
			and (Upper(Left(LTRIM(N.NAME),1))=Upper(Left(LTRIM(@psName),1)) OR Upper(Left(LTRIM(N.NAME),1))= '"' OR Upper(Left(LTRIM(N.NAME),1))= '''')
			-- line above added to improve performance
			-- note that there is a small tradeoff in that names must match on first character unless first char is inverted comma
        	End
		Else Begin
		
			set @sNameChunk=Upper(Left(LTRIM(@psName),8))

			Insert into @tbMatch(NAMENO, NAMECODE, NAME, FIRSTNAME, POSTALADDRESS, STREETADDRESS, ADDRESSCODE, SEARCHKEY1, SEARCHKEY2, USEDASFLAG)
			Select N.NAMENO, N.NAMECODE, N.NAME, N.FIRSTNAME, N.POSTALADDRESS, N.STREETADDRESS, N.POSTALADDRESS, N.SEARCHKEY1, N.SEARCHKEY2, N.USEDASFLAG 
			from NAME N
			where Upper(Left(LTRIM(N.NAME),8))=@sNameChunk
		End

		Set @ErrorCode=@@Error
	End
	Else Begin
		
		If (@pbRemoveNoiseChars=1)
        	Begin
			set @sNameChunk=Upper(Left(dbo.fn_RemoveNoiseCharacters(dbo.fn_RemoveStopWords(@psName)),8))

			Insert into @tbMatch(NAMENO, NAMECODE, NAME, FIRSTNAME, POSTALADDRESS, STREETADDRESS, ADDRESSCODE, SEARCHKEY1, SEARCHKEY2, USEDASFLAG)
			Select N.NAMENO, N.NAMECODE, N.NAME, N.FIRSTNAME, N.POSTALADDRESS, N.STREETADDRESS, N.POSTALADDRESS, N.SEARCHKEY1, N.SEARCHKEY2, N.USEDASFLAG 
			from NAME N
			where LEFT(Upper(
			replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(N.NAME	,	' ',''),
						'&',''),
						'(',''),
						')',''),
						'-',''),
						'+',''),
						':',''),
						';',''),
						char(34),''),
						char(39),''),
						',',''),
						'.',''),
						'/',''),
						'\',''),
						'^','')),8)=@sNameChunk
			and (Upper(Left(LTRIM(N.FIRSTNAME),1))=@sGivenName1
			or (N.FIRSTNAME is null and N.USEDASFLAG not in (0,4)))

        	End
		Else Begin
		
			set @sNameChunk=Upper(Left(LTRIM(@psName),8))

			Insert into @tbMatch(NAMENO, NAMECODE, NAME, FIRSTNAME, POSTALADDRESS, STREETADDRESS, ADDRESSCODE, SEARCHKEY1, SEARCHKEY2, USEDASFLAG)
			Select N.NAMENO, N.NAMECODE, N.NAME, N.FIRSTNAME, N.POSTALADDRESS, N.STREETADDRESS, N.POSTALADDRESS, N.SEARCHKEY1, N.SEARCHKEY2, N.USEDASFLAG
			from NAME N
                	where Upper(Left(LTRIM(N.NAME),8))=@sNameChunk
			and (Upper(Left(LTRIM(N.FIRSTNAME),1))=@sGivenName1
			or (N.FIRSTNAME is null and N.USEDASFLAG not in (0,4)))
		End
		Set @ErrorCode=@@Error
	End
	
	-- use postal address unless flagged to use street address
	If  @ErrorCode=0
	and (@pbUseStreetAddress = 1)
	Begin
		Update @tbMatch set ADDRESSCODE = STREETADDRESS
	End


	-- no office restrictions
	If  @ErrorCode=0
	and @pnRestrictToOffice is NULL
	Begin
		Select N.NAMENO, N.NAMECODE, N.NAME, N.FIRSTNAME, N.ADDRESSCODE, A.STREET1, A.CITY, A.STATE, A.POSTCODE, Y.COUNTRY, 
		N.SEARCHKEY1, N.SEARCHKEY2, N.USEDASFLAG,
		MATCHSTATUS = case when (@sTrimName = Upper(LTRIM(N.NAME)) AND ((@psGivenName = N.FIRSTNAME) OR (@psGivenName is null))) then 4
				   when (Left(@sTrimName,16) = Upper(Left(LTRIM(N.NAME),16)) AND ((@psGivenName = N.FIRSTNAME) OR (@psGivenName is null))) then 2
				   when (Left(@sTrimName,12) = Upper(Left(LTRIM(N.NAME),12)) AND ((@psGivenName = N.FIRSTNAME) OR (@psGivenName is null))) then 1 else 0 end
		from @tbMatch N
		left join ADDRESS A on (N.ADDRESSCODE = A.ADDRESSCODE)
		left join COUNTRY Y on (A.COUNTRYCODE = Y.COUNTRYCODE)
		left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO)
		where NTC.NAMETYPE = @psRestrictByNameType
		and NTC.ALLOW=1
		order by MATCHSTATUS desc, N.NAME

		Select 	@ErrorCode =@@Error,
			@pnRowCount=@@RowCount
	End
	
	-- If the duplicate checking is to be restricted to a specific office then only individuals
	-- who are either marked as belonging to the given office or who have not been assigned an
	-- office at all are to be returned as potential duplicates.
	Else If  @ErrorCode=0
	     and @pnRestrictToOffice is not NULL
	Begin
		Select N.NAMENO, N.NAMECODE, N.NAME, N.FIRSTNAME, N.ADDRESSCODE, A.STREET1, A.CITY, A.STATE, A.POSTCODE, Y.COUNTRY, 
		N.SEARCHKEY1, N.SEARCHKEY2, N.USEDASFLAG,
		MATCHSTATUS = case when (@sTrimName = Upper(LTRIM(N.NAME)) AND ((@psGivenName = N.FIRSTNAME) OR (@psGivenName is null))) then 4
				   when (Left(@sTrimName,16) = Upper(Left(LTRIM(N.NAME),16)) AND ((@psGivenName = N.FIRSTNAME) OR (@psGivenName is null))) then 2
				   when (Left(@sTrimName,12) = Upper(Left(LTRIM(N.NAME),12)) AND ((@psGivenName = N.FIRSTNAME) OR (@psGivenName is null))) then 1 else 0 end
		from @tbMatch N
		left join ADDRESS A on (N.ADDRESSCODE = A.ADDRESSCODE)
		left join COUNTRY Y on (A.COUNTRYCODE = Y.COUNTRYCODE)
		left join TABLEATTRIBUTES T	on (T.PARENTTABLE='NAME'
						and T.TABLETYPE=44
						and T.GENERICKEY=cast(N.NAMENO as varchar))
		left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO)
		where (T.TABLECODE=@pnRestrictToOffice
		or     T.TABLECODE is NULL
		or     N.USEDASFLAG not in (1,5))	-- only Individuals are to have office restriction
		and	NTC.NAMETYPE = @psRestrictByNameType
		and NTC.ALLOW=1
		order by MATCHSTATUS desc, N.NAME

		Select 	@ErrorCode =@@Error,
			@pnRowCount=@@RowCount
	End		
End

Return @ErrorCode
GO

Grant execute on dbo.ede_ListPotentialNameMatch to public
GO