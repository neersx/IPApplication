-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipu_GenerateKeyWordsFromTitle
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.ipu_GenerateKeyWordsFromTitle') and sysstat & 0xf = 4)
Begin
	Print '**** Drop Stored Procedure dbo.ipu_GenerateKeyWordsFromTitle.'
	drop procedure dbo.ipu_GenerateKeyWordsFromTitle
End
Print '**** Creating Stored Procedure dbo.ipu_GenerateKeyWordsFromTitle...'
Print ''
go

create procedure dbo.ipu_GenerateKeyWordsFromTitle 
			@nCaseid	int = NULL /* Caseid for 1 case or NULL for all cases */
AS
-- PROCEDURE :	ipu_GenerateKeyWordsFromTitle
-- DESCRIPTION:	Combinations of alphanumeric characters separated by a single space are
--		stripped out of the Case TITLE as KEYWORDS and linked to the cases.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24/06/2001	MF			Procedure created
-- 01/08/2001	MF			Replace the temporary table with a permanent table and drop it at the end.
--					This is to work around a SQLServer 2000 problem where REPLACE of 2 spaces
--					with a single space is not working. 
-- 03/08/2001	MF			Go back to using a temporary table however change the code that replaces 2 spaces
--					with a single space to first convert all spaces to a tilde "~" and then replace
--					all occurrences of 2 tildes with a single tilde.  Finally replace the remaining
--					single tilde with a space.
-- 06 Aug 2004	AB	8035	4	Add collate database_default to temp table definitions

set nocount on

declare @nCounter	smallint,
	@nFirstSpace	smallint,
	@RowCount	int,
	@TranCountStart int,
	@nKeyWordNo	int,
	@ErrorCode	int, 
	@sTitle		varchar(255),
	@sTitleCopy	varchar(255),
	@sWord		varchar(255),
	@sFullWord	varchar(255)

set	@nCounter	=0
set	@ErrorCode	=0

-- Create a working table to manipulate the TITLE

create table #TEMPCASETITLE
	(CASEID		int						NOT NULL,
	 TITLE		varchar(256) 	 collate database_default 	NULL)

 CREATE INDEX XIE1#TEMPCASETITLE ON #TEMPCASETITLE
 (
        TITLE
 )

-- Load the temporary table stripping out any leading spaces from TITLE and appending a single space

if @nCaseid is null
begin
	insert into #TEMPCASETITLE (CASEID, TITLE)
	select 	CASEID, ltrim(upper(TITLE))+' '
	from	CASES
	where	TITLE is not null

	select @ErrorCode=@@Error
end
else begin
	insert into #TEMPCASETITLE (CASEID, TITLE)
	select 	CASEID, ltrim(upper(TITLE))+' '
	from	CASES
	where	TITLE is not null
	and	CASEID = @nCaseid

	select @ErrorCode=@@Error
end

-- Load all of the non alpha-numeric characters into a temporary table so they
-- can subsequently be used in an Update to replace any occurrences of these to a space.
-- This is done by using the ASCII value of the non alpha-numeric characters

While @nCounter<255
and   @ErrorCode=0
begin
	if @nCounter between  1 and 31
	or @nCounter between 33 and 47
	or @nCounter between 58 and 64
	or @nCounter between 91 and 96
	or @nCounter > 122
	begin
		update	#TEMPCASETITLE
		set	TITLE = replace(TITLE,char(@nCounter), ' ')

		select @ErrorCode=@@Error
	end
	
	Set @nCounter=@nCounter+1
end

-- Now convert any 2 spaces to a single space and repeat this until no more
-- updates occur
-- The process to do this will use an interim step of converting spaces to a "~" due to a bug
-- found in SQLServer 2000 when trying to replace 2 spaces with a single space in a temporary table.

if @ErrorCode=0
Begin
	update	#TEMPCASETITLE
	set	TITLE=replace(TITLE,' ','~')

	Set	@ErrorCode=@@Error
End

Set	@RowCount=1

While @RowCount>0
and   @ErrorCode=0
Begin
	update  #TEMPCASETITLE
	set	TITLE=replace(TITLE,'~~','~')
	where	TITLE like '%~~%'

	Set	@RowCount =@@rowcount
	Set	@ErrorCode=@@Error
end

-- Each word is now separated by a "~". Change these to a single space

if @ErrorCode=0
Begin
	update	#TEMPCASETITLE
	set	TITLE=replace(TITLE,'~',' ')

	Set	@ErrorCode=@@Error
End


-- Remove any leading spaces

if  @ErrorCode=0
Begin
	update	#TEMPCASETITLE
	set	TITLE=ltrim(TITLE)
	where	TITLE like ' %'

	Select	@ErrorCode=@@Error
end

-- At this point the TITLE in the temporary table consists of alpha-numeric combinations of characters
-- with a single trailing space after every word.

-- Create a cursor that will return a distinct set of the TITLE so that the individual words can be split
-- apart.  As many cases often share the same TITLE, working on a distinct list will improve the efficency

If @ErrorCode = 0
Begin

	DECLARE casetitlecursor CURSOR SCROLL DYNAMIC FOR

	select  TITLE
	from #TEMPCASETITLE

	Select @ErrorCode=@@Error
End

If @ErrorCode=0
Begin
	OPEN casetitlecursor 

	fetch casetitlecursor into
		@sTitle

	Select @ErrorCode=@@Error
