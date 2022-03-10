-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_Encrypt
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_Encrypt') and xtype='FN')
Begin
	 Print '**** Drop function dbo.fn_Encrypt.'
	 Drop function [dbo].[fn_Encrypt]
End
Print '**** Creating function dbo.fn_Encrypt...'
Print ''
go

CREATE function dbo.fn_Encrypt 
(
	@psClearText 		nvarchar(268),
	@pnReturnTextLength 	smallint = 268
)
Returns nvarchar(268)
With ENCRYPTION
AS 
-- function :	fn_Encrypt
-- VERSION :	4
-- DESCRIPTION:	Decrypt the passed data
-- NOTES:	We need to keep the encryption and decryption separate because
--		we are only going to deliver the decryption part to the client
--
--		NOTE: DO NOT DELIVER THIS TO THE CLIENT
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21/04/2004	JB		1	function created.
-- 19/08/2004	JB		2	change function to use only printable characters.
-- 11/11/2004	JEK		3	Include the length of the string in the algorithm
--					if the @pnReturnTextLength = -1.
-- 29/05/2006	vql	11588	4	changed to encryption string length to from 254 to 268.
Begin

Declare @nCount smallint
Declare @sKey nvarchar(4000)
Declare @nClearChar smallint
Declare @nKeyChar smallint
Declare @sEncryptedText nvarchar(268)  -- The result
Declare @nClearTextLength smallint
Declare @nAddend smallint

