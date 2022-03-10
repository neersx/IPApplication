-----------------------------------------------------------------------------------------------------------------------------
-- Creation of util_GenerateTranslationTriggers
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[util_GenerateTranslationTriggers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.util_GenerateTranslationTriggers.'
	drop procedure dbo.util_GenerateTranslationTriggers
	print '**** Creating procedure dbo.util_GenerateTranslationTriggers...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE dbo.util_GenerateTranslationTriggers
			@psTable	varchar(30)	-- Mandatory
	
AS

-- PROCEDURE :	util_GenerateTranslationTriggers
-- VERSION :	10  -- NOTE : Modify the variable @sVersion
-- DESCRIPTION:	Generates the triggers required for data translation management for a specific table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
--  7 Sep 2004	MF		1	Procedure created
-- 20 Sep 2004	MF	RFC1695	2	Cater for collation sequence conflicts on the table variable being
--					created for the generated trigger.
-- 22 Sep 2004	MF	RFC1500	3	Minor trigger generation correction
-- 23 Sep 2004	MF	RFC1695	4	Change the VERSION of the generated triggers.
-- 30 Sep 2004	JEK	RFC1880	5	underscore in Like '%_TID' was being treated as a wild card.
-- 12 Oct 2004	MF	RFC1890	6	Only generate INSTEAD OF triggers for tables that contain a 
--					TEXT column with the exception of the NAMETEXT table which is to be
--					generated as AFTER triggers with some specific processing.
-- 15 Oct 2004	MF	RFC1908	7	Correction to problem where more than 2 TID columns exist in the one table.
-- 04 Nov 2004	MF	RFC1969	8	An INSTEAD OF trigger is only required if there is a TEXT or NTEXT column
--					present in the table that will be available for translation.
-- 23 May 2005	MF	SQA11321 9	Only issue an UPDATE for the TID columns if a change has been detected
--					against one of the associated columns.
-- 01 Jun 2005	MF	RFC2659	10	When a column with a translation is set to NULL then remove the TID column
--					before the TRANSLATEDITEMS row is deleted otherwise the new declarative
--					referential integrity rules will give an error.  Modify the code to change
--					the order of statements generated.

Set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF

Declare	@tbColumns 	table (	Name		nvarchar(30),
				TIDColumn	nvarchar(30),
				RelatedColumn	nvarchar(30),
				Display		nvarchar(30),
				DataType	nvarchar(20),
				Type		nvarchar(20),
				Length		smallint,
				KeyNo		int,
				IsIdentity	bit,
				Position	tinyint	identity)

Declare @tbResult	table ( LineNumber	smallint identity,
				ResultString	nvarchar(4000))

Declare @nColCount		tinyint	
Declare @nLastKeyPos		tinyint
Declare	@bTableHasText		bit
Declare @sColumnList		nvarchar(4000)
Declare @sFullColumnList	nvarchar(4000)
Declare	@sTIDColumnList		nvarchar(1000)
Declare @sKeyColumns		nvarchar(1000)
Declare @sKeyJoins		nvarchar(1000)
Declare @sIdentityColumn	nvarchar(30)
Declare @sVersion		nvarchar(3)

-- Update this to be the same as the VERSION number of this stored procedure so it can be used in the 
-- generation of the trigger.
Set @sVersion='10'

-- Get all of the columns for the table and identify those columns that
-- are part of the primary key.  Also return the associated TID column if
-- there is one and any other Column sharing the same TID Column.
insert into @tbColumns(Name, TIDColumn, RelatedColumn, DataType, Type, Length, KeyNo, IsIdentity)
Select	C.name,
	TS.TIDCOLUMN,
	-- Where 2 columns point to the same TIDColumn then save the name of the other column
	CASE WHEN(TS.SHORTCOLUMN=C.name) THEN TS.LONGCOLUMN ELSE TS.SHORTCOLUMN END,
	T.name+	CASE WHEN(patindex('%CHAR%',upper(T.name))>0) then  '('+convert(varchar(10),CASE WHEN(T.name in ('NCHAR','NVARCHAR')) THEN C.length/2 ELSE C.length END)+')' 
		     WHEN(upper(T.name)='DECIMAL')            then  '('+convert(varchar(5), C.prec)+','+convert(varchar(5),C.scale)+')'
		END,
	T.name, 
	CASE WHEN(T.name in ('NCHAR','NVARCHAR')) THEN C.length/2 ELSE C.length END,
	K.keyno,
	COLUMNPROPERTY(O.id, C.name, 'IsIdentity')
from sysobjects O
     join syscolumns C  	on (C.id=O.id)
     join systypes   T 		on (T.xtype=C.xtype) 
left join sysindexes I		on (I.id=O.id
				and I.name like 'XPK%') -- limit to primary key index
left join sysindexkeys K	on (K.id=I.id
				and K.indid=I.indid
				and K.colid=C.colid)
left join TRANSLATIONSOURCE TS	on (TS.TABLENAME=O.name
				and C.name in (TS.SHORTCOLUMN, TS.LONGCOLUMN))
where O.type = 'U'	
and O.name = @psTable
and T.name not in ('sysname')
order by isnull(K.keyno,999), C.colid

set @nColCount=@@Rowcount

-- Save the Identity column name
select @sIdentityColumn=Name
from @tbColumns
where IsIdentity=1

-- Get the Position of the last column that is part of the primary key.

select @nLastKeyPos=isnull(max(Position),1)
from @tbColumns
where KeyNo is not null

-- Get a concatenated string of Columns (excluding Identity columns)
Select @sColumnList = ISNULL(NULLIF(@sColumnList + ',', ','),'')  + Name
from @tbColumns
where IsIdentity=0
order by Position

-- Get a concatenated string of all Columns
Select @sFullColumnList = ISNULL(NULLIF(@sFullColumnList + ',', ','),'')  + Name
from @tbColumns
order by Position

-- Get a concatenated string of TID Columns
Select @sTIDColumnList = ISNULL(NULLIF(@sTIDColumnList + ',', ','),'')  + Name
from @tbColumns
where Name like '%\_TID' escape '\'
order by Position

-- Get a concatenated string of the columns that are part of the
-- primary key
select @sKeyColumns = ISNULL(NULLIF(@sKeyColumns + ',', ','),'')  + Name
from @tbColumns
where KeyNo is not null
order by KeyNo

-- Construct a set of joins for the columns that are part of the 
-- primary key
select @sKeyJoins=ISNULL(NULLIF(@sKeyJoins + ' and ',' and '),'')+'t.'+Name+'=i.'+Name
from @tbColumns
where KeyNo is not null
order by KeyNo

-- If a column that is available for translation is either 'text' or 'ntext'
-- then a flag will be set to cause the triggers to be generated as INSTEAD OF triggers.
-- This is because an AFTER trigger cannot reference a column that is defined as 'text' or 'ntext'

if exists(	select 1
		from TRANSLATIONSOURCE T
		join @tbColumns C	on (C.Name=T.LONGCOLUMN)
		where T.TABLENAME=@psTable
		and C.DataType in ('text','ntext'))
Begin
	Set @bTableHasText=1
End
Else Begin
	Set @bTableHasText=0
End
--------------------------------------------------------------------------------------
-- Generation of the DELETE trigger
--------------------------------------------------------------------------------------

Insert into @tbResult(ResultString)
select
"-----------------------------------------------------------------------------------------------------------------------------
-- Creation of trigger tD_"+@psTable+"_Translation
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where type='TR' and name = 'tD_"+@psTable+"_Translation')
begin
	PRINT 'Refreshing trigger tD_"+@psTable+"_Translation...'
	DROP TRIGGER tD_"+@psTable+"_Translation
