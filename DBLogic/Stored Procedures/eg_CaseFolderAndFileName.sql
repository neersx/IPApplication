-----------------------------------------------------------------------------------------------------------------------------
-- Creation of eg_CaseFolderAndFileName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[eg_CaseFolderAndFileName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.eg_CaseFolderAndFileName.'
	drop procedure dbo.eg_CaseFolderAndFileName
end
print '**** Creating procedure dbo.eg_CaseFolderAndFileName...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.eg_CaseFolderAndFileName
(
	@pnCaseId			int,
	@pnLetterNo			int,
	@pbCalledFromCentura		bit		=0,
	@pnActivityId			int		= null,
	@prsDestinationDirectory	nvarchar(254)	=null output,
	@prsDestinationFile		nvarchar(254)	=null output
)
AS
-- PROCEDURE 	:	eg_CaseFolderAndFileName
-- VERSION 	:	3.0
-- DESCRIPTION	:	Returns destination directory in the form:
--			drive:\propertyname\country\IRN
--			and file name is in the form:
--			pdf form name.pdf or document name.doc
--			Note: the format has been changed in version 2.0
-- SCOPE	:	DocGen, Case
-- CALLED BY 	:	Centura
-- COPYRIGHT	:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  Version Mod  	Change
-- ------------ ---- ------- ----------	---------------------------------------------------
-- 29/07/2004	IB	1.0		Procedure created
-- 10/05/2005	IB	2.0  SQA11347	The format of the destination directory needs to be
--					c:\document storage\instructor name\irn
--					The format of the destination file needs to be:
--					date(in yyyy.mm.dd format) followed by 
--					Instructor's Attention Name (if one exists)
--					then a document code (if one exists).
-- 20/O8/2008	DL	3.0 SQA16128	Add optional parameter 	@pnActivityId

	Set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	Declare @nErrorCode		int
	Declare @nStart			int
	Declare @sSQLString		nvarchar(4000)
	Declare @sIRN			nvarchar(30)
	Declare @sDocumentCode		nvarchar(10)
	Declare @nDocumentType		int
	Declare @sInstructorFirstName	nvarchar(50)
	Declare @sInstructorName	nvarchar(254)
	Declare @sInstructor		nvarchar(305)
	Declare @sAttentionFirstName	nvarchar(50)
	Declare @sAttentionName		nvarchar(254)
	Declare @sAttention		nvarchar(305)
	Declare @sDestinationDirectory	nvarchar(254)
	Declare @sDestinationFile	nvarchar(254)

	Set @sDestinationDirectory = ''
	Set @sDestinationFile = ''
	Set @nErrorCode=0
	
	If @nErrorCode = 0
	Begin
		-- get case info
		Set @sSQLString="
		Select 	@sIRN 	  		= C.IRN, 
			@sInstructorFirstName 	= NINSTR.FIRSTNAME,
			@sInstructorName 	= NINSTR.NAME,
			@sAttentionFirstName 	= NATTN.FIRSTNAME,
			@sAttentionName 	= NATTN.NAME
		from	CASES C
		left join	
			CASENAME CN 	on (CN.CASEID = C.CASEID 
						AND CN.NAMETYPE = 'I')
		left join
			NAME NINSTR	on (NINSTR.NAMENO = CN.NAMENO)
		left join
			NAME NATTN	on (NATTN.NAMENO = CN.CORRESPONDNAME)
		
		where   C.CASEID = @pnCaseId"
	
		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sIRN			nvarchar(30)	OUTPUT,
						  @sInstructorFirstName	nvarchar(50)	OUTPUT,
						  @sInstructorName	nvarchar(254)	OUTPUT,	
						  @sAttentionFirstName	nvarchar(50)	OUTPUT,
						  @sAttentionName	nvarchar(254)	OUTPUT,	
						  @pnCaseId		int',
						  @sIRN			=@sIRN			OUTPUT,
						  @sInstructorFirstName	=@sInstructorFirstName	OUTPUT,
						  @sInstructorName     	=@sInstructorName	OUTPUT,	
						  @sAttentionFirstName	=@sAttentionFirstName	OUTPUT,
						  @sAttentionName     	=@sAttentionName	OUTPUT,	
						  @pnCaseId        	=@pnCaseId
	 
	
	End
	

	If @nErrorCode = 0
	Begin	

		If @sInstructorFirstName != ''
		Begin
			-- A directory cannot contain any of the following characters:
                        --    \ / :  * ? " < > | 
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '\', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '/', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, ':', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '*', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '?', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '"', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '<', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '>', '')
			Select @sInstructorFirstName = Replace(@sInstructorFirstName, '|', '')

		End

		If @sInstructorName != ''
		Begin
			-- A directory cannot contain any of the following characters:
                        --    \ / :  * ? " < > | 
			Select @sInstructorName = Replace(@sInstructorName, '\', '')
			Select @sInstructorName = Replace(@sInstructorName, '/', '')
			Select @sInstructorName = Replace(@sInstructorName, ':', '')
			Select @sInstructorName = Replace(@sInstructorName, '*', '')
			Select @sInstructorName = Replace(@sInstructorName, '?', '')
			Select @sInstructorName = Replace(@sInstructorName, '"', '')
			Select @sInstructorName = Replace(@sInstructorName, '<', '')
			Select @sInstructorName = Replace(@sInstructorName, '>', '')
			Select @sInstructorName = Replace(@sInstructorName, '|', '')

		End
		
		If @sInstructorFirstName != ''
		Begin
			Set @sInstructor = @sInstructorFirstName
		End
		
		If @sInstructorName != ''
		Begin
			If @sInstructor != ''
				Set @sInstructor = @sInstructor + ' '
			Set @sInstructor = @sInstructor + @sInstructorName
		End

		If @sInstructor != ''
			Set @sDestinationDirectory = 
				@sDestinationDirectory + '\' + @sInstructor

		If @sIRN != ''
		Begin
			-- A directory cannot contain any of the following characters:
                        --    \ / :  * ? " < > | 
			Select @sIRN = Replace(@sIRN, '\', '')
			Select @sIRN = Replace(@sIRN, '/', '')
			Select @sIRN = Replace(@sIRN, ':', '')
			Select @sIRN = Replace(@sIRN, '*', '')
			Select @sIRN = Replace(@sIRN, '?', '')
			Select @sIRN = Replace(@sIRN, '"', '')
			Select @sIRN = Replace(@sIRN, '<', '')
			Select @sIRN = Replace(@sIRN, '>', '')
			Select @sIRN = Replace(@sIRN, '|', '')

			Set @sDestinationDirectory = 
				@sDestinationDirectory + '\' + @sIRN
		End

		If @sAttentionFirstName != ''
		Begin
			-- A filename cannot contain any of the following characters:
                        --    \ / :  * ? " < > | 
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '\', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '/', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, ':', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '*', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '?', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '"', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '<', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '>', '')
			Select @sAttentionFirstName = Replace(@sAttentionFirstName, '|', '')

		End

		If @sAttentionName != ''
		Begin
			-- A filename cannot contain any of the following characters:
                        --    \ / :  * ? " < > | 
			Select @sAttentionName = Replace(@sAttentionName, '\', '')
			Select @sAttentionName = Replace(@sAttentionName, '/', '')
			Select @sAttentionName = Replace(@sAttentionName, ':', '')
			Select @sAttentionName = Replace(@sAttentionName, '*', '')
			Select @sAttentionName = Replace(@sAttentionName, '?', '')
			Select @sAttentionName = Replace(@sAttentionName, '"', '')
			Select @sAttentionName = Replace(@sAttentionName, '<', '')
			Select @sAttentionName = Replace(@sAttentionName, '>', '')
			Select @sAttentionName = Replace(@sAttentionName, '|', '')

		End
		
		If @sAttentionFirstName != ''
		Begin
			Set @sAttention = @sAttentionFirstName
		End
		
		If @sAttentionName != ''
		Begin
			If @sAttention != ''
				Set @sAttention = @sAttention + ' '
			Set @sAttention = @sAttention + @sAttentionName
		End

		If @sAttention != ''
			Set @sDestinationFile = @sAttention

	End

	If @nErrorCode = 0
	Begin
		-- get letter info
		Set @sSQLString="
			Select	@sDocumentCode = L.DOCUMENTCODE,
				@nDocumentType = L.DOCUMENTTYPE
			From	LETTER L
			Where	L.LETTERNO = @pnLetterNo"
	
		Exec @nErrorCode=
			sp_executesql @sSQLString,
				N'@sDocumentCode	nvarchar(10)	OUTPUT,	
				  @nDocumentType	int		OUTPUT,
				  @pnLetterNo		int',
				  @sDocumentCode	=@sDocumentCode	OUTPUT,
				  @nDocumentType	=@nDocumentType	OUTPUT,
				  @pnLetterNo   	=@pnLetterNo
	 
		
	End

	If @nErrorCode = 0
	
	Begin
		If @sDocumentCode != ''
		Begin
			-- A file cannot contain any of the following characters:
                        --    \ / :  * ? " < > | 
			Select @sDocumentCode = Replace(@sDocumentCode, '\', '')
			Select @sDocumentCode = Replace(@sDocumentCode, '/', '')
			Select @sDocumentCode = Replace(@sDocumentCode, ':', '')
			Select @sDocumentCode = Replace(@sDocumentCode, '*', '')
			Select @sDocumentCode = Replace(@sDocumentCode, '?', '')
			Select @sDocumentCode = Replace(@sDocumentCode, '"', '')
			Select @sDocumentCode = Replace(@sDocumentCode, '<', '')
			Select @sDocumentCode = Replace(@sDocumentCode, '>', '')
			Select @sDocumentCode = Replace(@sDocumentCode, '|', '')

			Set @sDestinationFile = @sDestinationFile + @sDocumentCode
							
		End
		
		If @nDocumentType is not NULL and @sDestinationFile != ''
		Begin
			if @nDocumentType = 1 -- Word template
				Set @sDestinationFile = @sDestinationFile + '.doc'
			
			if @nDocumentType = 2 -- PDF form
				Set @sDestinationFile = @sDestinationFile + '.pdf'
			
			if @nDocumentType = 3 -- XML document
				Set @sDestinationFile = @sDestinationFile + '.xml'
			
			if @nDocumentType = 4 -- Mail Merge (word document)
				Set @sDestinationFile = @sDestinationFile + '.doc'
		End

	End

	If @nErrorCode = 0
	Begin
		If len(@sDestinationDirectory) > 0
			Set @prsDestinationDirectory = 'c:\document storage' 
				+ @sDestinationDirectory

		If len(@sDestinationFile) > 0
			Set @prsDestinationFile = convert(nvarchar(10), getdate(), 102)
				+ @sDestinationFile

		If @pbCalledFromCentura = 1
			Select @prsDestinationDirectory, @prsDestinationFile
	End

	Return @nErrorCode	
GO

Grant execute on dbo.eg_CaseFolderAndFileName to public
go