Set @sEncryptedText = ''
Set @sKey = 'TuArLngthDDsLEconcQrGnstGQnotLHnoHfanQffQctLvQormHQchanLcalHmQthodLHnlogLcanHdmathQmatLffQctLvHdLtssynonymQchanLcrQtQrmsofartLnthQsQdLscLplLnQsAthQydonotcarrythQLrQvQrydaymQanLngBAmQthodPorprocQdurQPMPforachLQvLngsomQdQsLrQdrQsultLscallQdYQffQctLvQYorYmQchanLcalYjustLncasQMLssQtoutLntQrmsofafLnLtQnumbQrofQxactLnstructLonsNQachLnstructLonbQLngQxprQssQdbymQansofafLnLtQnumbQrofsymbolsKOMwLllPLfcarrLQdoutwLthoutQrrorPproducQthQdQsLrQdrQsultLnafLnLtQnumbQrofstQpsOMcanNLnpractLcQorLnprLncLplQKbQcarrLQdoutbyahumanbQLngunaLdQdbyanymachLnQrysavQpapQrandpQncLlOMdQmandsnoLnsLghtorLngQnuLtyonthQpartofthQhumanbQLngcarryLngLtoutBAwQllQknownQxamplQofanQffQctLvQmQthodLsthQtruthtablQtQstfortautologousnQssBLnpractLcQPofcoursQPthLstQstLsunworkablQforformulaQcontaLnLngalargQnumbQrofproposLtLonalvarLablQsPbutLnprLncLplQonQcouldapplyLtsuccQssfullytoanyformulaofthQproposLtLonalcalculusPgLvQnsuffLcLQnttLmQPtQnacLtyPpapQrPandpQncLlsBStatQmQntsthatthQrQLsanQffQctLvQmQthodforachLQvLngsuchQandQsucharQsultarQcommonlyQxprQssQdbysayLngthatthQrQLsanQffQctLvQmQthodforobtaLnLngthQvaluQsofsuchQandQsuchamathQmatLcalfunctLonBForQxamplQPthatthQrQLsanQffQctLvQmQthodfordQtQrmLnLngwhQthQrornotanygLvQnformulaofthQproposLtLonalcalculusLsatautologyhTQBgBthQtruthtablQmQthodhTLsQxprQssQdLnfunctLonQspQakbysayLngthatthQrQLsanQffQctLvQmQthodforobtaLnLngthQvaluQsofafunctLonPcallLtTPwhosQdomaLnLsthQsQtofformulaQofthQproposLtLonalcalculusandwhosQvaluQforanygLvQnformulaxPwrLttQnTNxKPLs1or0accordLngtowhQthQrxLsPorLsnotPatautologyBThQnotLonofanQffQctLvQmQthodLsanLnformalonQPandattQmptstocharactQrLsQQffQctLvQnQssPsuchasthQabovQPlackrLgourPforthQkQyrQquLrQmQntthatthQmQthoddQmandnoLnsLghtorLngQnuLtyLslQftunQxplLcatQdBOnQofTurLngsachLQvQmQntsLnhLspapQrof1936wastoprQsQntaformallyQxactprQdLcatQwLthwhLchthQLnformalprQdLcatQYcanbQcalculatQdbymQansofanQffQctLvQmQthodYmaybQrQplacQdBChurchdLdthQsamQN1936aKBThQrQplacQmQntprQdLcatQsthatTurLngandChurchproposQdwQrQPonthQfacQofLtPvQrydLffQrQntfromonQanothQrPbutthQyturnQdouttobQQquLvalQntPLnthesQnsethatQachpLcksoutthesamQsetofmathQmatLcalfunctLonsBTheChurchQTurLngthQsLsLstheassQrtLonthatthLssetcontaLnsQveryfunctLonwhosQvaluescanbQobtaLnedbyamQthodsatLsfyLngtheabovQcondLtLonsforeffQctLvenQssBNClearlyPLfthQrewQrefunctLonsofwhLchthQLnformalpredLcatQPbutnottheformalprQdLcatePwQretruQPthenthQlatterwouldbQlessgQneralthanthQformerandsocouldnotrQasonablybeQmployedtoreplacQLtBKWhenthQthesLsLsQxpressQdLntermsofthQformalconceptproposQdbyTurLngPLtLsapproprLatetorQfertothQthesLsalsoasTurLngsthQsLsYOandmutatLsmutandLsLnthecasQofChurchBTheformalconcQptproposedbyTurLngLsthatofcomputabLlLtybyTurLngmachLnQBHearguQdfortheclaLmNTurLngsthQsLsKthatwheneverthQreLsanQffQctLvQmethodforobtaLnLngthQvaluesofamathQmatLcalfunctLonPthefunctLoncanbQcomputedbyaTurLngmachLnQBTheconvQrseclaLmLsQasLlyestablLshQdPforaTurLngmachLneprogramLsLtsQlfaspecLfLcatLonofanQffectLvQmethodAwLthoutQxercLsLnganyLngQnuLtyorLnsLghtPahumanbeLngcanworkthroughthQLnstructLonsLntheprogramandcarryoutthQrequLrQdoperatLonsBLfTurLngsthesLsLscorrectPthQntalkaboutthQQxLstQncQandnonQQxLstQncQofQffQctLvQmQthodscanbereplacedthroughoutmathematLcsandlogLcbytalkabouttheexLstencQornonQQxLstQncQofTurLngmachLnQprogramsBTurLngstatedhLsthesLsLnnumerousplacesPwLthvaryLngdegreesofrLgourBThQfollowLngformulatLonLsonQofthQmostaccQssLblQBTurLngsthesLsALCMsLlogLcalcomputLngmachLnesATurLngsexpressLonforTurLngmachLnesLcandoanythLngthatcouldbedQscrLbQdasDrulQofthumbDorDpurQlymQchanLcalDBNTurLng1948A7BKHQaddsAThLsLssuffLcLentlywellestablLshQdthatLtLsnowagrQQdamongstlogLcLansthatDcalculablQbymeansofanLCMDLsthecorrectaccuraterendQrLngofsuchphrasQsBN1948A7BKTurLngLntroducQdthLsthQsLsLnthecourseofarguLngthattheEntscheLdungsproblQmPordQcLsLonproblQmPforthepredLcatecalculusQposQdbyHLlbQrtNHLlbQrtandAckQrmann1928KhTLsunsolvablQBHQreLsChurchsaccountoftheEntscheLdungsproblemABytheEntscheLdungsproblemofasystemofsymbolLclogLcLshereunderstoodtheproblemtofLndaneffectLvemethodbywhLchPgLvenanyexpressLonQLnthenotatLonofthesystemPLtcanbedetermLnedw'
Set @nCount = 1

If @pnReturnTextLength < 0
Begin
	-- Look up the key for the clear text position plus the length of the string
	Set @pnReturnTextLength = len(@psClearText)
	Set @nAddend = @pnReturnTextLength
End
Else
Begin
	Set @psClearText = LEFT(@psClearText + REPLICATE(' ', @pnReturnTextLength), @pnReturnTextLength)
	-- Use the clear text position only
	Set @nAddend = 0
End

While @nCount <= @pnReturnTextLength
Begin
	Set @nClearChar = ASCII(SUBSTRING(@psClearText, @nCount, 1)) 
	Set @nKeyChar = ASCII(SUBSTRING(@sKey, (@nCount+@nAddend), 1))
	Set @sEncryptedText = @sEncryptedText +  CHAR(((@nClearChar + @nKeyChar) % 95) + 32)
	Set @nCount = @nCount + 1 
End

Return @sEncryptedText
End

GO

Grant execute on dbo.fn_Encrypt to public
GO
