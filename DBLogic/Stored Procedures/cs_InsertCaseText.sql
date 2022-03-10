-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertCaseText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertCaseText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_InsertCaseText.'
	drop procedure [dbo].[cs_InsertCaseText]
	Print '**** Creating Stored Procedure dbo.cs_InsertCaseText...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_InsertCaseText
	(
		@pnUserIdentityId	int,
		@psCulture		nvarchar(10) 	= null,
		@psCaseKey		nvarchar(11)	= null, 
		@pnTextTypeId		int,		-- mand
		@pnTextSequence		int = null,
		@psText			ntext		-- mand
	)
-- PROCEDURE :	cs_InsertCaseText
-- VERSION :	11
-- DESCRIPTION:	Insert a row into the CASETEXT table
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/07/2002	JB	Procedure created
-- 15/07/2002	SF  	@pnTextTypeId = 0 is perfectly valid.  
-- 16/07/2002	SF	Must translare TextTypeId to equivalent CaseText.TextType
-- 15/04/2013	DV	11 R13270 Increase the length of nvarchar to 11 when casting or declaring integer
AS

set concat_null_yields_null off

-- -------------------
-- Minimum Data
If 	@pnTextTypeId is null 
/*	or @pnTextTypeId = 0   (0 = title) */
	or @psText is null
	or @psText like ''
	return -1

-- -------------------
-- Set Flags
-- Not you cannot len() and ntext so I am grabbing the first 300 and testing those
Declare @bLongFlag bit
If LEN(CAST(@psText AS NVARCHAR(300))) <= 254
	Set @bLongFlag = 0
else
	Set @bLongFlag = 1

-- -------------------
-- Data Convertion
Declare @nCaseId int
Set @nCaseId = CAST(@psCaseKey as int)

Declare @sTextType nvarchar(2)
--Set @sTextType = CAST(@pnTextTypeId as nvarchar(2))
set @sTextType = case @pnTextTypeId 
		  when	0	then 'T'	/* Title 	*/
		  when	1	then 'R'	/* Remarks 	*/
		  when 	2	then 'CL'	/* Claims 	*/
		  when 	3	then 'A'	/* Abstract 	*/
		  when	4	then 'T1'	/* Text1 	*/
		  when 	5	then 'T2'	/* Text2 	*/
		  when	6	then 'T3'	/* Text3 	*/
		end

if @sTextType is null
	return -2

-- -------------------
-- Generate Seq No.
Declare @nLastTextNo int
SELECT @nLastTextNo = MAX(TEXTNO) 
	FROM [CASETEXT] 
	WHERE [CASEID] = @nCaseId
	AND [TEXTTYPE] = @sTextType

if @nLastTextNo is null
begin
	/* if they aren't any rows against this caseid @nLastTextNo will be null */
	set @pnTextSequence = 0
end
else
begin
	set @pnTextSequence = @nLastTextNo + 1
end
-- ---------------------
-- Insert into CASETEXT


INSERT INTO CASETEXT
	(	[CASEID],
		[TEXTTYPE], 
		[TEXTNO],
		[MODIFIEDDATE],
		[LONGFLAG],
		[SHORTTEXT],
		[TEXT]

	)
VALUES	(	@nCaseId,
		@sTextType,
		@pnTextSequence,
		GETDATE(),
		@bLongFlag,
		CASE WHEN @bLongFlag = 1 THEN null ELSE CAST(@psText as nvarchar(254)) END,
		CASE WHEN @bLongFlag = 1 THEN @psText ELSE null END
	)


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_InsertCaseText to public
go
