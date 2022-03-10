-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListStatus
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListStatus'
	drop procedure [dbo].[wa_ListStatus]
	print '**** Creating procedure dbo.wa_ListStatus...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

CREATE PROCEDURE [dbo].[wa_ListStatus]

-- search criteria to include
@bPending		tinyint     = NULL,
@bRegistered		tinyint     = NULL,
@bDead			tinyint     = NULL,
@bRenewalFlag		tinyint     = NULL


-- PROCEDURE :	wa_ListStatus
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list from the Status table.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 20/08/2001	MF	Procedure created
--			
AS
begin
	-- disable row counts
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	-- declare variables
	declare @ErrorCode	int
	declare @nOpenBracket	tinyint
	declare @sSql		nvarchar(4000) 	-- the SQL to execute
	declare @sWhere		nvarchar(2048) 	-- the SQL to filter
	declare @sOrder		nvarchar(500)	-- the SQL to order
	
	set @ErrorCode=0

	set @sSql = "SELECT STATUSCODE, INTERNALDESC from STATUS"

	set @sOrder=char(10)+"Order by INTERNALDESC"

	-- Dead cases only
	If   @bDead      =1
	and (@bRegistered=0 or @bRegistered is null)
	and (@bPending   =0 or @bPending    is null)
	begin
		if @sWhere is NULL
			set @sWhere = char(10)+"where	LIVEFLAG=0"
		else
			set @sWhere = @sWhere+char(10)+"and	LIVEFLAG=0"
	end
	
	-- Registered cases only
	else
	if  (@bDead      =0 or @bDead       is null)
	and (@bRegistered=1)
	and (@bPending   =0 or @bPending    is null)
	begin
		if @sWhere is NULL
			set @sWhere = char(10)+"where	LIVEFLAG=1"
				     +char(10)+"and	REGISTEREDFLAG=1"
		else
			set @sWhere = @sWhere+char(10)+"and	LIVEFLAG=1"
				    	     +char(10)+"and	REGISTEREDFLAG=1"
	end

	-- Pending cases only
	else
	if  (@bDead      =0 or @bDead       is null)
	and (@bRegistered=0 or @bRegistered is null)
	and (@bPending   =1)
	begin
		if @sWhere is NULL
			set @sWhere = char(10)+"where	LIVEFLAG=1"
				     +char(10)+"and	REGISTEREDFLAG=0"
		else
			set @sWhere = @sWhere+char(10)+"and	LIVEFLAG=1"
				    	     +char(10)+"and	REGISTEREDFLAG=0"
	end

	-- Pending cases or Registed cases only (not dead)
	else
	if  (@bDead      =0 or @bDead       is null)
	and (@bRegistered=1)
	and (@bPending   =1)
	begin
		if @sWhere is NULL
			set @sWhere = char(10)+"where	LIVEFLAG=1"
		else
			set @sWhere = @sWhere+char(10)+"and	LIVEFLAG=1"
	end

	-- Registered cases or Dead cases
	else
	if  (@bDead      =1)
	and (@bRegistered=1)
	and (@bPending   =0 or @bPending is null)
	begin
		set @nOpenBracket=1

		if @sWhere is NULL
			set @sWhere = char(10)+"where ((LIVEFLAG=1 and REGISTEREDFLAG=1) OR (LIVEFLAG =0)"
		else
			set @sWhere = @sWhere+char(10)+"and   ((LIVEFLAG=1 and REGISTEREDFLAG=1) OR (LIVEFLAG =0)"
	end

	-- Pending cases or Dead cases
	else
	if  (@bDead      =1)
	and (@bRegistered=0 or @bRegistered is null)
	and (@bPending   =1)
	begin
		set @nOpenBracket=1

		if @sWhere is NULL
			set @sWhere = char(10)+"where ((LIVEFLAG=1 and REGISTEREDFLAG=0) OR (LIVEFLAG =0)"
		else
			set @sWhere = @sWhere+char(10)+"and   ((LIVEFLAG=1 and REGISTEREDFLAG=0) OR (LIVEFLAG =0)"
	end

	-- Restrict the Status codes returned to those flagged as Renewals

	if @bRenewalFlag=1
	begin
		if @sWhere is NULL
			set @sWhere = char(10)+"where	RENEWALFLAG=1"
		else
			set @sWhere = @sWhere+char(10)+"and	RENEWALFLAG=1"
	end

	-- Add a closing bracket if required

	if @nOpenBracket=1
		set @sWhere=@sWhere+")"

	set @sSql=@sSql+@sWhere+@sOrder

	exec @ErrorCode=sp_executesql @sSql

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListStatus] to public
go
