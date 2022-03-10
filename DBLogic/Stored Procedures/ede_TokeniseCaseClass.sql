-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_TokeniseCaseClass
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_TokeniseCaseClass]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)

begin
	Print '**** Drop Stored Procedure dbo.ede_TokeniseCaseClass.'
	Drop procedure [dbo].[ede_TokeniseCaseClass]
end
Print '**** Creating Stored Procedure dbo.ede_TokeniseCaseClass...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE dbo.ede_TokeniseCaseClass 
		@psCaseClassTableName nvarchar(100)
AS
-- PROCEDURE :	ede_TokeniseCaseClass
-- VERSION :	4
-- DESCRIPTION:	Case classes are stored as a collection of classes separated by commas.  This funtion tokenises 
--						case LOCALCLASSES and INTCLASSES into individual class.
--	Parameters:
--						- @psCaseClassTableName is a global temp table name to contain the return classes for affected cases with
--							following structure.
--					 		##xxx(
--							CASEID						int,
--							CLASSTYPE					nvarchar(3),		-- value = 'INT' or 'LOC' 
--							CLASS							nvarchar(5),
--							SEQUENCENO					int	
--							)
--
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	------	-----	-------	----------------------------------------------- 
-- 16/01/2007	DL	12304	1	Procedure created
-- 13/06/2008	DL	16439	2	Split the classes within this SP instead of using fn_tokenise to enhance performance.
-- 26/06/2008	DL	16439	3	Revisiting to fix a bug.
-- 14/05/2009	DL	17676	4	Performance enhancement. Only tokenise classes that are multiple. 



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

CREATE TABLE #TEMPCASE(
	ROWID 		int identity(1,1),
	CASEID		int
)

CREATE INDEX X1TEMPCASE ON #TEMPCASE 
(
	CASEID
)

CREATE TABLE #TEMPCASELOCAL(
	ROWID 		int identity(1,1),
	CASEID		int
)
CREATE INDEX X1TEMPCASELOCAL ON #TEMPCASELOCAL 
(
	CASEID
)

CREATE TABLE #TEMPCASEINT(
	ROWID 		int identity(1,1),
	CASEID		int
)
CREATE INDEX X1TEMPCASEINT ON #TEMPCASEINT 
(
	CASEID
)


Declare 	@sSQLString 		nvarchar(4000),
		@nCaseId		int,
		@nErrorCode		int,
		@nRowId			int,
		@nNumberOfCases		int,
		@sLocalClass		nvarchar(254),
		@sIntClass		nvarchar(254),

		@nSeq			int,
		@nFirstDelimiter	int,
		@sParsedClass		nvarchar(50),
		@nNumberOfLocalCases	int,
		@nNumberOfIntCases	int



Set @nErrorCode = 0 


-- Copy cases into a temp table 
If @nErrorCode = 0
Begin
	Set @sSQLString="
		Insert into #TEMPCASE ( CASEID)
		Select CASEID
		from " + @psCaseClassTableName
	exec @nErrorCode=sp_executesql @sSQLString
	set @nNumberOfCases = @@rowcount
End


-- clear the @psCaseClassTableName table before inserting parsed classses
If @nErrorCode = 0
Begin
	Set @sSQLString="
		Truncate table " + @psCaseClassTableName 
	exec @nErrorCode=sp_executesql @sSQLString
End

-- add single local class
If @nErrorCode = 0
Begin
	Set @sSQLString="Insert into " + @psCaseClassTableName + " (CASEID, CLASSTYPE, CLASS, SEQUENCENO)
		select C.CASEID, 'LOC', LOCALCLASSES, 1
		from #TEMPCASE TC 
		join CASES C ON C.CASEID = TC.CASEID
		where C.LOCALCLASSES is not null
		and charindex(',', C.LOCALCLASSES) = 0 "
	exec @nErrorCode=sp_executesql @sSQLString
End


-- add single international class
If @nErrorCode = 0
Begin
	Set @sSQLString="Insert into " + @psCaseClassTableName + " (CASEID, CLASSTYPE, CLASS, SEQUENCENO)
		select C.CASEID, 'INT', INTCLASSES, 1
		from #TEMPCASE TC 
		join CASES C ON C.CASEID = TC.CASEID
		where C.INTCLASSES is not null
		and charindex(',', C.INTCLASSES) = 0 "
	exec @nErrorCode=sp_executesql @sSQLString
End


-- cases with multiple local classes that require parsing
If @nErrorCode = 0
Begin
	Set @sSQLString="Insert into #TEMPCASELOCAL (CASEID)
		select C.CASEID 
		from #TEMPCASE TC 
		join CASES C ON C.CASEID = TC.CASEID
		where charindex(',', isnull(C.LOCALCLASSES, '')) > 0
		 "
	exec @nErrorCode=sp_executesql @sSQLString
	set @nNumberOfLocalCases = @@rowcount
