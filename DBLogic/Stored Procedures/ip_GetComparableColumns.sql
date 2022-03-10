-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetComparableColumns
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetComparableColumns]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetComparableColumns.'
	Drop procedure [dbo].[ip_GetComparableColumns]
End
Print '**** Creating Stored Procedure dbo.ip_GetComparableColumns...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_GetComparableColumns
(
	@psColumns 	nvarchar(4000)	= null	output,
	@psTableName 	nvarchar(30),			-- Mandatory
	@psAlias	nvarchar(50)	= null		-- The alias to be used in the select clause for the @psTableName
)
as
-- PROCEDURE:	ip_GetComparableColumns
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	The procedure looks up the table definition and returns a comma separated list of the column names 
--		for the table that may be compared. The list is in the order the columns are specified in the table.
--		Noncomparable data types are text, ntext, image.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Jan 2005	TM	RFC1319	1	Procedure created
-- 15 Feb 2005	TM	RFC1319	2	Adjust the procedure to convert any text/ntext columns to nvarchar(4000) 
--					and include them in the list.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int

Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Assemble the comma separated list of the column names by looking up the 
	-- table definition in the system view:
	Set @sSQLString = "
	Select @psColumns = ISNULL(NULLIF(@psColumns+',', ','),'') + "+char(10)+
			    CASE WHEN @psAlias is not null 
				 THEN "CASE WHEN DATA_TYPE in ('text', 'ntext')"+char(10)+
				       -- Convert ntext and text types columns to the nvarchar(4000)
				       -- to be able to use then in the checksum function:
				      "     THEN 'CAST('+@psAlias + '.' + COLUMN_NAME + ' as nvarchar(4000))'"+char(10)+
				      "	    ELSE @psAlias + '.' + COLUMN_NAME"+char(10)+
				      "END"
				 ELSE "CASE WHEN DATA_TYPE in ('text', 'ntext')"+char(10)+
				      -- Convert ntext and text types columns to the nvarchar(4000)
				      -- to be able to use then in the checksum function:
				      "     THEN 'CAST(' + COLUMN_NAME + ' as nvarchar(4000))'"+char(10)+
				      "	    ELSE COLUMN_NAME"+char(10)+
				      "END"
			    END+char(10)+
	"from INFORMATION_SCHEMA.COLUMNS 
	where TABLE_NAME = @psTableName
	-- Exclude noncomparable data types to avoide SQL error:
	and DATA_TYPE not in ('image')
	-- Order the list of columns in the order the columns 
	-- are specified in the table:
	order by ORDINAL_POSITION"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@psColumns	nvarchar(4000)	OUTPUT,
					  @psTableName	nvarchar(30),
					  @psAlias	nvarchar(50)',
					  @psColumns	= @psColumns	OUTPUT,
					  @psTableName	= @psTableName,
					  @psAlias	= @psAlias
End

Return @nErrorCode
GO

Grant execute on dbo.ip_GetComparableColumns to public
GO