End

-- Loop through each row returned and split the individual words out of the TITLE

WHILE @@fetch_status = 0
 and  @ErrorCode=0
BEGIN
	-- Loop through @sTitle to find each word.   Either create a KEYWORD row 
	-- or find an existing row then insert a CASEWORD row for each Case in the 
	-- temporary table where TITLE matches @sTitle

	set @sTitleCopy = @sTitle

	WHILE datalength(ltrim(@sTitleCopy))>0
	Begin
		set @nFirstSpace=patindex('% %',@sTitleCopy)

		-- A keyword has a maximum size of 50 characters so truncate larger words
		if @nFirstSpace>51
		begin
			set @sWord     = substring(@sTitleCopy, 1, 50)
			set @sFullWord = substring(@sTitleCopy, 1, @nFirstSpace-1)	
		end
		else begin
			set @sWord     = substring(@sTitleCopy, 1, @nFirstSpace-1)	
			set @sFullWord = @sWord
		end

		-- Now that the Word has been extracted find out if it already exists as a KEYWORD

		Set	@nKeyWordNo=NULL

		select	@nKeyWordNo= CASE STOPWORD WHEN 1 THEN NULL ELSE KEYWORDNO END
		from	KEYWORDS
		where	KEYWORD=@sWord
	
		Select	@RowCount=@@rowcount,
			@ErrorCode=@@Error

		-- If the KEYWORD does not exist then it has to be created

		If  @RowCount=0
		and @ErrorCode=0
		begin
			Select @TranCountStart = @@TranCount
			BEGIN TRANSACTION

			select @nKeyWordNo=isnull(INTERNALSEQUENCE,0) + 1
			from LASTINTERNALCODE 
			where TABLENAME='KEYWORDS'

			select	@RowCount=@@rowcount,
				@ErrorCode=@@Error

			if  @ErrorCode=0
			begin
				if  @RowCount=0
				begin
					set @nKeyWordNo=1

					insert into LASTINTERNALCODE (TABLENAME, INTERNALSEQUENCE)
					values ('KEYWORDS', @nKeyWordNo)

					select @ErrorCode=@@error
				end
				else begin
					update	LASTINTERNALCODE
					set	INTERNALSEQUENCE=@nKeyWordNo
					where	TABLENAME='KEYWORDS'

					select @ErrorCode=@@error
				end
			end

			-- Insert the KEYWORD
	
			if @ErrorCode=0
			begin
				insert into KEYWORDS (KEYWORDNO, KEYWORD, STOPWORD)
				values (@nKeyWordNo, @sWord, 0)

				select @ErrorCode=@@error
			end

			-- Commit or Rollback the transaction

			If @@TranCount > @TranCountStart
			Begin
				If @ErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			end
		end

		-- Now link the Keyword (if it is not a STOPWORD) to the Cases
		-- This will search for the occurrence of the Keyword in all TITLEs

		if  @ErrorCode=0
		and @nKeyWordNo is not Null
		begin
			-- If the Keyword was truncated then search for the appearance of the
			-- letters within the title
			if @nFirstSpace>51
				insert into CASEWORDS (CASEID, KEYWORDNO, FROMTITLE)
				select	T.CASEID, @nKeyWordNo, 1
				from	#TEMPCASETITLE T
				where	TITLE like @sWord+'%'
				and not exists
				(select * from CASEWORDS CW
				 where CW.CASEID=T.CASEID
				 and   CW.KEYWORDNO=@nKeyWordNo)
			else
				insert into CASEWORDS (CASEID, KEYWORDNO, FROMTITLE)
				select	T.CASEID, @nKeyWordNo, 1
				from	#TEMPCASETITLE T
				where	TITLE like @sWord+' %'
				and not exists
				(select * from CASEWORDS CW
				 where CW.CASEID=T.CASEID
				 and   CW.KEYWORDNO=@nKeyWordNo)

			select @ErrorCode=@@error
		end

		-- Remove any occurrences of the extracted word from the working copy of the Title
		-- First remove the current word from the begining of the title and then replace the
		-- word with a space on either side with a single space and remove leading spaces

		set @sTitleCopy = substring(@sTitleCopy, @nFirstSpace, datalength(@sTitleCopy))
		set @sTitleCopy = ltrim(replace(@sTitleCopy,' '+@sFullWord+' ', ' '))

		if  @ErrorCode=0
		begin
			if  @nFirstSpace>51
				update	#TEMPCASETITLE
				set	TITLE=substring(TITLE, @nFirstSpace, datalength(TITLE))
				where	TITLE like @sWord+'%'
			else
				update	#TEMPCASETITLE
				set	TITLE=substring(TITLE, @nFirstSpace, datalength(TITLE))
				where	TITLE like @sWord+' %'

			select @ErrorCode=@@Error

			If @ErrorCode=0
			begin
				update	#TEMPCASETITLE
				set	TITLE=ltrim(TITLE)
				where	TITLE like ' %'

				select @ErrorCode=@@Error
			end

		end
		
	End

	-- Now get the next TITLE to process

	If @ErrorCode=0
	Begin
		fetch next from casetitlecursor  into
			@sTitle

		Select @ErrorCode=@@Error
	End

END

deallocate casetitlecursor

return @ErrorCode
go

grant execute on dbo.ipu_GenerateKeyWordsFromTitle  to public
go

