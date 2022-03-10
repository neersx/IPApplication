/**********************************************************************************************************/
/*** RFC74789 Update licensing ValidObjects (E-Filing Module)				***/
/**********************************************************************************************************/
If NOT exists (SELECT *
FROM VALIDOBJECT
WHERE TYPE = 40 and OBJECTDATA = '10 242')
        	BEGIN
	PRINT '**** RFC74789 Adding data VALIDOBJECT.OBJECTDATA = ''10 242'''
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1)
	from VALIDOBJECT

	INSERT INTO VALIDOBJECT
		(OBJECTID, TYPE, OBJECTDATA)
	VALUES
		(@validObject, 40, '10 242')
	PRINT '**** RFC74789 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
    	ELSE
         	PRINT '**** RFC74789 VALIDOBJECT.OBJECTDATA = ''10 242'' already exists'
PRINT ''
    	go

/**********************************************************************************************************/
/*** RFC74789 Update licensing ValidObjects (Integration E-Filing Module)				***/
/**********************************************************************************************************/
If NOT exists (SELECT *
FROM VALIDOBJECT
WHERE TYPE = 40 and OBJECTDATA = '10 443')
        	BEGIN
	PRINT '**** RFC74789 Adding data VALIDOBJECT.OBJECTDATA = ''10 443'''
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1)
	from VALIDOBJECT

	INSERT INTO VALIDOBJECT
		(OBJECTID, TYPE, OBJECTDATA)
	VALUES
		(@validObject, 40, '10 443')
	PRINT '**** RFC74789 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
    	ELSE
         	PRINT '**** RFC74789 VALIDOBJECT.OBJECTDATA = ''10 443'' already exists'
PRINT ''
    	go

/**********************************************************************************************************/
/*** RFC74789 New Subject Security for E-Filing Section - DataTopic					***/
/**********************************************************************************************************/
If NOT exists(SELECT *
FROM DATATOPIC
WHERE TOPICID = 8)
        	BEGIN
	PRINT '**** RFC74789 Adding DATATOPIC.TOPICID = 8'
	INSERT	DATATOPIC
		(TOPICID, TOPICNAME, DESCRIPTION, ISEXTERNAL, ISINTERNAL)
	VALUES
		(8, N'E-filing', N'Information regarding the history and progress of e-filing transactions, including package status and contents', 0, 1)
	PRINT '**** RFC74789 Data successfully added to DATATOPIC table.'
	PRINT ''
END
    	ELSE
        	BEGIN
	PRINT '**** RFC74789 DATATOPIC.TOPICID = 8 already exists'
	PRINT ''
END
    	go


/**********************************************************************************************************/
/*** RFC74789 New Subject Security for E-Filing Section - ValidObject					***/
/**********************************************************************************************************/

If NOT exists (SELECT *
FROM VALIDOBJECT
WHERE TYPE = 30
	and OBJECTDATA = ' 282')
        	BEGIN
	PRINT '**** RFC74789 Adding data VALIDOBJECT.OBJECTDATA =  282'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1)
	from VALIDOBJECT
	INSERT INTO VALIDOBJECT
		(OBJECTID, TYPE, OBJECTDATA)
	VALUES
		(@validObject, 30, ' 282')
	PRINT '**** RFC74789 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
    	ELSE
         	PRINT '**** RFC74789 VALIDOBJECT.OBJECTDATA =  282 already exists'
PRINT ''
    	go

If NOT exists (SELECT *
FROM VALIDOBJECT
WHERE TYPE = 30
	and OBJECTDATA = ' 483')
        	BEGIN
	PRINT '**** RFC74789 Adding data VALIDOBJECT.OBJECTDATA =  483'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1)
	from VALIDOBJECT
	INSERT INTO VALIDOBJECT
		(OBJECTID, TYPE, OBJECTDATA)
	VALUES
		(@validObject, 30, ' 483')
	PRINT '**** RFC74789 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
    	ELSE
         	PRINT '**** RFC74789 VALIDOBJECT.OBJECTDATA =  483 already exists'
PRINT ''
    	go

If NOT exists (SELECT *
FROM VALIDOBJECT
WHERE TYPE = 35
	and OBJECTDATA = '9989')
        	BEGIN
	PRINT '**** RFC74789 Adding data VALIDOBJECT.OBJECTDATA = 9989'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1)
	from VALIDOBJECT
	INSERT INTO VALIDOBJECT
		(OBJECTID, TYPE, OBJECTDATA)
	VALUES
		(@validObject, 35, '9989')
	PRINT '**** RFC74789 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
    	ELSE
         	PRINT '**** RFC74789 VALIDOBJECT.OBJECTDATA = 9989 already exists'
