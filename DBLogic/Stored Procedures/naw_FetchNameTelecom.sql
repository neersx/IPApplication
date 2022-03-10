-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchNameTelecom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchNameTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchNameTelecom.'
	Drop procedure [dbo].[naw_FetchNameTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_FetchNameTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchNameTelecom
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pbNewRow		bit		= 0,
	@pbMainNumbers		bit		= 0,
	@pnTelecomTypeKey	int		= null,
	@pnCopyFromNameKey	int		= null,
	@psCountryCode		nvarchar(3)	= null
)
as
-- PROCEDURE:	naw_FetchNameTelecom
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the NameTelecom business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 27 Mar 2006	SW	RFC3721	1	Procedure created
-- 02 May 2006	PG	RFC3721	2	Return TelecomKey for @pnNewRow=1
-- 19 Jun 2006	PG	RFC3721	3	Return RowKey for @pnNewRow=1
-- 27 Jun 2006	SW	RFC4036 4 	Suppress duplicate rows
-- 05 Oct 2007	vql	RFC3500	5	Change row key to include telecom type.
-- 14 Nov 2007	PG	RFC3501	6	Return formatted telecom
-- 30 Jan 2008	AT	RFC7369	7	Return default coutnry Isd for mobile phone. 
-- 09 July 2010	ASH	RFC3832	8	Find Main Email of the given @pnCopyFromNameKey.
-- 26 Jul 2010	SF	RFC9563	9	Ensure IsOwner flag is returned as either a 0 or a 1.
-- 11 Apr 2013	DV	R13270	10	Increase the length of nvarchar to 11 when casting or declaring integer
-- 26 May 2015	DV	R47577	11	Return false if REMINDEREMAILS is null
-- 02 Nov 2015	vql	R53910	12	Adjust formatted names logic (DR-15543).
-- 04 Nov 2019	AK	DR-15204	13	returned all telecom of  @pnCopyFromNameKey.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sRowKey	nvarchar(200)
Declare @nTelecode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @pbNewRow = 0 or
	  (@pnTelecomTypeKey is null and @pnCopyFromNameKey is not null)
	Begin

	if (@pnTelecomTypeKey is null and 
		@pnCopyFromNameKey is not null)
		Begin
			set @pnNameKey = @pnCopyFromNameKey
			set @sRowKey   = "CAST(-1 as nvarchar(11))
								+ '^'
							 + CAST(NT.TELECODE as nvarchar(11))	as RowKey,"
		End
	Else
		Begin
			set @sRowKey = "CAST(NT.NAMENO as nvarchar(11))
							+ '^' +
							CAST(T.TELECOMTYPE as nvarchar(11))
							+ '^' +
							CAST(NT.TELECODE as nvarchar(11))	as RowKey,"
		End


		Set @sSQLString = "	Select " + @sRowKey + " 
		
		NT.NAMENO				as NameKey,
		NT.TELECODE				as TelecomKey,
		NT.TELECOMDESC				as TelecomNotes,
		case
			when 
			((T.TELECOMTYPE = 1901 and NT.TELECODE = N.MAINPHONE)
			or (T.TELECOMTYPE = 1902 and NT.TELECODE = N.FAX)
			or (T.TELECOMTYPE = 1903 and NT.TELECODE = N.MAINEMAIL))
			then cast(1 as bit)
			else cast(0 as bit)
		end					as IsMain,
		cast(ISNULL(NT.OWNEDBY,0) as bit)			as IsOwner,
		-- if more than 1 then IsLinked = true, otherwise false
		cast(ISLINK_RESULT.ISLINKED as bit)	as IsLinked,
		NT1.NAMENO				as BelongsToKey,
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null)	as BelongsToName,
		N1.NAMECODE				as BelongsToCode,
		T.TELECOMTYPE				as TelecomTypeKey,
		TC19.[DESCRIPTION]			as TelecomTypeDescription,
		T.ISD					as Isd,
		T.AREACODE				as AreaCode,
		T.TELECOMNUMBER				as TelecomNumber,
		T.EXTENSION				as Extension,
		T.CARRIER				as CarrierKey,
		TC5.[DESCRIPTION]			as CarrierDescription,
		cast(Isnull(T.REMINDEREMAILS,0) as bit)	as IsReminderAddress,
		dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION) as FormattedTelecom
	
		from [NAME] N
		join NAMETELECOM NT 		on (NT.NAMENO = N.NAMENO)
		join TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE)
		left join (	select	MAX(NT1.NAMENO) NAMENO, NT1.TELECODE
				from	NAMETELECOM NT
				join	NAMETELECOM NT1 on (        NT.NAMENO = @pnNameKey
								and NT1.TELECODE = NT.TELECODE
								and NT1.OWNEDBY = 1
								and ISNULL(NT.OWNEDBY,0) = 0)
				group by NT1.TELECODE
				) NT1 on (NT1.TELECODE = NT.TELECODE)
		left join [NAME] N1		on (N1.NAMENO = NT1.NAMENO)
		left join TABLECODES TC5 	on (TC5.TABLECODE = T.CARRIER)
		left join TABLECODES TC19 	on (TC19.TABLECODE = T.TELECOMTYPE)
		-- this derived table calculate if TELECODE IsLinked or not.
		left join (	Select 	NT3.TELECODE	as TELECODE, 
					case  
						when count(NT3.TELECODE) > 1 then 1
						else 0
					end 		as ISLINKED
				from	(Select	TELECODE
					from	NAMETELECOM
					where	NAMENO = @pnNameKey) CODE
				join	NAMETELECOM NT3 on (NT3.TELECODE = CODE.TELECODE)
				group by NT3.TELECODE
				) ISLINK_RESULT	on (NT.TELECODE = ISLINK_RESULT.TELECODE)
		where N.NAMENO = @pnNameKey
		"

		if (@pnTelecomTypeKey is null and @pnCopyFromNameKey is not null)
		Begin 
			set @sSQLString  = @sSQLString + " and		NT.OWNEDBY = 1 "
		END

		-- Add to where clause if only return main numbers
		If @pbMainNumbers = 1 and @pbNewRow = 0
		Begin
			Set @sSQLString = @sSQLString + "
			and ((T.TELECOMTYPE = 1901 and NT.TELECODE = N.MAINPHONE)
			or (T.TELECOMTYPE = 1902 and NT.TELECODE = N.FAX)
			or (T.TELECOMTYPE = 1903 and NT.TELECODE = N.MAINEMAIL))
			"
		End
	
		Set @sSQLString = @sSQLString + "
		order by NameKey, TelecomTypeKey, TelecomTypeDescription, IsMain desc, TelecomNumber, TelecomKey
		"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey		int',
				@pnNameKey	 = @pnNameKey
	End
	Else
	Begin		
			-- Find out the TELECODE of the given @pnCopyFromNameKey with the given @pnTelecomTypeKey
			Set @sSQLString = "
				Select	@nTelecode = 
						case
						when @pnTelecomTypeKey = 1901 then N.MAINPHONE
						when @pnTelecomTypeKey = 1902 then N.FAX
						when @pnTelecomTypeKey = 1903 then N.MAINEMAIL
					end
				from	[NAME] N
				where	N.NAMENO = @pnCopyFromNameKey
				and 	@pnTelecomTypeKey in (1901, 1902,1903)
			"
	
			exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@nTelecode 		int			OUTPUT,
			@pnCopyFromNameKey 	int,
			@pnTelecomTypeKey	int',
			@nTelecode 		= @nTelecode		OUTPUT,
			@pnCopyFromNameKey 	= @pnCopyFromNameKey,
			@pnTelecomTypeKey	= @pnTelecomTypeKey
				
			-- if there is a valid telecom to copy from
			If @nTelecode is not null
			Begin
				Set @sSQLString = "
				Select
				CAST(-1 as nvarchar(11))
				 + '^'
				 + CAST(NT.TELECODE as nvarchar(11))	as RowKey,
				@pnNameKey				as NameKey,
				NT.TELECODE				as TelecomKey,
				@pnTelecomTypeKey			as TelecomTypeKey,
				TC19.[DESCRIPTION]			as TelecomTypeDescription,
				cast(1 as bit)		 		as IsMain,
				cast(0 as bit)				as IsOwner,
				cast(1 as bit)				as IsLinked,
				NT.NAMENO				as BelongsToKey,
				dbo.fn_FormatNameUsingNameNo(N.NAMENO,null)	as BelongsToName,
				N.NAMECODE				as BelongsToCode,
				T.ISD					as Isd,
				T.AREACODE				as AreaCode,
				T.TELECOMNUMBER				as TelecomNumber,
				T.EXTENSION				as Extension,
				T.CARRIER				as CarrierKey,
				TC5.[DESCRIPTION]			as CarrierDescription,
				cast(Isnull(T.REMINDEREMAILS,0) as bit)	as IsReminderAddress
	
				from		NAMETELECOM NT
				join		[NAME] N		on (N.NAMENO = NT.NAMENO)
				join		TELECOMMUNICATION T	on (T.TELECODE = NT.TELECODE)
				left join	TABLECODES TC5 		on (TC5.TABLECODE = T.CARRIER)
				left join	TABLECODES TC19 	on (TC19.TABLECODE = @pnTelecomTypeKey)
				where		NT.TELECODE = @nTelecode
				and		NT.OWNEDBY = 1
				"
	
				exec @nErrorCode=sp_executesql @sSQLString,
						N'
						@pnNameKey		int,
						@pnTelecomTypeKey	int,
						@pnCopyFromNameKey	int,
						@psCountryCode		nvarchar(3),
						@nTelecode		int',
						@pnNameKey	 	= @pnNameKey,
						@pnTelecomTypeKey	= @pnTelecomTypeKey,
						@pnCopyFromNameKey	= @pnCopyFromNameKey,
						@psCountryCode		= @psCountryCode,
						@nTelecode		= @nTelecode
				
			End
			Else
			-- else, return default values if no valid telecom to copy from
			Begin
	
				Set @sSQLString = "
				Select
				@pnNameKey			as NameKey,
				null 				as TelecomKey,
				@pnTelecomTypeKey		as TelecomTypeKey,
				TC19.[DESCRIPTION]		as TelecomTypeDescription,
				case 
					when (@pbMainNumbers = 1)
					then cast(1 as bit)
					else cast(0 as bit)
				end			 	as IsMain,
				cast(1 as bit)			as IsOwner,
				cast(0 as bit)			as IsLinked,
				null				as BelongsToKey,
				null				as BelongsToName,
				null				as BelongsToCode,
				-- if telecom type is phone or fax, return ISD, else null
				case
					when	(@pnTelecomTypeKey in (1901, 1902, 1906))
					then 	C.ISD
					else 	null
				end				as Isd,
				null				as AreaCode,
				null				as TelecomNumber,
				null				as Extension,
				null				as CarrierKey,
				null				as CarrierDescription,
				null				as IsReminderAddress
	
				from 	TABLECODES TC19 
				left	join COUNTRY C		on (C.COUNTRYCODE = @psCountryCode)
				where	(TC19.TABLECODE = @pnTelecomTypeKey)
				"
	
				exec @nErrorCode=sp_executesql @sSQLString,
						N'
						@pnNameKey		int,
						@pnTelecomTypeKey	int,
						@pbMainNumbers		bit,
						@psCountryCode		nvarchar(3)',
						@pnNameKey	 	= @pnNameKey,
						@pnTelecomTypeKey	= @pnTelecomTypeKey,
						@pbMainNumbers		= @pbMainNumbers,
						@psCountryCode		= @psCountryCode
			End		
		
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchNameTelecom to public
GO
