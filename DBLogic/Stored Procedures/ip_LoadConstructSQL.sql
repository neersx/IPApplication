-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_LoadConstructSQL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_LoadConstructSQL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_LoadConstructSQL.'
	drop procedure dbo.ip_LoadConstructSQL
	print '**** Creating procedure dbo.ip_LoadConstructSQL...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_LoadConstructSQL
(
	@psCurrentString		nvarchar(4000)	output,
	@psAddString			nvarchar(4000),		-- Mandatory
	@psComponentType		char(1),		-- Mandatory
	@psSeparator			nvarchar(10)	=null,
	@pbForceLoad			bit		= 0


)		
-- PROCEDURE :	ip_LoadConstructSQL
-- VERSION :	2
-- DESCRIPTION:	This procedure takes a string and determines if it can be concatenated with the Current String 
--		without exceeding the 4000 character sizer limit.  If the size limit is going to be exceeded
--		then the Current String is loaded into a table.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Details
-- ----		---	-------	-------	-------------------------------------
-- 02 Apr 2004	MF	SQA9664	1	Procedure created
-- 20 Sep 2004	TM	RFC886	2	When inserting the new row into the #TempConstructSQL table concatenate 
--					the comma (',') at the end of the @psCurrentString. 

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode		int

Declare @sSQLString		nvarchar(4000)

Set @ErrorCode=0

Set @sSQLString="
	insert into #TempConstructSQL (ComponentType, SavedString)
	values(@psComponentType, @psCurrentSting)"

If len(isnull(@psCurrentString,''))+
   len(isnull(@psSeparator,    ''))+
   len(isnull(@psAddString,    ''))<4000
Begin
	Set @psCurrentString=nullif(@psCurrentString+@psSeparator,@psSeparator)+@psAddString
	Set @psAddString=null
End
Else Begin
	Set @psCurrentString=nullif(@psCurrentString+@psSeparator,@psSeparator)

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@psComponentType	char(1),
					  @psCurrentSting	nvarchar(4000)',
					  @psComponentType=@psComponentType,
					  @psCurrentSting=@psCurrentString

	Set @psCurrentString=@psAddString				
End

If @pbForceLoad=1
and  @ErrorCode=0
Begin
	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@psComponentType	char(1),
					  @psCurrentSting	nvarchar(4000)',
					  @psComponentType=@psComponentType,
					  @psCurrentSting=@psCurrentString	
End

RETURN @ErrorCode
go

grant execute on dbo.ip_LoadConstructSQL  to public
go