PRINT ''
    	go

------------------------------------------------------------------------------------------------------------------------------
-- Creation of b2b_ListPackageDetails																						--
------------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[b2b_ListPackageDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.b2b_ListPackageDetails.'
	Drop procedure [dbo].[b2b_ListPackageDetails]
End
Print '**** Creating Stored Procedure dbo.b2b_ListPackageDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.b2b_ListPackageDetails
(
	@psCulture	nvarchar(10) = null,
	@psCaseId	nvarchar(max)
)
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

select  'e2e-PackageType' as PackageType, 
	'e2e-PackageReference01' as PackageReference, 
	'e2e-Status01' as CurrentStatus, 
	'e2e-StatusDescription001' as CurrentStatusDescription, 
	'e2e-NextEventDue' as NextEventDue, 
	getdate() as LastStatusChange, 
	'e2e-User' as UserName, 
	'e2e-Server' as Server, 
	1 as ExchangeId, 
	1 as PackageSequence
union
select  'e2e-PackageType' as PackageType, 
	'e2e-PackageReference02' as PackageReference, 
	'e2e-Status02' as CurrentStatus, 
	'e2e-StatusDescription002' as CurrentStatusDescription, 
	NULL as NextEventDue, 
	getdate() as LastStatusChange, 
	'e2e-User' as UserName, 
	'e2e-Server' as Server, 
	2 as ExchangeId, 
	1 as PackageSequence


Grant execute on dbo.b2b_ListPackageDetails to public
GO

------------------------------------------------------------------------------------------------------------------------------
-- Creation of b2b_ListPackageFiles																							--
------------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[b2b_ListPackageFiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.b2b_ListPackageFiles.'
	Drop procedure [dbo].[b2b_ListPackageFiles]
End
Print '**** Creating Stored Procedure dbo.b2b_ListPackageFiles...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.b2b_ListPackageFiles
(
	@pnCaseId		int,
	@pnExchangeId	int,
	@pnPackageSeqNo	int
)
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

select 'e2e1-ComponentDescription' as ComponentDescription, 'e2e1-FileName.jpg' as FileName, 100071 as FileSize, 'jpg' as FileType, 1 as Outbound, 1 as PackageFileSequence
union
select 'e2e2-ComponentDescription' as ComponentDescription, 'e2e2-FileName.jpg' as FileName, 100070 as FileSize, 'jpg' as FileType, 1 as Outbound, 1 as PackageFileSequence
union
select 'e2e3-ComponentDescription' as ComponentDescription, 'e2e3-Response-FileName.jpg' as FileName, 100069 as FileSize, 'jpg' as FileType, 0 as Outbound, 1 as PackageFileSequence

Grant execute on dbo.b2b_ListPackageFiles to public
GO

------------------------------------------------------------------------------------------------------------------------------
-- Creation of b2b_RetrieveFileData																							--
------------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[b2b_RetrieveFileData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.b2b_RetrieveFileData.'
	Drop procedure [dbo].[b2b_RetrieveFileData]
End
Print '**** Creating Stored Procedure dbo.b2b_RetrieveFileData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.b2b_RetrieveFileData
(
	@pnCaseId			int = null,
	@pnPackageSeqNo		int = null,
	@pnPackageFileSeqNo	int = null,
	@pnExchangeId		int = null
)
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

select 0x504B0304140000000800275B4C4D460A2E11810E0000270F000008000000444553432E6A70679D966754D34D9BC6FFA1F72A418812E908D2A4234504544444A4830AD28B21A022350410A40846400141402C1435861208201269A128BD492741AA20011E4394906C78CFBBBB5FF6C3EE5E3373CE9C3333F75CBFB9CFCC19C677C6022074E9BCD579000402019ECC0230A601738005043AACFF162B3BEBA138D8D858D9393938390F1B17372F3717170F1727270F3F0F0F2F1F539CDC0282FC7C0287FDC32087CB0F57312B1F172717DFFF598C2F803017600498B3826400166110AB3088D101400100C40EFA97807F0BC4C2CAC6CEC1B4C4C3CB9C5027C4B4CFCACAC234CBCEC6C61C4530C70136617611694D330E51BB5B9C3261474E27649572C99EAB6E15BB364496D3F2BA93C8CD03163F2A2129AFA0A87452595B47574FDFC0D0DCC2F2FC858B5697EC1D1C9D9C5D5CDDBC7D7CFDFC030283EEDE0BBF1F111915FD2029F9614A6A5A7A76CED367B979F9CF0B5EBD7EF3B6ACBCA2F25D4D2DB6AE1ED7D0D8D4D6DED149E8EAEEE91D1E191D1B9FF83E3945242DFE585A5E595D5BDFDED9FDE737658FFAE7EF2117086005FDA7FE472E6126170B33076C9C875C209688C309C26CECD29A1C2266769CB7C244654E27701D3997555ADDCA2DAB758D2CE6756788072CA74D94DF3E44FB17D9FF0E2CF1FF45F65F60FFCD3505F0B18298C96315064C8183E1F3A7A5C47A388F093080923FA47873EB44870D04264502756C652B14B11FBEE961401FC60BD0C5E37AF06C7548A9A0BFFE99F04D6D69F19C72D7C83CC7821587A68686C72AD6FADE7A663EB9AEC5FA4FF1BD6537BE9D4B0CDE1DB03F28A8B37D24A5DB3851577224F20F3CD692CDF79E077724CE1537B8017614393F0EA774CF6D67581B557D354A575086CB5BDB1802B5803FB2D5BFD9148E89851F5422B1D8ED281834116B1D73B27C286E9EA7FBD456089BDD0548D49EC839A3E9670F65543747FB107776200132A6E60CA0F576B371F9DA3C56BD75D3AF77FA0A03481A682F66DD1E9B48FCB052638D1DFB4D40700C1F3774E1182D98FB05799FEAEBF4E5E28FACD6ABCFA1FC71A353D076381BED0CB59338CBD289276A6D0F245B3465A0A34850219B0A77987D7955537831F103A1BB604A31008FF5E30D0F3F060E9DEE3848A181D517BBDAE1532A94C9F158DB8845789AA66BA439F151FB42C53F8545D697EA779772AE3E7207FF1212C45A854C857FD2F29AB910EAD7A4CE8F9BF4057E9B5215E7EACA63650EDEC14C34A77FEE19F6E57560D27F92BF76E19A321FB5DF8DA85C6F111DD4E1756EA8CFA47DB282FDEE0EF930CEFF1686ACF34DF3F9038998431ED1CE3FC100123FD0445BEAEB70E931A814137D5C73E3C55DB9C10B1554D8B05EB8CA931AA30CD1ACECBEC736717A2E7143261254AD0541D4CE1A543416F9EE4D01328576AFFAE63415E55A55D8592F3956F69AD75267B33A5B2E58E58C3E7BDF64BA7BC3C880A6B9F8932CFA2C7D025A25DEBA35DD3F7F36858463EEEA59C03283F4ADEB5CEAC3E67A11655D9FF9D4E79A9429997F7481AABA2C069C609D327F92D072AB2159BF9527EC49F40A246A6118D1A6010D5CBD0F8DC5CDCEA22A373D5868564C02219A0E150E8793E009BA5A91C88E68EDBB8691C11D6E7DF45A225EEC1941F523783D6A1997B3E7EEDD88F5896C9E5D923F3B643A88AC09794EDEA23CA48A9753BB2CC80E05CAD48712F7D01E56785799CF23EAAA6A37E7166D8B0AE96EEE339DDAF24FA27C49A78ED7BF16120CD7E3127486878DFCB1BB196AEA8D4C427F9B131A4C7AB3841FFA71B9E4FAFD57F126014C4FA4EBA71880601C281027D41EE3FB8E76BD3A91D4160C295CC5F8A22E8CFD527D326DDED7BAEF00EEAFEAB610D87E5994ABBAD162A788D25E6B3E79E732780A3BF596B01BAE09330BF9D1D810305ACD9759F1E86BC54DF99DB3F4F1DCEF8447027901E677F0E46BF0E997719325B517BE081EA5AA13CB33D5B4212519B05BBE944DE72B385487A8D95BEA832B0D588BEAD19BD6C9D90E5926DF6ACEE356E3FA6B1E84F287B528520748312AC6375D5A04A9258ED667AC27670752B5637AEAB8D9B2BEE3F329B877C79A92B1391B296A5E36E04E27FD5F3F3C05DF982E64E064561619C0A6D8B1EC1B373A43E912CD28BB06F5D0F0CC7167E1BAAE6948A6E5E46278F06F5EBE4C08BA09517CF4D80AF392F9C4DA938E43285DD4E3A501BAF06823047991844F81A3BD1F6C72DC47481296F5AF9D42E921C65EF0381B20A6CD7A3046CC530CA00FB6685211FB9E71C3F54D11ADD054298351452931FAA8E195EA97D8DC61B51223B91B33B3EB4EF535D73550F0ACF2BCBABA1D9B1AA09A338601901DB6A8EEF39066F385ADF4AFFBBA5406603D1C271809EFA89DEFFC18896AF75578BC84FD94D2EBB63E7C69E8A080F09B87D066BE5C71DE493A9EBD31D622EE645CFF61102B34DA6F3FB47A141B81D34CD0AE75A34A8DF79EAD789921015BE2C5A9F643E5780EA0547F520C3415C96F648A71B115FB55F87ECD692FB7B6A2B78F8DFCA63A6B134BB79858F1A089E6B4794018809F2D7FAC7BCB3674A39D04735B24A1FF91927647A877B44072799F2FD73A365C1059D7E7DAADE4CD43748B87FEB18919A0092F764D8DA136F62A63A5B6439EBF8B8C219882C26DA916F3D663F0DB181D50697EEEA245B1736D44FCAF911FB8D426DDCBF57759AC38E24D1A233C874DE5B7738AADBA644DF32EFDA9A57093FBCA13E24ED3C7A2C5AAE25DDC635D60E7949E824418404024FCDCA81F004A68096E9CADDE2B76F6CEEE32B50CDAF36BB76A2ABA155C962821275479A2F7AC625056B762594CCCC4129E26C400289BDB7A8F18C0421112DA624CED25AD909C33D46223717FD386B09DD8DD6529A941E98B169AE5DDF59F2E87F42625E12240BB0F8103EB17D7F3209EBBCE41C41916F704CBD83E72219D1744CEEBF210C0A2DD56EC479BB5226284638AD4EDC8FD3513607B0E19CB53F50DB79A359DA051975EF091D201EA16A5940A22A2BEB753D40E8A8D74882ACEE465146C7BC5FE2EDF9C42436D9AF3FE998EC1E4E01E5ACF3888E74D48F5C9C62CDE53A66B6ADCAB1FBC6310BAEB07F43E4F8A908FFB4CC986E388D3D46469835F240E91802686B1D5B47EBE5718E85D5D2BB22E6EDF5BA4473B425FFB80F41B488C1E15D773A2447B74159D8B79B46F3D1D69D251A62E32D5D68788D87145E946CAEAC56BE72EDB1A1E89F2CE843CCB21C10E30295313171B8A55BCDA34294E29568FD9D3640B945E3FF65CFED2C99DBD28BA842D8C92FCB5E661DF78F129EB90E9C2E3506BDF7D47FA10654BB5655361BECD0D9E2D1D6C85663344B4A5FAD65DF3AC527EA503D688CDFD2A29AB996F83C298066F2A4CB81F64D395BE0781E8AD31C4E36E73ABAAA3BAC9AF824F3A7615E9FD7A256FFAD8AC3AAC31C1F2048D9927B66447E4D43C254B33AACAEC784992CCE31EFC7D55597795E10498805BDBE98F3C53976D7A3FCA15DE9E10554678EF07AFC1D0718479F0C66BDCBE4F5E31FFF809F7D0C26612C55EED5B44CF09E4DF55D65A2A52DA846728F669C091C041658EE7F272F9840BF9198EF9C74E4E69840A5EF65EDE54EF58694392DDFBE0E7E2CF5545CE2F643EAC347C151F1168B834AA59EB79E7D27A7FA3F12BD63A8438B9EC44092F4D2BDF64408F62997F316E2B9720764B626D0825F17BCFE0CF0A5121D377DB9CCEB3BBFD809035355343D3270B242C7061A4C4847566C73A97AB11921A2B4B89378E773380B29FC577CF42AFF5163E5989600D53D613BA6000BD2CDA6514D6DD17DB45FEB43097B6FDA9CBA30E95ACF3C8CF109A6E1416187C5FB5485C890E26FF7DC6D76C98CB5675FBE189D7FC494A7FC3A77BF8BA325F178725CC67754B1D344DF49A92AD31EC815202DBCE9BE60A89B8F9EF8618429FDB7ABFEB7220D8F54A49397A87D0853AA9A35941788757CE9F11488CD7A9C350E5F45A55A399AFA606D5F6F25069C0E2C50DF46D58AE92989D83F79D10B9E41ED55CB9EC8E6C1BB17F92DA57164E1C05F8E3173CA30B9458973D924AF8683AFBB7E3DA6F2A92E32A31417986269F48A622AEC8A040E7AF076FCBAEB792781B611F61BE96D26AAA658F2548F76D732F2E48EBD6BB1319403A5D925ABBCFB7AA87D90E6E8F2E5A798885AB29D190448852B80DD8DD652950B68024B1A2EE7F3747FCD7966CF16090DEB5F999B91BA9B7924DE2992FB0B07149BBE97785AFB64358F4E93E759A2D296D4BEE626A7097945C33D6295460EE44BADC1F8730117F7DB407551549B0B9A94E95DD22CCBAE9D45837FC83D074DE3B3372A0B0AC70FBBD88C04806EB93B05DCE9702FE74AE66B9BA03343E60DA093CF841D2363165125D025E1D80553604647D69BEBAEA0DD7BBDA393BFFF5DE4FC96F599849065047FFAC98CC007C30E96E2FEC74BE154424E904BF49535BC66A3DAD799E9856AA72CA9560D4DD7DAFDFE1070FED23D3B8117D5C925EB87F8F3E690D2E24920B6E7E7AB9FABE308A2FCF0B3C96F531447ED768F2979FCFE99E531F3B3E3D2915B613DD6000D3CE94ECF1DFF049715251D278B4190E4F0E41C39553DF2CF9543F77A71E08FE39769573709134F7888CA704D942220BFE1A2BB617401F9EC7BD9FED59B9529F5B3599E6F76C47D295878026F07D1097CB0E5EB4FD2E48E96EA61AEC1BAFBBAD64D0F9E2063DC85526323FF3E806DB166E1EED9FAF91B49BF12FB4C143674A03D9D1056E934A5DDF4E991120628BF87AC5CD5AD2403ABE36E5CB16D77ABDC9F19C76BAE1F6448AF6E7E8910D984CD0FDABEEF52F613E2267FC4EFA5527F87A2CA2A2A1CF52316F3F20175ED30D4AAEF1DC1BE005EDFA8347126D9FEEE4949C31903F8230269FE5C0A4E0610C20158FDB6BEB46125FD084491E5C017459B323D0234661E5E6C1E56BF78BBDBA54C74BCA9EFB14D3D79C914FF3B8F91BB3ACAD65658E7AAC62262716A452F6356225C97B09461A7BFE9706557BDF8E1DF4F6DDADB495D5CE13C70966F418776CC9ED9CB9B36394B2C4B94CDB652644396E4C4A86EC4113295FF045A33F66C9F02BFCD518B154D110BE61F2CDEB2CE79C31B06AACB23A2F1E3757AC4E66FEC2A59B536CC8D3565A6FE4DDE642DF619465BD6FBF7C2C88B9AAC4BA0181DCA0BC8BC5B6F6CF1BB2F8F0169FBEBB96AE422CF4A02A31808CDF5C53AEF74C39B1C933E07D9D097D2F2D3A7E2A1D604CFE07504B01021400140000000800275B4C4D460A2E11810E0000270F0000080000000000000000002100000000000000444553432E6A7067504B0506000000000100010036000000A70E00000000 as FileData,
'jpg' as FileType, 'DESC.jpg' as FileName

Grant execute on dbo.b2b_RetrieveFileData to public
GO

------------------------------------------------------------------------------------------------------------------------------
-- Creation of b2b_ListPackageHistory																						--
------------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[b2b_ListPackageHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.b2b_ListPackageHistory.'
	Drop procedure [dbo].[b2b_ListPackageHistory]
End
Print '**** Creating Stored Procedure dbo.b2b_ListPackageHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.b2b_ListPackageHistory
(
	@psCulture		nvarchar(10) = null,
	@pnExchangeId	int
)
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sLookupCulture		nvarchar(10)
Declare @sSqlString			nvarchar(max)

select getdate() as StatusDateTime, 'Task completed successfully.' as Status, 'Task completed successfully (Prepare Package).' as StatusDescription
union
select getdate()+1 as StatusDateTime, 'Pack for DPMA failed.' as Status, 'Pack for DPMA failed. There was an error connecting to the URL: http://localhost/CPAInpro/apps Please ensure the Inprotech Web Application Security Token is correct.' as StatusDescription
order by StatusDateTime desc

Grant execute on dbo.b2b_ListPackageHistory to public
GO