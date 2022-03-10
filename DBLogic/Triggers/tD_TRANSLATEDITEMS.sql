-----------------------------------------------------------------------------------------------------------------------------
-- Creation of trigger tD_TRANSLATEDITEMS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where type='TR' and name = 'tD_TRANSLATEDITEMS')
begin
	PRINT 'Refreshing trigger tD_TRANSLATEDITEMS...'
	DROP TRIGGER tD_TRANSLATEDITEMS
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE TRIGGER tD_TRANSLATEDITEMS on TRANSLATEDITEMS instead of DELETE NOT FOR REPLICATION 
as
-- TRIGGER :	tD_TRANSLATEDITEMS
-- VERSION :	2
-- DESCRIPTION:	When the TRANSLATEDITEMS parent row is deleted then any child references
--		are to be set to NULL
--		NOTE : This needs to be an INSTEAD OF trigger so that the actual
--		       TRANSLATEDITEMS rows are deleted after all references are removed

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Sep 2004	MF		1	Trigger created
-- 22 Sep 2004	MF	RFC1500	2	Change to an INSTEAD OF trigger so the removal of the
--					TRANSLATEDITEMS rows can be delayed until all references
--					are removed.

Begin
	-- Only update the child references if the TRANSLATEDITEMS row(s) has been 
	-- deleted directly and not from within another trigger
	if trigger_nestlevel() = 1
	Begin
		declare @sSQLString	nvarchar(4000)
		declare	@sTable		nvarchar(30)
		declare @sTIDColumn	nvarchar(30)
		declare @sTIDList	nvarchar(3500)
		declare	@nSourceId	int
		declare	@nRowCount	int
		declare	@bUseTempTable	bit
		
		-- Create a comma separated list of the TID values to be deleted
		Select @sTIDList = ISNULL(NULLIF(@sTIDList + ',', ','),'')  + convert(varchar,TID)
		from deleted

		-- If the entire list of TID values do not fit into the @sTIDList variable
		-- then we need a temporary table to 
		If LEN(@sTIDList)=3500
		Begin
			Create table #TEMPDELETED (TID	int)

			insert into #TEMPDELETED
			select TID from deleted

			Set @bUseTempTable=1
		End

		-- If the list of TID has filled the entire availabl @sTIDList
		select 	@nSourceId	=d.TRANSLATIONSOURCEID,
			@sTable		=T.TABLENAME,
			@sTIDColumn	=T.TIDCOLUMN
		from deleted d
		join TRANSLATIONSOURCE T	on (T.TRANSLATIONSOURCEID=d.TRANSLATIONSOURCEID)
		where d.TRANSLATIONSOURCEID=(	select min(d2.TRANSLATIONSOURCEID)
						from deleted d2)

		Set @nRowCount=@@Rowcount

		-- If multiple rows have been deleted then we need to loop through each
		-- different source
		WHILE @nRowCount>0
		and   @sTable     is not null
		and   @sTIDColumn is not null
		Begin
			If @bUseTempTable=1
			Begin
				Set @sSQLString=
				"Update "+@sTable+char(10)+
				"Set "+@sTIDColumn+"=null"+char(10)+
				"From "+@sTable+" T"+char(10)+
				"Join #TEMPDELETED d on (d.TID=T."+@sTIDColumn+")"
			End
			Else Begin
				Set @sSQLString=
				"Update "+@sTable+char(10)+
				"Set "+@sTIDColumn+"=null"+char(10)+
				"From "+@sTable+" T"+char(10)+
				"Where T."+@sTIDColumn+" in ("+@sTIDList+")"
			End

			exec sp_executesql @sSQLString

			-- Get the next source to be updated

			select 	@nSourceId	=d.TRANSLATIONSOURCEID,
				@sTable		=T.TABLENAME,
				@sTIDColumn	=T.TIDCOLUMN
			from deleted d
			join TRANSLATIONSOURCE T	on (T.TRANSLATIONSOURCEID=d.TRANSLATIONSOURCEID)
			where d.TRANSLATIONSOURCEID=(	select min(d2.TRANSLATIONSOURCEID)
							from deleted d2
							where d2.TRANSLATIONSOURCEID>@nSourceId)

			Set @nRowCount=@@Rowcount
		End
	End
	
	-- Delete the chid TRANSLATEDTEXT rows
	delete TRANSLATEDTEXT
	from TRANSLATEDTEXT T
	join deleted d on (d.TID=T.TID)

	-- Now delete the TRANSLATEDITEMS rows
	delete TRANSLATEDITEMS
	from TRANSLATEDITEMS T
	join deleted d on (d.TID=T.TID)
End
go