end
go"

Insert into @tbResult(ResultString)
Select "

SET QUOTED_IDENTIFIER OFF 
go"

Insert into @tbResult(ResultString)
Select "

CREATE TRIGGER tD_"+@psTable+"_Translation on "+@psTable+" AFTER DELETE NOT FOR REPLICATION 
as
-- TRIGGER :	tD_"+@psTable+"_Translation
-- VERSION :	"+@sVersion+"
-- DESCRIPTION:	Removal of parent TRANSLATIONITEM data when referenced TID no longer required.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- "+convert(varchar, getdate(),106)+"	MF		1	Trigger created

Begin
	delete TRANSLATEDITEMS
	from deleted
	join TRANSLATEDITEMS TI	on (TI.TID in ("+@sTIDColumnList+"))
End
go"


--------------------------------------------------------------------------------------
-- Generation of the INSERT trigger
--------------------------------------------------------------------------------------

Insert into @tbResult(ResultString)
select
"-----------------------------------------------------------------------------------------------------------------------------
-- Creation of trigger tI_"+@psTable+"_Translation
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where type='TR' and name = 'tI_"+@psTable+"_Translation')
begin
	PRINT 'Refreshing trigger tI_"+@psTable+"_Translation...'
	DROP TRIGGER tI_"+@psTable+"_Translation
