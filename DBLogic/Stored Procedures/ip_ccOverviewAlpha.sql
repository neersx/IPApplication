-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ccOverviewAlpha
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ccOverviewAlpha]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_ccOverviewAlpha.'
	drop procedure dbo.ip_ccOverviewAlpha
	print '**** Creating procedure dbo.ip_ccOverviewAlpha...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE [dbo].[ip_ccOverviewAlpha]
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_ccOverviewAlpha
-- VERSION :	1
-- DESCRIPTION:	Returns the the Overview for All of the trips sorted by table name
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
--  11 June 2012	AvdA	1	Procedure created based on ip_ccOverviewAll (but sort this alpha)
--

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF

-- Prerequisite that the CCImport_OVERVIEW table has been loaded

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString0		nvarchar(4000)
Declare @sSQLString1		nvarchar(4000)
Declare @sSQLString2		nvarchar(4000)
Declare @sSQLString3		nvarchar(4000)
Declare @sSQLString4		nvarchar(4000)
Declare @sSQLString5		nvarchar(4000)

Declare	@ErrorCode			int
Declare	@nTabno	 		int 

Set @ErrorCode=0

-- Function 1 - Data Comparison
If @ErrorCode=0
and @pnFunction=1
	begin
		set @sSQLString="select 2 as Switch,
			'X' as Match,
			TABLENAME,
			sum(NEW) as [Inserts (I)],
			sum(MISSING) as [Deletes (D)],
			sum(CHANGE) as [Updates (U)],
			sum(MATCH) as [Matches]
		from
			CCImport_Overview
		group by
			TABLENAME
		order by 3"
		
		select isnull(@sSQLString,''), isnull(@sSQLString1,''),isnull(@sSQLString2,''), isnull(@sSQLString3,''),isnull(@sSQLString4,''), isnull(@sSQLString5,'')
		
		Select	@ErrorCode=@@Error,@pnRowCount=@@rowcount
	End
	
-- @pnFunction = 3 supplies the statement to collect the system keys if
-- there is a primary key associated with this tab which may be mapped.
-- ( no mapping is allowed for CopyConfig - return null)
If  @ErrorCode=0
and @pnFunction=3
Begin
	Set @sSQLString=null

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End


RETURN @ErrorCode
go
grant execute on dbo.ip_ccOverviewAlpha  to public
go
