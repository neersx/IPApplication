-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_SwitchDatabaseLanguage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_SwitchDatabaseLanguage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_SwitchDatabaseLanguage.'
	Drop procedure [dbo].[ip_SwitchDatabaseLanguage]
End
Print '**** Creating Stored Procedure dbo.ip_SwitchDatabaseLanguage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_SwitchDatabaseLanguage
(
	@psSwtichOutCulture	nvarchar(10)	= null, 	-- The culture (language and region) in which the main data in the database is held 
								-- and will be switched to the translation table, there will be no switch out if param not provided.
	@psSwitchInCulture	nvarchar(10),	-- Mandatory	   The culture (language and region) which is to become the main language of the database.
	@pnDebugFlag		tinyint		= 0 		-- 0=off,1=trace execution,2=dump data
)
as
-- PROCEDURE:	ip_SwitchDatabaseLanguage
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	The data in the main database tables is in the main language of the firm.
--		Translations of the data may be held in multi-language database structures.
--		This stored procedure switches one of the translations into the main database tables.
--		It optionally allows the main database language to be moved to a translation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Aug 2006	SW	RFC4178	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 25 Oct 2012 DL	R12881	3	Script error when running the translation test script on IPRULE

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sTableName	nvarchar(30)
Declare @nTSID		int
Declare @sShortColumn	nvarchar(30)
Declare @sLongColumn	nvarchar(30)
Declare @sSQLString	nvarchar(4000)
Declare @sSQLFragment	nvarchar(4000)
Declare @sSQLFragment2	nvarchar(4000)
Declare @sChildTableSqlFragment	nvarchar(4000)
Declare @sTIDColumn	nvarchar(30)
Declare	@nShortColumnLength	int
Declare @nTransactionCountStart	int
Declare @sSwitchInParentCulture	nvarchar(10)

Declare @sTrigNameUpdate	nvarchar(255)

-- Initialise variables
Set @nErrorCode = 0
Set @sSwitchInParentCulture = dbo.fn_GetParentCulture(@psSwitchInCulture)

If @nErrorCode = 0
Begin
	Select @nTransactionCountStart = @@TRANCOUNT
	BEGIN TRANSACTION
End

