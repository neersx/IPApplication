-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StripHTML
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StripHTML') and xtype='FN')
begin
	print '**** Drop function dbo.fn_StripHTML.'
	drop function dbo.fn_StripHTML
	print '**** Creating function dbo.fn_StripHTML...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

set CONCAT_NULL_YIELDS_NULL off
go

CREATE FUNCTION dbo.fn_StripHTML
			(
				@psText NVARCHAR(MAX)
			)
RETURNS NVARCHAR(MAX) 

-- FUNCTION :	fn_StripHTML
-- VERSION :	6
-- DESCRIPTION:	This funtion is used to remove rich text formattings. 
--		please refer 
--		http://www.ninjacode.com.br/Blog/2013/03/27/functions-sql-server/ 
--		http://blog.sqlauthority.com/2007/06/16/sql-server-udf-user-defined-function-to-strip-html-parse-html-no-regular-expression/
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description 
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Feb 2014	AK		1	Function created
-- 03 Mar 2014	AK		2	Included logic to remove valid html tags only
-- 08 APR 2014	AK		3	Included logic to remove valid html tags only and ignore custom tags
-- 03 AUG 2017	SF		4	Make compatible with case sensitive server with case insensitive database
-- 25 Oct 2017	MF	72706	5	Changed collate to Latin1_General_CI_AS when comparing the <p> tag (Courtesy of AK of Novagraaf)
-- 07 Dec 2017	AK	R72645	6	Make compatible with case sensitive server with case insensitive database

