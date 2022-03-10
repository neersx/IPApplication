-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ParseTITLE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ParseTITLE') and xtype='TF')
begin
	print '**** Drop function dbo.fn_ParseTITLE.'
	drop function dbo.fn_ParseTITLE
	print '**** Creating function dbo.fn_ParseTITLE...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function  [dbo].[fn_ParseTITLE] (@pnCaseId	int,
					@psTitle	nvarchar(254)
					)
RETURNS @tbTitleWordList TABLE 
	(
	 CASEID		int		NOT NULL,
	 WORD		nvarchar(254)	COLLATE database_default NULL
	 ) 

-- FUNCTION :	fn_ParseTITLE
-- VERSION :	1
-- DESCRIPTION:	Function to split the supplied Title into discrete words.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
--27 Nov 2013	AvB	R29305	1	Function created
as
Begin

	DECLARE @sTitleStr		nvarchar(255),
		@nASCIIChar		tinyint,
		@nErrorCode		int,
		@nCurrentStartPos	int,
		@nNextStartPos		int,
		@nMaxPos		int,
		@sWord			nvarchar(254),
		@bDoubleSpaceExist	bit

	SET @sTitleStr = LTRIM (RTRIM (@psTitle)) + N' '

	SET @nErrorCode = 0
	SET @nASCIIChar = 0

	WHILE @nASCIIChar < 255
	BEGIN
		IF @nASCIIChar BETWEEN   0 AND  31 OR
		   @nASCIIChar BETWEEN  33 AND  44 OR
		   @nASCIIChar BETWEEN  46 AND  47 OR
		   @nASCIIChar BETWEEN  58 AND  64 OR
		   @nASCIIChar BETWEEN  91 AND  96 OR
		   @nASCIIChar BETWEEN 123 AND 127
		BEGIN

			SET @sTitleStr = REPLACE (CAST (@sTitleStr AS nvarchar(255)) COLLATE SQL_Latin1_General_CP850_CI_AS, NCHAR (@nASCIIChar), N' ')

		END; -- if: character to be stripped out and treated as a separator between WORDs

		SET @nASCIIChar = @nASCIIChar + 1

	END

	SET @sTitleStr = LTRIM (@sTitleStr)
	------------------------------------
	-- If the resulting TitleStr is just 
	-- an empty space (e.g. if the title 
	-- was "#"), set it to NULL
	------------------------------------
	IF LEN (@sTitleStr) = 0
		SET @sTitleStr = NULL	

	----------------------------------
	-- Loop through and replace double
	-- spaces to a single space
	----------------------------------
	SET @bDoubleSpaceExist = 1

	WHILE @bDoubleSpaceExist = 1
	BEGIN
		SET @sTitleStr = REPLACE (@sTitleStr, N'  ', N' ')
		
		IF CHARINDEX (N'  ', @sTitleStr, 1) > 0
			SET @bDoubleSpaceExist = 1
		ELSE
			SET @bDoubleSpaceExist = 0
	END

	SET @nMaxPos = LEN (@sTitleStr)

	SET @nCurrentStartPos = 0

	IF @nMaxPos > 0
		SET @nCurrentStartPos = 1
		
	SET @nNextStartPos = @nCurrentStartPos

	WHILE @nCurrentStartPos <= @nMaxPos
	BEGIN
		SET @sWord  = NULL

		SET @nNextStartPos = CHARINDEX (N' ', @sTitleStr, @nCurrentStartPos) + 1

		SET @sWord = LTRIM (RTRIM (SUBSTRING (@sTitleStr, @nCurrentStartPos, @nNextStartPos - @nCurrentStartPos - 1)))

		INSERT INTO @tbTitleWordList([CASEID], [WORD]) VALUES (@pnCaseId,  @sWord)

		SET @nCurrentStartPos = @nNextStartPos;

	END -- while: CurrentStartPos <= MaxPos

	RETURN

End -- function fn_ParseTITLE
go

grant REFERENCES, SELECT on dbo.fn_ParseTITLE to public
GO