End


-- tokenise case local classes
If @nErrorCode = 0
Begin
	Set @nRowId = 1
	While (@nErrorCode = 0) and  (@nRowId <= @nNumberOfLocalCases)
	Begin
		Set @sSQLString="
			select 
				@nCaseId = C.CASEID,
				@sLocalClass = replace (LOCALCLASSES, ',', char(27)) 
				from #TEMPCASELOCAL  T
				join CASES C on (C.CASEID = T.CASEID)
				where T.ROWID = @nRowId
		"
		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCaseId				int			output,
		  @sLocalClass			nvarchar(254) output,
		  @nRowId				int',
		  @nCaseId				=  @nCaseId output,
		  @sLocalClass			= 	@sLocalClass output,
		  @nRowId				= 	@nRowId		


		-- If the string does not end in a delimiter then insert one
		if @sLocalClass not like '%'+char(27)
			set @sLocalClass = @sLocalClass+char(27)

		-- split local classes
		set @nSeq = 1
		While datalength(ltrim(@sLocalClass))>0
		Begin
			set @nFirstDelimiter=patindex('%'+char(27)+'%',@sLocalClass)
			set @sParsedClass = rtrim(ltrim(substring(@sLocalClass, 1, @nFirstDelimiter-1)))

			if datalength(ltrim(@sParsedClass))>0 
			begin
				Set @sSQLString="Insert into " + @psCaseClassTableName + " (CASEID, CLASSTYPE, CLASS, SEQUENCENO)
				values ( @nCaseId, 'LOC', @sParsedClass, @nSeq ) "

				Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nCaseId		int,
				  @sParsedClass		nvarchar(50),
				  @nSeq			int',
				  @nCaseId		= @nCaseId,
				  @sParsedClass		= @sParsedClass ,
				  @nSeq			= @nSeq 

				set @nSeq = @nSeq + 1
			end

			-- Now remove the parameter just extracted
			set @sLocalClass=substring(@sLocalClass,@nFirstDelimiter+1,4000)

		End

		-- process next case
		set @nRowId = @nRowId + 1

	End  -- end while loop
End


-- cases with multiple int classes that require parsing
If @nErrorCode = 0
Begin
	Set @sSQLString="Insert into #TEMPCASEINT (CASEID)
		select C.CASEID 
		from #TEMPCASE TC 
		join CASES C ON C.CASEID = TC.CASEID
		where charindex(',', isnull(C.INTCLASSES, '')) > 0
		 "
	exec @nErrorCode=sp_executesql @sSQLString
	set @nNumberOfIntCases = @@rowcount
End


-- tokenise case int classes
If @nErrorCode = 0
Begin
	Set @nRowId = 1
	While (@nErrorCode = 0) and  (@nRowId <= @nNumberOfIntCases)
	Begin
		Set @sSQLString="
			select 
				@nCaseId = C.CASEID,
				@sIntClass = replace (INTCLASSES, ',', char(27))
				from #TEMPCASEINT  T
				join CASES C on (C.CASEID = T.CASEID)
				where T.ROWID = @nRowId
		"
		Exec @nErrorCode=sp_executesql @sSQLString,
		N'@nCaseId				int			output,
		  @sIntClass			nvarchar(254) output,
		  @nRowId				int',
		  @nCaseId				=  @nCaseId output,
		  @sIntClass			=  @sIntClass output,
		  @nRowId				= 	@nRowId		


		-- If the string does not end in a delimiter then insert one
		if @sIntClass not like '%'+char(27)
			set @sIntClass = @sIntClass+char(27)

		-- split international classes
		set @nSeq = 1
		While datalength(ltrim(@sIntClass))>0
		Begin
			set @nFirstDelimiter=patindex('%'+char(27)+'%',@sIntClass)
			set @sParsedClass = rtrim(ltrim(substring(@sIntClass, 1, @nFirstDelimiter-1)))

			if datalength(ltrim(@sParsedClass))>0 
			begin
				Set @sSQLString="Insert into " + @psCaseClassTableName + " (CASEID, CLASSTYPE, CLASS, SEQUENCENO)
				values ( @nCaseId, 'INT', @sParsedClass, @nSeq ) "

				Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nCaseId		int,
				  @sParsedClass		nvarchar(50),
				  @nSeq			int',
				  @nCaseId		= @nCaseId,
				  @sParsedClass		= @sParsedClass ,
				  @nSeq			= @nSeq 

				set @nSeq = @nSeq + 1
			end

			-- Now remove the parameter just extracted
			set @sIntClass=substring(@sIntClass,@nFirstDelimiter+1,4000)

		End

		-- process next case
		set @nRowId = @nRowId + 1

	End  -- end while loop
End


RETURN @nErrorCode


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant execute on dbo.ede_TokeniseCaseClass to public
GO

