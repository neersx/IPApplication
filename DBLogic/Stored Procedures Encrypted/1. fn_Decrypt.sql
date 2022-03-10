-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_Decrypt
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_Decrypt') and xtype='FN')
Begin
	 Print '**** Drop function dbo.fn_Decrypt.'
	 Drop function [dbo].[fn_Decrypt]
End
Print '**** Creating function dbo.fn_Decrypt...'
Print ''
go

CREATE function dbo.fn_Decrypt
(
	@psEncryptedText 	nvarchar(268) = null,
	@pnMethod		tinyint = 0		-- 0-basic version,
							-- 1-includes length of string in algorithm
)
Returns nvarchar(268)
With ENCRYPTION
AS 
-- function :	fn_Decrypt
-- VERSION :	5
-- DESCRIPTION:	Decrypt the passed data
-- NOTES:	We need to keep the encryption and decryption separate because
--		we are only going to deliver the decryption part to the client
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21/04/2004	JB		1	function created.
-- 19/08/2004	JB		2	change function to use only printable characters.
-- 11/11/2004	JEK		3	Allow decryption from an algorithm that includes the string length
--					Introduced @pnMethod switch to differentiate.
-- 29/05/2006	vql	11588	4	changed to encryption string length to from 254 to 268.
-- 21/10/2011	vql	19887	5	Unable to deliver DB script allencryptedprocs.sql between ClearCase projects.

Begin

Declare @sClearText nvarchar(268)  -- The result
Declare @sKey nvarchar(4000)
Declare @nEncryptChar smallint
Declare @nKeyChar smallint
Declare @nCount smallint
Declare @nCandidate smallint
Declare @nEncryptedTextLength smallint
Declare @nAddend smallint

Declare @sPartKey1 nvarchar(500)
Declare @sPartKey2 nvarchar(500)
Declare @sPartKey3 nvarchar(500)
Declare @sPartKey4 nvarchar(500)
Declare @sPartKey5 nvarchar(500)
Declare @sPartKey6 nvarchar(500)
Declare @sPartKey7 nvarchar(500)
Declare @sPartKey8 nvarchar(500)

