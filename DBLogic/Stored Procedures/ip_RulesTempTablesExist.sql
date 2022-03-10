-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesTempTablesExist
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_RulesTempTablesExist]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_RulesTempTablesExist.'
	Drop procedure [dbo].[ip_RulesTempTablesExist]
End
Print '**** Creating Stored Procedure dbo.ip_RulesTempTablesExist...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ip_RulesTempTablesExist
	@psUserName			nvarchar(40),  -- mandatory
	@pbAllTempTablesExists		bit OUTPUT
AS

-- VERSION :	3
-- DESCRIPTION:	This procedure checks if all the IMPORTED_* temp tables
--		for the specified user exists
-- EXPECTS:	@psUserName
-- RETURNS:	Errorcode
-- SCOPE:	CPA Inpro
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 1/03/2005	PK	10985	1	Initial creation
-- 24 Oct 2006	MF	13466	2	Two new tables INSTRUCTIONTYPE and INSTRUCTIONLABEL
-- 16 Aug 2007	MF	15018	3	New table TABLEATTRIBUTES

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare @sSQLString		nvarchar(4000),
	@ErrorCode		int,
	@nTranCountStart	int,
	@sUserName		nvarchar(40),
	@bInterimTableExists	bit

-- Initialize variables
Set @sUserName	= @psUserName
Set @ErrorCode = 0
Set @pbAllTempTablesExists = 0


If @ErrorCode=0
Begin
-- Check existence of Imported Table.
If @ErrorCode=0
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('"+@sUserName+".Imported_ACTIONS')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects
			 where id = object_id('"+@sUserName+".Imported_ADJUSTMENT')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('"+@sUserName+".Imported_APPLICATIONBASIS')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CASECATEGORY')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CASERELATION')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CHECKLISTITEM')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CHECKLISTLETTER')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CHECKLISTS')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRY')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRYFLAGS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRYGROUP'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRYTEXT'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_CRITERIA'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DATESLOGIC'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DETAILCONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DETAILDATES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DETAILLETTERS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DUEDATECALC'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_EVENTCONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_EVENTS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_INHERITS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_INSTRUCTIONLABEL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_INSTRUCTIONTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
 	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_ITEM'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_LETTER'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_NUMBERTYPES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_PROPERTYTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_QUESTION'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_RELATEDEVENTS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_SCREENCONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_SITECONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_STATE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_STATUS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_SUBTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TABLEATTRIBUTES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TABLECODES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TABLETYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TMCLASS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDACTDATES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDACTION'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDATENUMBERS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDBASIS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDCATEGORY'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDCHECKLISTS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDPROPERTY'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDRELATIONSHIPS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDSTATUS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDSUBTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_REMINDERS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @pbAllTempTablesExists = 1
end

End

RETURN @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ip_RulesTempTablesExist to public
go
