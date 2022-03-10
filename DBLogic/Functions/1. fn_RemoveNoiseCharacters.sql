-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_RemoveNoiseCharacters
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_RemoveNoiseCharacters') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_RemoveNoiseCharacters.'
	Drop function [dbo].[fn_RemoveNoiseCharacters]
	Print '**** Creating Function dbo.fn_RemoveNoiseCharacters...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_RemoveNoiseCharacters
(
	@psDirtyString	nvarchar(max)
)
RETURNS nvarchar(max)

-- PROCEDURE:	fn_RemoveNoiseCharacters
-- VERSION :	5
-- DESCRIPTION:	Returns the passed Sentence with all stop words removed

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17 Feb 2003  MF	1		Removes certain characters from the string
-- 26 Feb 2003	MF	2	8457	Strip out the "/" and "\" characters.
-- 09 Apr 2003	MF	3	8650	Change result to UPPER case
-- 04 Jun 2003  MF	4	8887	Strip out the ^ character
-- 14 Apr 2011	MF	5	10475	Change nvarchar(4000) to nvarchar(max)

AS
Begin
	-- Characters removed are as follows :
	--	space
	--	&
	--	(
	--	)
	--	-
	--	+
	--	:
	--	;
	--	"
	--	' (char(39)
	--	,
	--	.
	--	/
	--	\
	--	^

	Declare @sCleanString		nvarchar(max)

	Select @sCleanString=Upper(
		replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
			(@psDirtyString,	' ',''),
						'&',''),
						'(',''),
						')',''),
						'-',''),
						'+',''),
						':',''),
						';',''),
						'"',''),
						char(39),''),
						',',''),
						'.',''),
						'/',''),
						'\',''),
						'^',''))


	RETURN @sCleanString
End
GO

Grant execute on dbo.fn_RemoveNoiseCharacters to public 
go