end
go"

Insert into @tbResult(ResultString)
Select "

SET QUOTED_IDENTIFIER OFF 
go"

Insert into @tbResult(ResultString)
Select "

CREATE TRIGGER tI_"+@psTable+"_Translation on "+@psTable+CASE WHEN(@bTableHasText=0) THEN " AFTER " ELSE " INSTEAD OF " END+"INSERT NOT FOR REPLICATION 
as
-- TRIGGER :	tI_"+@psTable+"_Translation
-- VERSION :	"+@sVersion+"
-- DESCRIPTION:	Generate a TID for each column containing data that is eligible for translation
--		by inserting a row in the TRANSLATEDITEMS table and updating the associated
--		TID column(s) on the "+@psTable+" table."+
CASE WHEN(@bTableHasText=1) THEN "
--		NOTE : This trigger fires BEFORE the insert into the base table so that the values
--		       for the TID columns can be determined and included in the initial INSERT."
END+"

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- "+convert(varchar, getdate(),106)+"	MF		1	Trigger created

Begin"

-- If the table does not have a TEXT column the an AFTER trigger is being generated
If @bTableHasText=0
Begin
	Insert into @tbResult(ResultString)
	select "
	If exists(select 1 from TRANSLATIONSOURCE where TABLENAME='"+@psTable+"' and INUSE=1)
	Begin"
			
End
Else Begin
	Insert into @tbResult(ResultString)
	select 	
"	If not exists(select 1 from TRANSLATIONSOURCE where TABLENAME='"+@psTable+"' and INUSE=1)
	Begin
		insert into "+@psTable+"
		select * from inserted
	End
	Else Begin"
End