-- Switch out data from data structure to TRANSLATEDTEXT
If @nErrorCode = 0
and @psSwtichOutCulture is not null
Begin
	-- Initialize first table to @sTableName
	Set @sSQLString = "
		Select	@nTSID = min(TRANSLATIONSOURCEID)
		from	TRANSLATIONSOURCE
		where	INUSE = 1"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nTSID		int		OUTPUT',
				  @nTSID		= @nTSID	OUTPUT

	-- loop thru all the tables that have translation
	While @nTSID is not null and @nErrorCode = 0
	Begin

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Select	@sTableName = TS.TABLENAME,
					@sTIDColumn = TS.TIDCOLUMN,
					@sShortColumn = TS.SHORTCOLUMN,
					@sLongColumn = TS.LONGCOLUMN
				from	TRANSLATIONSOURCE TS
				where	TS.TRANSLATIONSOURCEID = @nTSID"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@sTableName		nvarchar(30)		OUTPUT,
						  @sTIDColumn		nvarchar(30)		OUTPUT,
						  @sShortColumn		nvarchar(30)		OUTPUT,
						  @sLongColumn		nvarchar(30)		OUTPUT,
						  @nTSID		int',
						  @sTableName		= @sTableName		OUTPUT,
						  @sTIDColumn		= @sTIDColumn		OUTPUT,
						  @sShortColumn		= @sShortColumn		OUTPUT,
						  @sLongColumn		= @sLongColumn		OUTPUT,
						  @nTSID		= @nTSID
		End

		-- Insert text from data structure to TRANSLATEDTEXT 
		If @nErrorCode = 0
		Begin
			If (    @sShortColumn is not null
			    and @sLongColumn is not null)
			Begin
				Set @sSQLString = "
					Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT, LONGTEXT, HASSOURCECHANGED)
					Select	TAB.["+@sTIDColumn+"],
						@psSwtichOutCulture,
						case when LEN(ISNULL(NULLIF(Cast(TAB.["+@sLongColumn+"] as nvarchar(4000)), ''), TAB.["+@sShortColumn+"])) <= 3200
						     then ISNULL(NULLIF(TAB.["+@sLongColumn+"], ''), TAB.["+@sShortColumn+"])
						     else NULL
						end,
						case when LEN(ISNULL(NULLIF(Cast(TAB.["+@sLongColumn+"] as nvarchar(4000)), ''), TAB.["+@sShortColumn+"])) > 3200
						     then ISNULL(NULLIF(TAB.["+@sLongColumn+"], ''), TAB.["+@sShortColumn+"])
						     else NULL
						end,
						0
					from	["+@sTableName+"] TAB
					left join TRANSLATEDTEXT TT on (TT.TID = TAB.["+@sTIDColumn+"] and TT.CULTURE = @psSwtichOutCulture)
					where	TT.TID is NULL
					and	TAB.["+@sTIDColumn+"] is not NULL"

				Exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSwtichOutCulture		nvarchar(10)',
							  @psSwtichOutCulture		= @psSwtichOutCulture

			End
			Else
			Begin
				Set @sSQLString = "
					Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT, LONGTEXT, HASSOURCECHANGED)
					Select	TAB.["+@sTIDColumn+"],
						@psSwtichOutCulture,
						case when LEN(Cast(TAB.["+ISNULL(@sLongColumn, @sShortColumn)+"] as nvarchar(4000))) <= 3200
						     then TAB.["+ISNULL(@sLongColumn, @sShortColumn)+"]
						     else NULL
						end,
						case when LEN(Cast(TAB.["+ISNULL(@sLongColumn, @sShortColumn)+"] as nvarchar(4000))) > 3200
						     then TAB.["+ISNULL(@sLongColumn, @sShortColumn)+"]
						     else NULL
						end,
						0
					from	["+@sTableName+"] TAB
					left join TRANSLATEDTEXT TT on (TT.TID = TAB.["+@sTIDColumn+"] and TT.CULTURE = @psSwtichOutCulture)
					where	TT.TID is NULL
					and	TAB.["+@sTIDColumn+"] is not NULL"

				Exec @nErrorCode = sp_executesql @sSQLString,
							N'@psSwtichOutCulture		nvarchar(10)',
							  @psSwtichOutCulture		= @psSwtichOutCulture
	
			End
 		End

		-- Move to next table	
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Select	@nTSID = min(TRANSLATIONSOURCEID)
				from	TRANSLATIONSOURCE
				where	TRANSLATIONSOURCEID > @nTSID
				and	INUSE = 1"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@nTSID		int		OUTPUT',
						  @nTSID		= @nTSID	OUTPUT
		End
	End
End

-- Switch in data from TRANSLATEDTEXT to data structure

-- Initialize first TRANSLATIONSOURCEID to variable
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@nTSID = min(TS.TRANSLATIONSOURCEID)
		from	TRANSLATIONSOURCE TS
		where	TS.INUSE = 1"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nTSID			int			OUTPUT',
				  @nTSID			= @nTSID		OUTPUT
End

