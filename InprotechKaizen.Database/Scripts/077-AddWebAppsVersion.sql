Begin
declare @controlId nvarchar(50)='Inprotech Web Apps Version',
		@comment nvarchar(150)='This is an indicator of the Inprotech Apps release version installed and is updated with every Apps upgrade.',
		@ReleaseName nvarchar(50)='Inprotech Apps 3.3';

	if not exists(select * from sitecontrol where controlid=@controlId)
		Begin 

			declare @versionID int,
			@SiteControPK int;
			
			select @versionID=VERSIONID from RELEASEVERSIONS where VERSIONNAME=@ReleaseName
			if(@versionID is null)
				begin
					insert into RELEASEVERSIONS(VERSIONNAME,RELEASEDATE,SEQUENCE)values(@ReleaseName,'20160513',330000);
					set @versionID=SCOPE_IDENTITY();
				end

			insert into SITECONTROL(CONTROLID, DATATYPE, COLCHARACTER,VERSIONID, COMMENTS,NOTES, INITIALVALUE) 
			values(@controlId, 'C', '',@versionID, @comment, @comment, 'current release'); 
			set @SiteControPK=SCOPE_IDENTITY();

			insert into SITECONTROLCOMPONENTS(SITECONTROLID,COMPONENTID) 
			values(@SiteControPK, 
					(select COMPONENTID from COMPONENTS where COMPONENTNAME = 'Inprotech')); 

			insert into SITECONTROLCOMPONENTS(SITECONTROLID,COMPONENTID) 
			values(@SiteControPK, 
					(select COMPONENTID from COMPONENTS where COMPONENTNAME = 'IP Matter Management')); 
		end;

	else
		Begin	

			if not exists(select * from RELEASEVERSIONS where VERSIONNAME=@ReleaseName)
				begin
					update RELEASEVERSIONS set VERSIONNAME=@ReleaseName,RELEASEDATE='20160513',SEQUENCE=330000 where VERSIONID=(select VERSIONID from SITECONTROL where CONTROLID=@controlId)
				end
			else
				begin
					if not exists (select * from RELEASEVERSIONS where VERSIONNAME=@ReleaseName and VERSIONID = (select versionid from sitecontrol where controlid=@controlId))
						begin
							declare @existingVersionId int;
							select @existingVersionId=versionId from SITECONTROL where CONTROLID=@controlId;
					
							update SITECONTROL set VERSIONID=(select VERSIONID from RELEASEVERSIONS where VERSIONNAME=@ReleaseName) where CONTROLID=@controlId;
					
							delete from RELEASEVERSIONS where VERSIONID=@existingVersionId and VERSIONNAME!=@ReleaseName;
						end
				end
		End
END;