Insert into @tbResult(ResultString)
select
"		-- declare a variable to save the last inserted TID
		declare @nMaxTID	int

		-- declare a table variable to hold the detail of each row being inserted
		-- that requires a TID and load it
		declare @tbROWS table (
				ROWNUMBER		int identity(0,1),"

-- Include the columns of the primary key into the table variable
Insert into @tbResult(ResultString)
Select char(9)+char(9)+char(9)+char(9)+C.Name+char(9)+char(9)+C.DataType+
	CASE WHEN(C.Type in ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext'))
		THEN ' collate database_default'
	END +
	','
from @tbColumns C
where C.Position<=@nLastKeyPos
order by C.Position

Insert into @tbResult(ResultString)
select 
"				TIDCOLUMN		nvarchar(30) collate database_default,
				TRANSLATIONSOURCEID	int)

		insert into @tbROWS("+@sKeyColumns+", TIDCOLUMN, TRANSLATIONSOURCEID)"

Insert into @tbResult(ResultString)
select 
"		select i."+replace(@sKeyColumns,',',',i.')+", TS.TIDCOLUMN, TS.TRANSLATIONSOURCEID
		from inserted i
		join TRANSLATIONSOURCE TS	on (TS.TABLENAME='"+@psTable+"'
						and TS.TIDCOLUMN='"+C.TIDColumn+"'
						and TS.INUSE    =1)
		where i."+C.Name+" is not null"+
CASE WHEN(C.RelatedColumn is not null) THEN "
		and i."+C.RelatedColumn+" is null"
END+
CASE WHEN((select count(*) from @tbColumns C1 where C1.Position>C.Position and C1.TIDColumn is not null)>0)
	THEN "		
		union"
END
from @tbColumns C
where C.TIDColumn is not null
order by C.Position

Insert into @tbResult(ResultString)
Select "
		-- Now load a TRANSLATEDITEMS row for each TID to be generated 
		-- The TID will be generated automatically from the Identity column
		insert into TRANSLATEDITEMS(TRANSLATIONSOURCEID)
		select TRANSLATIONSOURCEID
		from @tbROWS

		-- Get the value of the last identity column value inserted into TRANSLATEDITEMS
		-- table.  This is required so that we can determine a unique TID value for each
		-- column that has had a TRANSLATEDITEMS row insert when inserting the "+@psTable+" table 
		Select @nMaxTID=SCOPE_IDENTITY()"


-- If the table does not include an Text column then the trigger will have fired after the  
-- Insert so we now need to Update the row with the new TID column values
If @bTableHasText=0
Begin
	Insert into @tbResult(ResultString)
	select
"		Update "+@psTable+"
		Set"

	Insert into @tbResult(ResultString)
	Select char(9)+char(9)+char(9)+C.TIDColumn+"=(select @nMaxTID-t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.TIDColumn+"')"+
		CASE WHEN((select count(*) from @tbColumns C1 where C1.Position>C.Position and C1.TIDColumn is not null)>0) THEN ',' END
	from @tbColumns C
	Where C.TIDColumn is not null
	order by C.Position

	Insert into @tbResult(ResultString)
	Select
"		from inserted i
		join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"			
End
Else Begin
	-- If there are no Identity columns then the trigger is fired as a Replacement for
	-- the original Insert and so now we must perform the Insert of the data into the
	-- database along with the TID column values

	Insert into @tbResult(ResultString)
	select 	"
		-- Now load the EVENTS table along with any TID values
		insert into "+@psTable+" ("+@sColumnList+")
		select "

	Insert into @tbResult(ResultString)
	Select char(9)+char(9)+char(9)+
		CASE WHEN(C.Name like '%\_TID' escape '\')
			THEN "(select @nMaxTID-t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.Name+"')"
			ELSE "i."+C.Name
		END+
		CASE WHEN(C.Position<@nColCount) THEN ',' END
	from @tbColumns C
	where IsIdentity=0
	order by C.Position

	Insert into @tbResult(ResultString)
	Select
"		from inserted i"
End

Insert into @tbResult(ResultString)
Select
"	End
End
go"

-- The NAMETEXT table has a TEXT column however we wish to force the generation of 
-- an AFTER trigger due to an existing SQLServer error

If upper(@psTable)='NAMETEXT'
Begin
	Set @bTableHasText=0
End

--------------------------------------------------------------------------------------
-- Generation of the UPDATE trigger
--------------------------------------------------------------------------------------

Insert into @tbResult(ResultString)
select
"-----------------------------------------------------------------------------------------------------------------------------
-- Creation of trigger tU_"+@psTable+"_Translation
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where type='TR' and name = 'tU_"+@psTable+"_Translation')
begin
	PRINT 'Refreshing trigger tU_"+@psTable+"_Translation...'
	DROP TRIGGER tU_"+@psTable+"_Translation
end
go"

Insert into @tbResult(ResultString)
Select "

SET QUOTED_IDENTIFIER OFF 
go"

Insert into @tbResult(ResultString)
Select "

CREATE TRIGGER tU_"+@psTable+"_Translation on "+@psTable+CASE WHEN(@bTableHasText=0) THEN " AFTER " ELSE " INSTEAD OF " END+"UPDATE NOT FOR REPLICATION 
as
-- TRIGGER :	tU_"+@psTable+"_Translation
-- VERSION :	"+@sVersion+"
-- DESCRIPTION:	Managing the TID and translations for each column containing data that is eligible for translation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- "+convert(varchar, getdate(),106)+"	MF		1	Trigger created

Begin"

insert into @tbResult(ResultString)
Select "
	-- variable for number of new TID rows to insert
	declare @nNewTID	int

	-- declare a variable to save the last inserted TID value
	declare @nMaxTID	int

	-- declare a table variable to hold the detail of each row being inserted
	-- that requires a TID and load it
	declare @tbROWS table (
			ROWNUMBER		int identity(0,1),"

-- Include the columns of the primary key into the table variable
Insert into @tbResult(ResultString)
Select char(9)+char(9)+char(9)+C.Name+char(9)+char(9)+C.DataType+
	CASE WHEN(C.Type in ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext'))
		THEN ' collate database_default'
	END +
	','
from @tbColumns C
where C.Position<=@nLastKeyPos
order by C.Position

Insert into @tbResult(ResultString)
select 
"			TIDCOLUMN		nvarchar(30) collate database_default,
			TRANSLATIONSOURCEID	int)"

Insert into @tbResult(ResultString)
select 
"
	-- NEW columns to be translated
	-- Columns flagged for translation that have a value but do 
	-- not have a TID value are to generate a TID value"

If upper(@psTable)='NAMETEXT'
Begin
	Insert into @tbResult(ResultString)
	select 
"
	insert into @tbROWS(NAMENO,TEXTTYPE, TIDCOLUMN, TRANSLATIONSOURCEID)
	select i.NAMENO,i.TEXTTYPE, TS.TIDCOLUMN, TS.TRANSLATIONSOURCEID
	from inserted i
	join TRANSLATIONSOURCE TS	on (TS.TABLENAME='NAMETEXT'
					and TS.TIDCOLUMN='TEXT_TID'
					and TS.INUSE    =1)
	where i.TEXT_TID is null"
End
Else Begin
	Insert into @tbResult(ResultString)
	select 
"
	insert into @tbROWS("+@sKeyColumns+", TIDCOLUMN, TRANSLATIONSOURCEID)"

	Insert into @tbResult(ResultString)
	select 
"	select i."+replace(@sKeyColumns,',',',i.')+", TS.TIDCOLUMN, TS.TRANSLATIONSOURCEID
	from inserted i
	join TRANSLATIONSOURCE TS	on (TS.TABLENAME='"+@psTable+"'
					and TS.TIDCOLUMN='"+C.TIDColumn+"'
					and TS.INUSE    =1)
	where i."+C.Name+" is not null
	and   i."+C.TIDColumn+" is null"+
CASE WHEN((select count(*) from @tbColumns C1 where C1.Position>C.Position and C1.TIDColumn is not null)>0)
	THEN "		
	union"
END
	from @tbColumns C
	where C.TIDColumn is not null
	order by C.Position
End

insert into @tbResult(ResultString)
select "
	Set @nNewTID=@@Rowcount

	-- Now load a TRANSLATEDITEMS row for each TID to be generated 
	-- The TID will be generated automatically from the Identity column
	If @nNewTID>0
	Begin
		insert into TRANSLATEDITEMS(TRANSLATIONSOURCEID)
		select TRANSLATIONSOURCEID
		from @tbROWS

		-- Get the value of the last identity column value inserted into TRANSLATEDITEMS
		-- table.  This is required so that we can determine a unique TID value for each
		-- column that has had a TRANSLATEDITEMS row insert when inserting the "+@psTable+" table 
		Select @nMaxTID=SCOPE_IDENTITY()
	End"

If @bTableHasText=1
Begin 
	Insert into @tbResult(ResultString)
	Select "
	If 1=0"

	Insert into @tbResult(ResultString)
	select char(9)+"OR UPDATE("+C.Name+")"
	from @tbColumns C
	where C.TIDColumn is not null
	order by C.Position

	Insert into @tbResult(ResultString)
	Select "
		-- Finally apply the UPDATE to the "+@psTable+" table
		Update "+@psTable+"
		set"

	Insert into @tbResult(ResultString)
	Select char(9)+char(9)+char(9)+C.Name+"="+
		CASE WHEN(C.Name like '%\_TID' escape '\' and C1.Name is not null) 
			THEN "
				CASE	WHEN(i."+C1.Name+" is null"+
					CASE WHEN(C1.RelatedColumn is not null) THEN " and i."+C1.RelatedColumn+" is null" END+
								") THEN NULL
				    	WHEN(i."+C.Name+" is null)
					  THEN (select @nMaxTID-t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.Name+"')
					ELSE i."+C.Name+"
				END"
			ELSE "i."+C.Name
		END+
		CASE WHEN(C.Position<@nColCount) THEN ',' END
	from @tbColumns C
	-- If this is a TID column then get the associated column being
	-- translated.  Only return the first associated column if the TID
	-- column has been used more than once
	left join @tbColumns C1	on (C1.Position=(select min(C2.Position)
						 from @tbColumns C2
						 where C2.TIDColumn=C.Name))
	where C.KeyNo is null
	and C.IsIdentity=0
	order by C.Position

	Insert into @tbResult(ResultString)
	Select"
		from inserted i
		join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"
End
Else If upper(@psTable)='NAMETEXT'
Begin
	Insert into @tbResult(ResultString)
	Select "
	If 1=0"

	Insert into @tbResult(ResultString)
	select char(9)+"OR UPDATE("+C.Name+")"
	from @tbColumns C
	where C.TIDColumn is not null
	order by C.Position

	Insert into @tbResult(ResultString)
	Select "
		-- Apply the UPDATE of TID column to the "+@psTable+" table
		Update NAMETEXT
		set
		TEXT_TID=	CASE	WHEN(i.TEXT_TID is null)
					  THEN (select @nMaxTID-t.ROWNUMBER from @tbROWS t where t.NAMENO=i.NAMENO and t.TEXTTYPE=i.TEXTTYPE and t.TIDCOLUMN='TEXT_TID')
					ELSE i.TEXT_TID
				END

		from inserted i
		join NAMETEXT T1 on (T1.NAMENO=i.NAMENO and T1.TEXTTYPE=i.TEXTTYPE)"
End
Else Begin 
	Insert into @tbResult(ResultString)
	Select "
	If 1=0"

	Insert into @tbResult(ResultString)
	select char(9)+"OR UPDATE("+C.Name+")"
	from @tbColumns C
	where C.TIDColumn is not null
	order by C.Position
	
	Insert into @tbResult(ResultString)
	Select "
		-- Apply the UPDATE of TID columns to the "+@psTable+" table
		Update "+@psTable+"
		set"

	Insert into @tbResult(ResultString)
	Select char(9)+char(9)+char(9)+C.Name+"="+
		CASE WHEN(C.Name like '%\_TID' escape '\' and C1.Name is not null) 
			THEN "
				CASE	WHEN(i."+C1.Name+" is null"+
					CASE WHEN(C1.RelatedColumn is not null) THEN " and i."+C1.RelatedColumn+" is null" END+
								") THEN NULL
				    	WHEN(i."+C.Name+" is null)
					  THEN (select @nMaxTID-t.ROWNUMBER from @tbROWS t where "+@sKeyJoins+" and t.TIDCOLUMN='"+C.Name+"')
					ELSE i."+C.Name+"
				END"
			ELSE "i."+C.Name
		END+
		CASE WHEN((select count(*) from @tbColumns C3 where C3.Position>C.Position and C3.Name like '%\_TID' escape '\')>0) THEN ',' END
	from @tbColumns C
	-- If this is a TID column then get the associated column being
	-- translated.  Only return the first associated column if the TID
	-- column has been used more than once
	left join @tbColumns C1	on (C1.Position=(select min(C2.Position)
						 from @tbColumns C2
						 where C2.TIDColumn=C.Name))
	where C.Name like '%\_TID' escape '\'
	and C.IsIdentity=0
	order by C.Position

	Insert into @tbResult(ResultString)
	Select"
		from inserted i
		join "+@psTable+" T1 on ("+replace(@sKeyJoins,'t.','T1.')+")"
End

insert into @tbResult(ResultString)
select "

	-- TRANSLATION TEXT to be flagged for update
	-- If the text has been changed and the TID exists then set the HASSOURCECHANGED
	-- flag on to indicate that the translation requires review"
If upper(@psTable)='NAMETEXT'
Begin
	Insert into @tbResult(ResultString)
	Select "
	Update TRANSLATEDTEXT
	set HASSOURCECHANGED=1
	from inserted i
	join TRANSLATEDTEXT TT on (TT.TID=i."+C.TIDColumn+")"
	From  @tbColumns C
	where C.TIDColumn is not null
	order by C.Position
End
Else Begin
	Insert into @tbResult(ResultString)
	Select "

	-- TRANSLATIONS and TID to be REMOVED
	-- If the text has been set to NULL but the TID exists then the translation is
	-- to be removed."

	Insert into @tbResult(ResultString)
	select "
	If UPDATE("+C.Name+")
	Begin
		delete TRANSLATEDITEMS
		from inserted i
		join TRANSLATEDITEMS TI	on (TI.TID=i."+C.TIDColumn+")
		where i."+C.Name+" is null"+
		CASE WHEN(C.RelatedColumn is not null) 
			THEN char(10)+char(9)+char(9)+"and i."+C.RelatedColumn+" is null" 
		END+"

		update TRANSLATEDTEXT
		set HASSOURCECHANGED=1
		from inserted i
		join deleted t	on ("+@sKeyJoins+")
		join TRANSLATEDTEXT TT	on (TT.TID=i."+C.TIDColumn+")
		where "+
		CASE WHEN(C.Type like '%text')
			THEN "dbo.fn_IsNtextEqual(i."+C.Name+",t."+C.Name+")=0"
			ELSE "i."+C.Name+"<>t."+C.Name
		END+
		CASE WHEN(C.RelatedColumn is not null)
			THEN char(10)+char(9)+char(9)+"or (t."+C.Name+" is not null and i."+C.Name+" is null and i."+C.RelatedColumn+" is not null)"
		END+"
	End
	"
	from @tbColumns C
	where C.TIDColumn is not null
	order by C.Position
End

Insert into @tbResult(ResultString)
Select "
End
go"

--------------------------------------------------------------------------------------
-- Dump out the generated triggers
--------------------------------------------------------------------------------------
select ResultString as ' '
from @tbResult order by LineNumber
go

grant execute on dbo.util_GenerateTranslationTriggers  to public
go