AS
BEGIN
	DECLARE @sResult NVARCHAR(MAX)
	DECLARE @sCrLf NVARCHAR(2)
	DECLARE @nPos SMALLINT
	DECLARE @sEncoded NVARCHAR(7)
	DECLARE @nChar SMALLINT
	DECLARE @sCurrentSelectedTag nvarchar(max)	
	Declare @sTagtoRemove nvarchar(max)	
	DECLARE @sHTMLTagsToRemove nvarchar(max)
	DECLARE @sSubString nvarchar(max)
	DECLARE @nStart INT
	DECLARE @nEnd INT
	DECLARE @nLength INT
	DECLARE @nCounter int
	SET @nCounter=1
	SET @sHTMLTagsToRemove = '!--,!DOCTYPE,A,ABBR,ACRONYM,ADDRESS,APPLET,AREA,B,BASE,BASEFONT,BDO,BIG,BLOCKQUOTE,BODY,BR,BUTTON,CAPTION,CENTER,CITE,CODE,COL,COLGROUP,DD,DEL,DFN,DIR,DIV,DL,DT,EM,FIELDSET,FONT,FORM,FRAME,FRAMESET,H1,H2,H3,H4,H5,H6,HEAD,HR,HTML,I,IFRAME,IMG,INPUT,INS,ISINDEX,KBD,LABEL,LEGEND,LI,LINK,MAP,MENU,META,NOFRAMES,NOSCRIPT,OBJECT,OL,OPTGROUP,OPTION,P,PARAM,PRE,Q,S,SAMP,SCRIPT,SELECT,SMALL,SPAN,STRIKE,STRONG,STYLE,SUB,SUP,TABLE,TBODY,TD,TEXTAREA,TFOOT,TH,THEAD,TITLE,TR,TT,U,UL,VAR,STYLE,FONT'

	DECLARE @Records table
	(
		ID int,
		TAG nvarchar(max)		
	);
	insert into @Records(ID,TAG)
	Select InsertOrder,Parameter from dbo.fn_Tokenise(@sHTMLTagsToRemove, ',')

	WHILE (@nCounter <= (SELECT MAX(ID) FROM @Records))
	BEGIN

		SELECT @sCurrentSelectedTag=TAG FROM  @Records WHERE ID = @nCounter;

		set @sTagtoRemove='<'+@sCurrentSelectedTag+'>'
		set @nLength=len(@sTagtoRemove)
		WHILE (charindex(@sTagtoRemove,@psText)> 0)
		BEGIN
			SET @nStart = CHARINDEX(@sTagtoRemove,@psText)			
			If(@nStart > 0 AND @nLength > 0)
				SET @psText = STUFF(@psText,@nStart,@nLength,'')
		END
				
		set @sTagtoRemove='<'+@sCurrentSelectedTag+' '
		set @nLength=datalength(@sTagtoRemove)
		SET @nStart=0
		SET @nEnd=0
		SET @sSubString=@psText
		WHILE(charindex(@sTagtoRemove,@sSubString)> 0)
		Begin 				
			IF(@nStart=0)
				Begin					
					SET @nStart = CHARINDEX(@sTagtoRemove,@psText)			
					SET @nEnd = CHARINDEX('>',SUBSTRING (@psText, (@nStart), datalength(@psText)))
					SET @nLength = @nEnd
				END
			ELSE
				BEGIN					
						SET @nStart = @nStart+CHARINDEX(@sTagtoRemove,@sSubString)			
						SET @nEnd = CHARINDEX('>',SUBSTRING (@sSubString, CHARINDEX(@sTagtoRemove,@sSubString), datalength(@sSubString)))
						SET @nLength = @nEnd
				END
			
			If(@nStart > 0 AND @nEnd > 0 AND @nLength > 0 and charindex('<',SUBSTRING (@psText, (@nStart+1),@nLength-1))=0)
				Begin
					SET @psText = STUFF(@psText,@nStart,@nLength,'')				
					SET @nStart=0
				End
			ELSE
				BEGIN
				    SET @sSubString=SUBSTRING (@psText,(@nStart+1),datalength(@psText))					
				END		
			
		End

		set @sTagtoRemove='<'+@sCurrentSelectedTag+'/>'
		set @nLength=len(@sTagtoRemove)
		WHILE(charindex(@sTagtoRemove,@psText)> 0)
		Begin
			SET @nStart = CHARINDEX(@sTagtoRemove,@psText)			
			If(@nStart > 0 AND @nLength > 0)
				SET @psText = STUFF(@psText,@nStart,@nLength,'')
		End

		set @sTagtoRemove='</'+@sCurrentSelectedTag+'>'
		set @nLength=len(@sTagtoRemove)
		WHILE(charindex(@sTagtoRemove,@psText)> 0)
		Begin
			SET @nStart = CHARINDEX(@sTagtoRemove,@psText)			
			If(@nStart > 0 AND @nLength > 0)
				SET @psText = STUFF(@psText,@nStart,@nLength,'')
		End
		
		SET @nCounter = (@nCounter + 1);
	END    
    
	SET @sCrLf = CHAR(13) + CHAR(10)

	SELECT @sResult = @psText
	SELECT @nPos = PATINDEX('%&#___;%', @sResult)
	WHILE (@nPos > 0)
	BEGIN
		SELECT @sEncoded = SUBSTRING(@sResult, @nPos, 6)
		SELECT @nChar = CAST(SUBSTRING(@sEncoded, 3, 3) AS SMALLINT)
		SELECT @sResult = REPLACE(@sResult, @sEncoded, NCHAR(@nChar))
		SELECT @nPos = PATINDEX('%&#___;%', @sResult)
	END

	SELECT @nPos = PATINDEX('%&#____;%', @sResult)
	WHILE (@nPos > 0)
	BEGIN
		SELECT @sEncoded = SUBSTRING(@sResult, @nPos, 7)
		SELECT @nChar = CAST(SUBSTRING(@sEncoded, 3, 4) AS SMALLINT)
		SELECT @sResult = REPLACE(@sResult, @sEncoded, NCHAR(@nChar))
		SELECT @nPos = PATINDEX('%&#____;%', @sResult)
	END

	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&quot;', NCHAR(0x0022))	
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lt;', NCHAR(0x003c))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&gt;', NCHAR(0x003e))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&nbsp;', NCHAR(0x00a0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&iexcl;', NCHAR(0x00a1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&cent;', NCHAR(0x00a2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&pound;', NCHAR(0x00a3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&curren;', NCHAR(0x00a4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&yen;', NCHAR(0x00a5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&brvbar;', NCHAR(0x00a6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sect;', NCHAR(0x00a7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&uml;', NCHAR(0x00a8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&copy;', NCHAR(0x00a9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ordf;', NCHAR(0x00aa))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&laquo;', NCHAR(0x00ab))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&not;', NCHAR(0x00ac))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&shy;', NCHAR(0x00ad))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&reg;', NCHAR(0x00ae))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&macr;', NCHAR(0x00af))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&deg;', NCHAR(0x00b0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&plusmn;', NCHAR(0x00b1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sup2;', NCHAR(0x00b2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sup3;', NCHAR(0x00b3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&acute;', NCHAR(0x00b4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&micro;', NCHAR(0x00b5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&para;', NCHAR(0x00b6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&middot;', NCHAR(0x00b7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&cedil;', NCHAR(0x00b8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sup1;', NCHAR(0x00b9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ordm;', NCHAR(0x00ba))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&raquo;', NCHAR(0x00bb))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&frac14;', NCHAR(0x00bc))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&frac12;', NCHAR(0x00bd))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&frac34;', NCHAR(0x00be))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&iquest;', NCHAR(0x00bf))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Agrave;', NCHAR(0x00c0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Aacute;', NCHAR(0x00c1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Acirc;', NCHAR(0x00c2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Atilde;', NCHAR(0x00c3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Auml;', NCHAR(0x00c4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Aring;', NCHAR(0x00c5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&AElig;', NCHAR(0x00c6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ccedil;', NCHAR(0x00c7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Egrave;', NCHAR(0x00c8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Eacute;', NCHAR(0x00c9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ecirc;', NCHAR(0x00ca))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Euml;', NCHAR(0x00cb))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Igrave;', NCHAR(0x00cc))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Iacute;', NCHAR(0x00cd))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Icirc;', NCHAR(0x00ce ))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Iuml;', NCHAR(0x00cf))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ETH;', NCHAR(0x00d0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ntilde;', NCHAR(0x00d1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ograve;', NCHAR(0x00d2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Oacute;', NCHAR(0x00d3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ocirc;', NCHAR(0x00d4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Otilde;', NCHAR(0x00d5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ouml;', NCHAR(0x00d6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&times;', NCHAR(0x00d7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Oslash;', NCHAR(0x00d8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ugrave;', NCHAR(0x00d9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Uacute;', NCHAR(0x00da))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Ucirc;', NCHAR(0x00db))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Uuml;', NCHAR(0x00dc))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Yacute;', NCHAR(0x00dd))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&THORN;', NCHAR(0x00de))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&szlig;', NCHAR(0x00df))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&agrave;', NCHAR(0x00e0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&aacute;', NCHAR(0x00e1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&acirc;', NCHAR(0x00e2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&atilde;', NCHAR(0x00e3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&auml;', NCHAR(0x00e4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&aring;', NCHAR(0x00e5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&aelig;', NCHAR(0x00e6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ccedil;', NCHAR(0x00e7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&egrave;', NCHAR(0x00e8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&eacute;', NCHAR(0x00e9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ecirc;', NCHAR(0x00ea))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&euml;', NCHAR(0x00eb))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&igrave;', NCHAR(0x00ec))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&iacute;', NCHAR(0x00ed))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&icirc;', NCHAR(0x00ee))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&iuml;', NCHAR(0x00ef))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&eth;', NCHAR(0x00f0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ntilde;', NCHAR(0x00f1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ograve;', NCHAR(0x00f2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&oacute;', NCHAR(0x00f3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ocirc;', NCHAR(0x00f4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&otilde;', NCHAR(0x00f5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ouml;', NCHAR(0x00f6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&divide;', NCHAR(0x00f7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&oslash;', NCHAR(0x00f8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ugrave;', NCHAR(0x00f9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&uacute;', NCHAR(0x00fa))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ucirc;', NCHAR(0x00fb))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&uuml;', NCHAR(0x00fc))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&yacute;', NCHAR(0x00fd))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&thorn;', NCHAR(0x00fe))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&yuml;', NCHAR(0x00ff))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&OElig;', NCHAR(0x0152))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&oelig;', NCHAR(0x0153))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Scaron;', NCHAR(0x0160))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&scaron;', NCHAR(0x0161))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Yuml;', NCHAR(0x0178))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&fnof;', NCHAR(0x0192))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&circ;', NCHAR(0x02c6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&tilde;', NCHAR(0x02dc))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Alpha;', NCHAR(0x0391))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Beta;', NCHAR(0x0392))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Gamma;', NCHAR(0x0393))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Delta;', NCHAR(0x0394))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Epsilon;', NCHAR(0x0395))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Zeta;', NCHAR(0x0396))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Eta;', NCHAR(0x0397))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Theta;', NCHAR(0x0398))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Iota;', NCHAR(0x0399))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Kappa;', NCHAR(0x039a))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Lambda;', NCHAR(0x039b))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Mu;', NCHAR(0x039c))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Nu;', NCHAR(0x039d))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Xi;', NCHAR(0x039e))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Omicron;', NCHAR(0x039f))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Pi;', NCHAR(0x03a0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '& Rho ;', NCHAR(0x03a1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Sigma;', NCHAR(0x03a3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Tau;', NCHAR(0x03a4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Upsilon;', NCHAR(0x03a5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Phi;', NCHAR(0x03a6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Chi;', NCHAR(0x03a7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Psi;', NCHAR(0x03a8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Omega;', NCHAR(0x03a9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&alpha;', NCHAR(0x03b1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&beta;', NCHAR(0x03b2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&gamma;', NCHAR(0x03b3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&delta;', NCHAR(0x03b4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&epsilon;', NCHAR(0x03b5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&zeta;', NCHAR(0x03b6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&eta;', NCHAR(0x03b7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&theta;', NCHAR(0x03b8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&iota;', NCHAR(0x03b9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&kappa;', NCHAR(0x03ba))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lambda;', NCHAR(0x03bb))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&mu;', NCHAR(0x03bc))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&nu;', NCHAR(0x03bd))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&xi;', NCHAR(0x03be))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&omicron;', NCHAR(0x03bf))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&pi;', NCHAR(0x03c0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rho;', NCHAR(0x03c1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sigmaf;', NCHAR(0x03c2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sigma;', NCHAR(0x03c3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&tau;', NCHAR(0x03c4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&upsilon;', NCHAR(0x03c5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&phi;', NCHAR(0x03c6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&chi;', NCHAR(0x03c7))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&psi;', NCHAR(0x03c8))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&omega;', NCHAR(0x03c9))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&thetasym;', NCHAR(0x03d1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&upsih;', NCHAR(0x03d2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&piv;', NCHAR(0x03d6))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ensp;', NCHAR(0x2002))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&emsp;', NCHAR(0x2003))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&thinsp;', NCHAR(0x2009))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&zwnj;', NCHAR(0x200c))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&zwj;', NCHAR(0x200d))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lrm;', NCHAR(0x200e))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rlm;', NCHAR(0x200f))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ndash;', NCHAR(0x2013))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&mdash;', NCHAR(0x2014))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lsquo;', NCHAR(0x2018))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rsquo;', NCHAR(0x2019))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sbquo;', NCHAR(0x201a))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ldquo;', NCHAR(0x201c))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rdquo;', NCHAR(0x201d))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&bdquo;', NCHAR(0x201e))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&dagger;', NCHAR(0x2020))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Dagger;', NCHAR(0x2021))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&bull;', NCHAR(0x2022))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&hellip;', NCHAR(0x2026))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&permil;', NCHAR(0x2030))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&prime;', NCHAR(0x2032))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&Prime;', NCHAR(0x2033))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lsaquo;', NCHAR(0x2039))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rsaquo;', NCHAR(0x203a))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&oline;', NCHAR(0x203e))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&frasl;', NCHAR(0x2044))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&euro;', NCHAR(0x20ac))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&image;', NCHAR(0x2111))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&weierp;', NCHAR(0x2118))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&real;', NCHAR(0x211c))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&trade;', NCHAR(0x2122))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&alefsym;', NCHAR(0x2135))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&larr;', NCHAR(0x2190))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&uarr;', NCHAR(0x2191))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rarr;', NCHAR(0x2192))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&darr;', NCHAR(0x2193))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&harr;', NCHAR(0x2194))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&crarr;', NCHAR(0x21b5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lArr;', NCHAR(0x21d0))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&uArr;', NCHAR(0x21d1))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rArr;', NCHAR(0x21d2))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&dArr;', NCHAR(0x21d3))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&hArr;', NCHAR(0x21d4))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&forall;', NCHAR(0x2200))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&part;', NCHAR(0x2202))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&exist;', NCHAR(0x2203))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&empty;', NCHAR(0x2205))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&nabla;', NCHAR(0x2207))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&isin;', NCHAR(0x2208))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&notin;', NCHAR(0x2209))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ni;', NCHAR(0x220b))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&prod;', NCHAR(0x220f))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sum;', NCHAR(0x2211))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&minus;', NCHAR(0x2212))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lowast;', NCHAR(0x2217))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&radic;', NCHAR(0x221a))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&prop;', NCHAR(0x221d))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&infin;', NCHAR(0x221e))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ang;', NCHAR(0x2220))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&and;', NCHAR(0x2227))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&or;', NCHAR(0x2228))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&cap;', NCHAR(0x2229))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&cup;', NCHAR(0x222a))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&int;', NCHAR(0x222b))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&there4;', NCHAR(0x2234))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sim;', NCHAR(0x223c))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&cong;', NCHAR(0x2245))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&asymp;', NCHAR(0x2248))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ne;', NCHAR(0x2260))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&equiv;', NCHAR(0x2261))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&le;', NCHAR(0x2264))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&ge;', NCHAR(0x2265))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sub;', NCHAR(0x2282))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sup;', NCHAR(0x2283))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&nsub;', NCHAR(0x2284))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sube;', NCHAR(0x2286))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&supe;', NCHAR(0x2287))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&oplus;', NCHAR(0x2295))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&otimes;', NCHAR(0x2297))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&perp;', NCHAR(0x22a5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&sdot;', NCHAR(0x22c5))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lceil;', NCHAR(0x2308))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rceil;', NCHAR(0x2309))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lfloor;', NCHAR(0x230a))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rfloor;', NCHAR(0x230b))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&lang;', NCHAR(0x2329))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&rang;', NCHAR(0x232a))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&loz;', NCHAR(0x25ca))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&spades;', NCHAR(0x2660))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&clubs;', NCHAR(0x2663))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&hearts;', NCHAR(0x2665))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&diams;', NCHAR(0x2666))
	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CS_AS, '&amp;', NCHAR(0x0026))

	SELECT @sResult = REPLACE(@sResult COLLATE Latin1_General_CI_AS, '<p>', @sCrLf)			-- 3a

	RETURN @sResult
END
go 

grant execute on dbo.fn_StripHTML to public
GO