Set @sPartKey1 = 'TuArLngthDDsLEconcQrGnstGQnotLHnoHfanQffQctLvQormHQchanLcalHmQthodLHnlogLcanHdmathQmatLffQctLvHdLtssynonymQchanLcrQtQrmsofartLnthQsQdLscLplLnQsAthQydonotcarrythQLrQvQrydaymQanLngBAmQthodPorprocQdurQPMPforachLQvLngsomQdQsLrQdrQsultLscallQdYQffQctLvQYorYmQchanLcalYjustLncasQMLssQtoutLntQrmsofafLnLtQnumbQrofQxactLnstructLonsNQachLnstructLonbQLngQxprQssQdbymQansofafLnLtQnumbQrofsymbolsKOMwLllPLfcarrLQdoutwLthoutQrrorPproducQthQdQsLrQdrQsultLnafLnLtQnumbQrofstQpsOMcanNLnpractLcQorLnprLncLplQKbQcarrLQ'
Set @sPartKey2 = 'doutbyahumanbQLngunaLdQdbyanymachLnQrysavQpapQrandpQncLlOMdQmandsnoLnsLghtorLngQnuLtyonthQpartofthQhumanbQLngcarryLngLtoutBAwQllQknownQxamplQofanQffQctLvQmQthodLsthQtruthtablQtQstfortautologousnQssBLnpractLcQPofcoursQPthLstQstLsunworkablQforformulaQcontaLnLngalargQnumbQrofproposLtLonalvarLablQsPbutLnprLncLplQonQcouldapplyLtsuccQssfullytoanyformulaofthQproposLtLonalcalculusPgLvQnsuffLcLQnttLmQPtQnacLtyPpapQrPandpQncLlsBStatQmQntsthatthQrQLsanQffQctLvQmQthodforachLQvLngsuchQandQsucharQsultarQcommo'
Set @sPartKey3 = 'nlyQxprQssQdbysayLngthatthQrQLsanQffQctLvQmQthodforobtaLnLngthQvaluQsofsuchQandQsuchamathQmatLcalfunctLonBForQxamplQPthatthQrQLsanQffQctLvQmQthodfordQtQrmLnLngwhQthQrornotanygLvQnformulaofthQproposLtLonalcalculusLsatautologyhTQBgBthQtruthtablQmQthodhTLsQxprQssQdLnfunctLonQspQakbysayLngthatthQrQLsanQffQctLvQmQthodforobtaLnLngthQvaluQsofafunctLonPcallLtTPwhosQdomaLnLsthQsQtofformulaQofthQproposLtLonalcalculusandwhosQvaluQforanygLvQnformulaxPwrLttQnTNxKPLs1or0accordLngtowhQthQrxLsPorLsnotPatautolog'
Set @sPartKey4 = 'yBThQnotLonofanQffQctLvQmQthodLsanLnformalonQPandattQmptstocharactQrLsQQffQctLvQnQssPsuchasthQabovQPlackrLgourPforthQkQyrQquLrQmQntthatthQmQthoddQmandnoLnsLghtorLngQnuLtyLslQftunQxplLcatQdBOnQofTurLngsachLQvQmQntsLnhLspapQrof1936wastoprQsQntaformallyQxactprQdLcatQwLthwhLchthQLnformalprQdLcatQYcanbQcalculatQdbymQansofanQffQctLvQmQthodYmaybQrQplacQdBChurchdLdthQsamQN1936aKBThQrQplacQmQntprQdLcatQsthatTurLngandChurchproposQdwQrQPonthQfacQofLtPvQrydLffQrQntfromonQanothQrPbutthQyturnQdouttobQQquLvalQ'
Set @sPartKey5 = 'ntPLnthesQnsethatQachpLcksoutthesamQsetofmathQmatLcalfunctLonsBTheChurchQTurLngthQsLsLstheassQrtLonthatthLssetcontaLnsQveryfunctLonwhosQvaluescanbQobtaLnedbyamQthodsatLsfyLngtheabovQcondLtLonsforeffQctLvenQssBNClearlyPLfthQrewQrefunctLonsofwhLchthQLnformalpredLcatQPbutnottheformalprQdLcatePwQretruQPthenthQlatterwouldbQlessgQneralthanthQformerandsocouldnotrQasonablybeQmployedtoreplacQLtBKWhenthQthesLsLsQxpressQdLntermsofthQformalconceptproposQdbyTurLngPLtLsapproprLatetorQfertothQthesLsalsoasTurLn'
Set @sPartKey6 = 'gsthQsLsYOandmutatLsmutandLsLnthecasQofChurchBTheformalconcQptproposedbyTurLngLsthatofcomputabLlLtybyTurLngmachLnQBHearguQdfortheclaLmNTurLngsthQsLsKthatwheneverthQreLsanQffQctLvQmethodforobtaLnLngthQvaluesofamathQmatLcalfunctLonPthefunctLoncanbQcomputedbyaTurLngmachLnQBTheconvQrseclaLmLsQasLlyestablLshQdPforaTurLngmachLneprogramLsLtsQlfaspecLfLcatLonofanQffectLvQmethodAwLthoutQxercLsLnganyLngQnuLtyorLnsLghtPahumanbeLngcanworkthroughthQLnstructLonsLntheprogramandcarryoutthQrequLrQdoperatLonsBLfT'
Set @sPartKey7 = 'urLngsthesLsLscorrectPthQntalkaboutthQQxLstQncQandnonQQxLstQncQofQffQctLvQmQthodscanbereplacedthroughoutmathematLcsandlogLcbytalkabouttheexLstencQornonQQxLstQncQofTurLngmachLnQprogramsBTurLngstatedhLsthesLsLnnumerousplacesPwLthvaryLngdegreesofrLgourBThQfollowLngformulatLonLsonQofthQmostaccQssLblQBTurLngsthesLsALCMsLlogLcalcomputLngmachLnesATurLngsexpressLonforTurLngmachLnesLcandoanythLngthatcouldbedQscrLbQdasDrulQofthumbDorDpurQlymQchanLcalDBNTurLng1948A7BKHQaddsAThLsLssuffLcLentlywellestablLshQ'
Set @sPartKey8 = 'dthatLtLsnowagrQQdamongstlogLcLansthatDcalculablQbymeansofanLCMDLsthecorrectaccuraterendQrLngofsuchphrasQsBN1948A7BKTurLngLntroducQdthLsthQsLsLnthecourseofarguLngthattheEntscheLdungsproblQmPordQcLsLonproblQmPforthepredLcatecalculusQposQdbyHLlbQrtNHLlbQrtandAckQrmann1928KhTLsunsolvablQBHQreLsChurchsaccountoftheEntscheLdungsproblemABytheEntscheLdungsproblemofasystemofsymbolLclogLcLshereunderstoodtheproblemtofLndaneffectLvemethodbywhLchPgLvenanyexpressLonQLnthenotatLonofthesystemPLtcanbedetermLnedw'

Set @sClearText = ''
Set @sKey = @sPartKey1+@sPartKey2+@sPartKey3+@sPartKey4+@sPartKey5+@sPartKey6+@sPartKey7+@sPartKey8
Set @nCount = 1
Set @nEncryptedTextLength = len(@psEncryptedText)

If @pnMethod = 0
Begin
	-- Original version
	Set @nAddend = 0 
End
Else
Begin
	-- Algorithm including string length
	Set @nAddend = @nEncryptedTextLength
End


While @nCount <= @nEncryptedTextLength
Begin
	Set @nEncryptChar = ASCII(SUBSTRING(@psEncryptedText, @nCount, 1))
	Set @nKeyChar = ASCII(SUBSTRING(@sKey, (@nCount+@nAddend), 1)) 
	Set @nCandidate = ((@nEncryptChar - 32) + 95) - @nKeyChar
	if @nCandidate < 32
		Set @sClearText = @sClearText + CHAR(@nCandidate + 95) 
	else
		Set @sClearText = @sClearText + CHAR(@nCandidate)
	Set @nCount = @nCount + 1 

End

Return @sClearText
End
GO

Grant execute on dbo.fn_Decrypt to public
GO
