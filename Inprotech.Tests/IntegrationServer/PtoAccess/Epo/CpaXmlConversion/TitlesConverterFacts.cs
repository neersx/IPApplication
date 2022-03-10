using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class TitlesConverterFacts
    {
        readonly TitlesConverter _subject = new TitlesConverter();
        readonly CaseDetails _caseDetails = new CaseDetails("Patent", "EP");
        WorldPatentFixture _fixture;

        [Fact]
        public void WithDefaultEnglish()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "en", "TitleEN").Build())
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "de", "TitleDE").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .WithProceduralData(new ProceduralDataBuilder().WithProceedingLang("fr").Build())
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.WorldPatentData, _fixture.Bibliographicdata, _caseDetails);

            var title = _caseDetails.DescriptionDetails.SingleOrDefault();

            Assert.NotNull(title);

            Assert.Equal("en", title.DescriptionText[0].LanguageCode);
            Assert.Equal("TitleEN", title.DescriptionText[0].Value);
        }

        [Fact]
        public void WithDefaultFirstLang()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "de", "TitleDE").Build())
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "sn", "TitleSN").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .WithProceduralData(new ProceduralDataBuilder().WithProceedingLang("fr").Build())
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.WorldPatentData, _fixture.Bibliographicdata, _caseDetails);

            var title = _caseDetails.DescriptionDetails.SingleOrDefault();

            Assert.NotNull(title);

            Assert.Equal("de", title.DescriptionText[0].LanguageCode);
            Assert.Equal("TitleDE", title.DescriptionText[0].Value);
        }

        [Fact]
        public void WithDefaultSingleLang()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "de", "TitleDE").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .WithProceduralData(new ProceduralDataBuilder().WithProceedingLang("fr").Build())
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.WorldPatentData, _fixture.Bibliographicdata, _caseDetails);

            var title = _caseDetails.DescriptionDetails.SingleOrDefault();

            Assert.NotNull(title);

            Assert.Equal("de", title.DescriptionText[0].LanguageCode);
            Assert.Equal("TitleDE", title.DescriptionText[0].Value);
        }

        [Fact]
        public void WithNoTitle()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .WithProceduralData(new ProceduralDataBuilder().WithStepDetails("ANY").Build())
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.WorldPatentData, _fixture.Bibliographicdata, _caseDetails);

            Assert.Empty(_caseDetails.DescriptionDetails);
        }

        [Fact]
        public void WithOutProceedingLang()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "de", "TitleDE").Build())
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "sn", "TitleSN").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .WithProceduralData(new ProceduralDataBuilder().WithStepDetails("ANY").Build())
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.WorldPatentData, _fixture.Bibliographicdata, _caseDetails);

            Assert.Empty(_caseDetails.DescriptionDetails);
        }

        [Fact]
        public void WithProceedingLangTitle()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "en", "TitleEN").Build())
                             .WithChildElement(new TitlesBuilder().WithDetails("2014/32", "de", "TitleDE").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .WithProceduralData(new ProceduralDataBuilder().WithProceedingLang("de").Build())
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.WorldPatentData, _fixture.Bibliographicdata, _caseDetails);

            var title = _caseDetails.DescriptionDetails.SingleOrDefault();

            Assert.NotNull(title);

            Assert.Equal("de", title.DescriptionText[0].LanguageCode);
            Assert.Equal("TitleDE", title.DescriptionText[0].Value);
        }
    }
}