-- loop thru all the tables that have translation
While @nTSID is not null and @nErrorCode = 0
Begin		
	-- Assign values from TRANSLATIONSOURCE
	-- Find out if there is a trigger namely tU_@sTableName_Translation
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
			Select	@sTableName = TS.TABLENAME,
				@sTIDColumn = TS.TIDCOLUMN,
				@sShortColumn = TS.SHORTCOLUMN,
				@sLongColumn = TS.LONGCOLUMN,
				@sTrigNameUpdate = TU.[name]
			from	TRANSLATIONSOURCE TS
			left join sysobjects PARENT on (PARENT.[name] = TS.TABLENAME)
			left join sysobjects TU on (TU.parent_obj = PARENT.[id] and TU.[name] = 'tU_'+TS.TABLENAME+'_Translation')
			where	TS.TRANSLATIONSOURCEID = @nTSID"

		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@sTableName		nvarchar(30)		OUTPUT,
					  @sTIDColumn		nvarchar(30)		OUTPUT,
					  @sShortColumn		nvarchar(30)		OUTPUT,
					  @sLongColumn		nvarchar(30)		OUTPUT,
					  @sTrigNameUpdate	nvarchar(255)		OUTPUT,
					  @nTSID		int',
					  @sTableName		= @sTableName		OUTPUT,
					  @sTIDColumn		= @sTIDColumn		OUTPUT,
					  @sShortColumn		= @sShortColumn		OUTPUT,
					  @sLongColumn		= @sLongColumn		OUTPUT,
					  @sTrigNameUpdate	= @sTrigNameUpdate	OUTPUT,
					  @nTSID		= @nTSID
	End

	-- Disable trigger before translating table @sTableName if any
	If @nErrorCode = 0 and @sTrigNameUpdate is not null
	Begin
		Set @sSQLString = "
			Alter table ["+@sTableName+"] DISABLE TRIGGER "+ @sTrigNameUpdate

		Exec @nErrorCode = sp_executesql @sSQLString

	End

	/*
	   Some of the data to be switched is the primary key of the table being processed. 
	   If this occurs, the procedure needs to ensure that corresponding changes to child tables are made
	   and that foreign key constraints are disabled until the tables are consistent again.
	   A simple hard coded solution is implemented.
	 */
	If @nErrorCode = 0
	and @sTableName in ('APPLICATIONS', 'MENU', 'REPORTS', 'SECURITYPROFILE', 'SECURITYTEMPLATE', 'SECURITYGROUP')
	Begin
		-- Define the core sql fragment code
		Set @sSQLFragment = "
			Cast(COALESCE(TT.LONGTEXT, TT.SHORTTEXT, TTP.LONGTEXT, TTP.SHORTTEXT) as nvarchar("

		Set @sSQLFragment2 = "))
			from	["+@sTableName+"]
			left join TRANSLATEDTEXT TT	on (    TT.TID = ["+@sTableName+"].["+@sTIDColumn+"]
							    and TT.CULTURE = @psSwitchInCulture 
							    and TT.HASSOURCECHANGED = 0)
			left join TRANSLATEDTEXT TTP 	on (    TTP.TID = ["+@sTableName+"].["+@sTIDColumn+"] 
							    and TTP.CULTURE = @sSwitchInParentCulture 
							    and TTP.HASSOURCECHANGED = 0)
			where COALESCE(TT.LONGTEXT, TT.SHORTTEXT, TTP.LONGTEXT, TTP.SHORTTEXT) is not null
			"
			
		If (@nErrorCode = 0
		and @sTableName = 'APPLICATIONS'
		and @sShortColumn = 'APPLICATIONNAME')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('USERAPPLICATIONS'),'APPLICATIONNAME','PRECISION')

			Alter table USERAPPLICATIONS NOCHECK CONSTRAINT R_1306

			Set @sChildTableSqlFragment = "
				Update	[USERAPPLICATIONS]
				set	[APPLICATIONNAME] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 + 
				"and ["+@sTableName+"].["+@sShortColumn+"] = [USERAPPLICATIONS].[APPLICATIONNAME]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
			If  @pnDebugFlag>0
			Begin
				RAISERROR ('Error with: %s',
						0, 1, @sSQLString) with NOWAIT
			End
		End

		If (@nErrorCode = 0
		and @sTableName = 'APPLICATIONS'
		and @sShortColumn = 'APPLICATIONNAME')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('DATAWIZARD'),'APPLICATIONNAME','PRECISION')

			Alter table DATAWIZARD NOCHECK CONSTRAINT R_1122

			Set @sChildTableSqlFragment = "
				Update	[DATAWIZARD]
				set	[APPLICATIONNAME] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 + 
				"and ["+@sTableName+"].["+@sShortColumn+"] = [DATAWIZARD].[APPLICATIONNAME]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
			If  @pnDebugFlag>0
			Begin
				RAISERROR ('Error with: %s',
						0, 1, @sSQLString) with NOWAIT
			End
		End

		If (@nErrorCode = 0
		and @sTableName = 'APPLICATIONS'
		and @sShortColumn = 'APPLICATIONNAME')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('GROUPAPPLICATION'),'APPLICATIONNAME','PRECISION')

			Alter table GROUPAPPLICATION NOCHECK CONSTRAINT R_1307

			Set @sChildTableSqlFragment = "
				Update	[GROUPAPPLICATION]
				set	[APPLICATIONNAME] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [GROUPAPPLICATION].[APPLICATIONNAME]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'APPLICATIONS'
		and @sShortColumn = 'APPLICATIONNAME')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('LINKAPPLICATIONS'),'APPLICATIONNAME','PRECISION')

			Alter table LINKAPPLICATIONS NOCHECK CONSTRAINT R_1492

			Set @sChildTableSqlFragment = "
				Update	[LINKAPPLICATIONS]
				set	[APPLICATIONNAME] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [LINKAPPLICATIONS].[APPLICATIONNAME]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'APPLICATIONS'
		and @sShortColumn = 'APPLICATIONNAME')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('LINKAPPLICATIONS'),'EXTERNALAPPNAME','PRECISION')

			Alter table LINKAPPLICATIONS NOCHECK CONSTRAINT R_1491

			Set @sChildTableSqlFragment = "
				Update	[LINKAPPLICATIONS]
				set	[EXTERNALAPPNAME] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [LINKAPPLICATIONS].[EXTERNALAPPNAME]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'MENU'
		and @sShortColumn = 'MENUNAME')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('APPLICATIONS'),'MENUNAME','PRECISION')

			Alter table APPLICATIONS NOCHECK CONSTRAINT R_1443

			Set @sChildTableSqlFragment = "
				Update	[APPLICATIONS]
				set	[MENUNAME] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [APPLICATIONS].[MENUNAME]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'REPORTS'
		and @sShortColumn = 'REPORTNAME')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('REPORTCOLUMNS'),'REPORTNAME','PRECISION')

			Alter table REPORTCOLUMNS NOCHECK CONSTRAINT R_1360

			Set @sChildTableSqlFragment = "
				Update	[REPORTCOLUMNS]
				set	[REPORTNAME] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [REPORTCOLUMNS].[REPORTNAME]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'SECURITYPROFILE'
		and @sShortColumn = 'PROFILE')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('USERPROFILES'),'PROFILE','PRECISION')

			Alter table USERPROFILES NOCHECK CONSTRAINT R_1312

			Set @sChildTableSqlFragment = "
				Update	[USERPROFILES]
				set	[PROFILE] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [USERPROFILES].[PROFILE]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'SECURITYPROFILE'
		and @sShortColumn = 'PROFILE')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('SECURITYTEMPLATE'),'PROFILE','PRECISION')

			Alter table SECURITYTEMPLATE NOCHECK CONSTRAINT R_1308

			Set @sChildTableSqlFragment = "
				Update	[SECURITYTEMPLATE]
				set	[PROFILE] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [SECURITYTEMPLATE].[PROFILE]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'SECURITYPROFILE'
		and @sShortColumn = 'PROFILE')
		Begin
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('GROUPPROFILES'),'PROFILE','PRECISION')

			Alter table GROUPPROFILES NOCHECK CONSTRAINT R_1311

			Set @sChildTableSqlFragment = "
				Update	[GROUPPROFILES]
				set	[PROFILE] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [GROUPPROFILES].[PROFILE]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'SECURITYTEMPLATE'
		and @sShortColumn = 'PROFILE')
		Begin			
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('TEMPLATECOLUMNS'),'PROFILE','PRECISION')

			Alter table TEMPLATECOLUMNS NOCHECK CONSTRAINT R_1326

			Set @sChildTableSqlFragment = "
				Update	[TEMPLATECOLUMNS]
				set	[PROFILE] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [TEMPLATECOLUMNS].[PROFILE]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'SECURITYGROUP'
		and @sShortColumn = 'SECURITYGROUP')
		Begin			
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('GROUPAPPLICATION'),'SECURITYGROUP','PRECISION')

			Alter table GROUPAPPLICATION NOCHECK CONSTRAINT R_1304

			Set @sChildTableSqlFragment = "
				Update	[GROUPAPPLICATION]
				set	[SECURITYGROUP] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [GROUPAPPLICATION].[SECURITYGROUP]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'SECURITYGROUP'
		and @sShortColumn = 'SECURITYGROUP')
		Begin			
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('GROUPPROFILES'),'SECURITYGROUP','PRECISION')

			Alter table GROUPPROFILES NOCHECK CONSTRAINT R_1310

			Set @sChildTableSqlFragment = "
				Update	[GROUPPROFILES]
				set	[SECURITYGROUP] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [GROUPPROFILES].[SECURITYGROUP]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End

		If (@nErrorCode = 0
		and @sTableName = 'SECURITYGROUP'
		and @sShortColumn = 'SECURITYGROUP')
		Begin			
			-- Find out max length of structure's shortcolumn
			Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID('ASSIGNEDUSERS'),'SECURITYGROUP','PRECISION')

			Alter table ASSIGNEDUSERS NOCHECK CONSTRAINT R_906

			Set @sChildTableSqlFragment = "
				Update	[ASSIGNEDUSERS]
				set	[SECURITYGROUP] = "
	
			Set @sSQLString = @sChildTableSqlFragment + @sSQLFragment + cast(@nShortColumnLength as nvarchar(10)) + @sSQLFragment2 +
				"and ["+@sTableName+"].["+@sShortColumn+"] = [ASSIGNEDUSERS].[SECURITYGROUP]"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture
		End
	End

	-- Find out max length of structure's shortcolumn
	Set @nShortColumnLength = COLUMNPROPERTY(OBJECT_ID(@sTableName),@sShortColumn,'PRECISION')
	-- RFC12881 when column precision is of type max the @nShortColumnLength is set to 9000 to enable len comparision
	if @nShortColumnLength = -1
		set @nShortColumnLength = 9000

	If (    @sShortColumn is not null
	    and @sLongColumn is not null)
	Begin

		-- Update for 0 < text length <= @nShortColumnLength
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Update	["+@sTableName+"]
				set	["+@sShortColumn+"] = COALESCE(TT.SHORTTEXT, TTP.SHORTTEXT),
				        ["+@sLongColumn+"] = NULL
				from	["+@sTableName+"]
				left join TRANSLATEDTEXT TT 	on (    TT.TID = ["+@sTableName+"].["+@sTIDColumn+"] 
								    and TT.CULTURE = @psSwitchInCulture
								    and TT.HASSOURCECHANGED = 0)
				left join TRANSLATEDTEXT TTP 	on (    TTP.TID = ["+@sTableName+"].["+@sTIDColumn+"]
								    and TTP.CULTURE = @sSwitchInParentCulture
								    and TTP.HASSOURCECHANGED = 0
								    and TT.TID is NULL)
				where	@nShortColumnLength >= LEN(COALESCE(TT.SHORTTEXT, TTP.SHORTTEXT))
				and	LEN(COALESCE(TT.SHORTTEXT, TTP.SHORTTEXT)) > 0
				"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10),
						  @nShortColumnLength		int',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture,
						  @nShortColumnLength		= @nShortColumnLength

		End

		-- Update for text length > @nShortColumnLength
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Update	["+@sTableName+"]
				set	["+@sShortColumn+"] = NULL,
				        ["+@sLongColumn+"] = COALESCE(TT.SHORTTEXT, TTP.SHORTTEXT)
				from	["+@sTableName+"]
				left join TRANSLATEDTEXT TT 	on (    TT.TID = ["+@sTableName+"].["+@sTIDColumn+"]
								    and TT.CULTURE = @psSwitchInCulture
								    and TT.HASSOURCECHANGED = 0)
				left join TRANSLATEDTEXT TTP 	on (    TTP.TID = ["+@sTableName+"].["+@sTIDColumn+"]
								    and TTP.CULTURE = @sSwitchInParentCulture
								    and TTP.HASSOURCECHANGED = 0
								    and TT.TID is NULL)
				where	LEN(COALESCE(TT.SHORTTEXT, TTP.SHORTTEXT)) > @nShortColumnLength
				"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10),
						  @nShortColumnLength		int',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture,
						  @nShortColumnLength		= @nShortColumnLength
		End

		-- Update the rest (only thing left here is text length = 0)
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
				Update	["+@sTableName+"]
				set	["+@sShortColumn+"] = NULL,
				        ["+@sLongColumn+"] = COALESCE(TT.LONGTEXT, TTP.LONGTEXT)
				from	["+@sTableName+"]
				left join TRANSLATEDTEXT TT 	on (    TT.TID = ["+@sTableName+"].["+@sTIDColumn+"] 
								    and TT.CULTURE = @psSwitchInCulture 
								    and TT.HASSOURCECHANGED = 0)
				left join TRANSLATEDTEXT TTP 	on (    TTP.TID = ["+@sTableName+"].["+@sTIDColumn+"] 
								    and TTP.CULTURE = @sSwitchInParentCulture 
								    and TTP.HASSOURCECHANGED = 0
								    and TT.TID is NULL)
				where	LEN(COALESCE(TT.SHORTTEXT, TTP.SHORTTEXT)) = 0
				and	COALESCE(TT.LONGTEXT, TTP.LONGTEXT) is not NULL"

			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture

		End
	End
	Else
	-- If @sShortColumn is null or @sLongColumn is null
	Begin
		If @nErrorCode = 0
		Begin
			-- RFC12881 when column precision is of type max the @nShortColumnLength is set to 9000 to enable len comparision.  
			-- The type however should be set to (max) when applying conversion.  -- as nvarchar("+cast(@nShortColumnLength as varchar(10))
			Set @sSQLString = "
				Update	["+@sTableName+"]
				set	["+ISNULL(@sLongColumn, @sShortColumn)+"] = "+
				case when @sLongColumn is not null
				     then "COALESCE(TT.LONGTEXT, TT.SHORTTEXT, TTP.LONGTEXT, TTP.SHORTTEXT)"
				     else "cast(COALESCE(TT.SHORTTEXT, TT.LONGTEXT, TTP.SHORTTEXT, TTP.LONGTEXT) as nvarchar("
						 +case when @nShortColumnLength = 9000 then 'max' else cast(@nShortColumnLength as varchar(10)) end+"))"
				end+"
				from	["+@sTableName+"]
				left join TRANSLATEDTEXT TT	on (    TT.TID = ["+@sTableName+"].["+@sTIDColumn+"]
								    and TT.CULTURE = @psSwitchInCulture 
								    and TT.HASSOURCECHANGED = 0)
				left join TRANSLATEDTEXT TTP 	on (    TTP.TID = ["+@sTableName+"].["+@sTIDColumn+"] 
								    and TTP.CULTURE = @sSwitchInParentCulture 
								    and TTP.HASSOURCECHANGED = 0)
				where "+
				case when @sLongColumn is not null
				     then "COALESCE(TT.LONGTEXT, TT.SHORTTEXT, TTP.LONGTEXT, TTP.SHORTTEXT)"
				     else "COALESCE(TT.SHORTTEXT, TT.LONGTEXT, TTP.SHORTTEXT, TTP.LONGTEXT)"
				end+" is not null
				"
			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psSwitchInCulture		nvarchar(10),
						  @sSwitchInParentCulture	nvarchar(10)',
						  @psSwitchInCulture		= @psSwitchInCulture,
						  @sSwitchInParentCulture	= @sSwitchInParentCulture

		End
	End

	-- Enable trigger after translating table @sTableName if any
	If @nErrorCode = 0 and @sTrigNameUpdate is not null
	Begin
		Set @sSQLString = "
			Alter table ["+@sTableName+"] ENABLE TRIGGER "+ @sTrigNameUpdate

		Exec @nErrorCode = sp_executesql @sSQLString

	End

	-- Hard code enable constraints for special tables
	If @sTableName = 'APPLICATIONS' and @sTIDColumn = 'APPLICATIONNAME'
	Begin
		Alter table USERAPPLICATIONS CHECK CONSTRAINT R_1306
		Alter table DATAWIZARD CHECK CONSTRAINT R_1122
		Alter table GROUPAPPLICATION CHECK CONSTRAINT R_1307
		Alter table LINKAPPLICATIONS CHECK CONSTRAINT R_1492
		Alter table LINKAPPLICATIONS CHECK CONSTRAINT R_1491
	End

	If @sTableName = 'MENU' and @sTIDColumn = 'MENUNAME'
	Begin
		Alter table APPLICATIONS CHECK CONSTRAINT R_1443
	End

	If @sTableName = 'REPORTS' and @sTIDColumn = 'REPORTNAME'
	Begin
		Alter table REPORTCOLUMNS CHECK CONSTRAINT R_1360
	End

	If @sTableName = 'SECURITYPROFILE' and @sTIDColumn = 'PROFILE'
	Begin
		Alter table USERPROFILES CHECK CONSTRAINT R_1312
		Alter table SECURITYTEMPLATE CHECK CONSTRAINT R_1308
		Alter table GROUPPROFILES CHECK CONSTRAINT R_1311
	End

	If @sTableName = 'SECURITYTEMPLATE' and @sTIDColumn = 'PROFILE'
	Begin
		Alter table TEMPLATECOLUMNS CHECK CONSTRAINT R_1326
	End

	If @sTableName = 'SECURITYGROUP' and @sTIDColumn = 'SECURITYGROUP'
	Begin
		Alter table GROUPAPPLICATION NOCHECK CONSTRAINT R_1304
		Alter table GROUPPROFILES NOCHECK CONSTRAINT R_1310
		Alter table ASSIGNEDUSERS NOCHECK CONSTRAINT R_906
	End
			
	-- Move to next table	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
			Select	@nTSID = min(TS.TRANSLATIONSOURCEID)
			from	TRANSLATIONSOURCE TS
			where	TS.TRANSLATIONSOURCEID > @nTSID
			and	TS.INUSE = 1"

		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@nTSID			int			OUTPUT',
					  @nTSID			= @nTSID		OUTPUT

	End

End

-- Remove text in switched in culture from TRANSLATEDTEXT table
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Delete	TRANSLATEDTEXT
		from	TRANSLATEDTEXT
		join	TRANSLATEDITEMS TI on (TI.TID = TRANSLATEDTEXT.TID)
		join	TRANSLATIONSOURCE TS on (TS.TRANSLATIONSOURCEID = TI.TRANSLATIONSOURCEID)
		where	TS.INUSE = 1
		and	TRANSLATEDTEXT.CULTURE = @psSwitchInCulture"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psSwitchInCulture		nvarchar(10)',
				  @psSwitchInCulture		= @psSwitchInCulture

End

-- Set the SITECONTROL to switched in culture
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Update	SITECONTROL
		set	COLCHARACTER = @psSwitchInCulture
		where	CONTROLID = 'Database Culture'"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psSwitchInCulture		nvarchar(10)',
				  @psSwitchInCulture		= @psSwitchInCulture
End

If @@TRANCOUNT > @nTransactionCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	else
		ROLLBACK TRANSACTION
End

Return @nErrorCode
GO

Grant execute on dbo.ip_SwitchDatabaseLanguage to public
GO
