using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class OfficialNumbersConverterFacts
    {
        readonly OfficialNumbersConverter _subject = new OfficialNumbersConverter();
        readonly CaseDetails _caseDetails = new CaseDetails("Patent", "EP");
        WorldPatentFixture _fixture;

        [Fact]
        public void ReturnsApplicationNumber()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2014/42", "EP", "1234", "20120522").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var officialNumberModified = _caseDetails.IdentifierNumberDetails.Single();
            var officialNumberDate = _caseDetails.EventDetails.Single();

            Assert.Equal("EP1234", officialNumberModified.IdentifierNumberText);
            Assert.Equal("Application", officialNumberModified.IdentifierNumberCode);
            Assert.Equal("2012-05-22", officialNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsApplicationNumberWhenMultipleDiffCountryDataPresent()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2011/42", "EP", "1234", "20120522").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2014/12", "US", "9999", "20140610").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2012/12", "EP", "8888", "20140311").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var officialNumberModified = _caseDetails.IdentifierNumberDetails.Single();
            var officialNumberDate = _caseDetails.EventDetails.Single();

            Assert.Equal("EP8888", officialNumberModified.IdentifierNumberText);
            Assert.Equal("Application", officialNumberModified.IdentifierNumberCode);
            Assert.Equal("2014-03-11", officialNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsApplicationNumberWhenMultiplePresent()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2011/42", "EP", "1234", "20120522").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2014/12", "EP", "9999", "20140610").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2012/12", "EP", "8888", "20140311").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var officialNumberModified = _caseDetails.IdentifierNumberDetails.Single();
            var officialNumberDate = _caseDetails.EventDetails.Single();

            Assert.Equal("EP9999", officialNumberModified.IdentifierNumberText);
            Assert.Equal("Application", officialNumberModified.IdentifierNumberCode);
            Assert.Equal("2014-06-10", officialNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsOfficailNumbersWhenMultiplePresent()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2011/42", "en", "EP", "1234", "20120522").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2014/12", "en", "US", "9999", "20140610").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2012/12", "en", "EP", "8888", "20140311").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2011/42", "EP", "1234", "20120522").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2014/12", "US", "9999", "20140610").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.ApplicationRef).WithApplicationNumber("2012/12", "EP", "8888", "20140311").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var applicationNumberModified = _caseDetails.IdentifierNumberDetails.Single(_ => _.IdentifierNumberCode == "Application");
            var applicationNumberDate = _caseDetails.EventDetails.Single(_ => _.EventCode == "Application");

            Assert.Equal("EP8888", applicationNumberModified.IdentifierNumberText);
            Assert.Equal("2014-03-11", applicationNumberDate.EventDate);

            var publicationNumberModified = _caseDetails.IdentifierNumberDetails.Single(_ => _.IdentifierNumberCode == "Publication");
            var publicationNumberDate = _caseDetails.EventDetails.Single(_ => _.EventCode == "Publication");

            Assert.Equal("EP8888", publicationNumberModified.IdentifierNumberText);
            Assert.Equal("2014-03-11", publicationNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsPublicationnNumber()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2014/42", "en", "EP", "1234", "20120522").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var officialNumberModified = _caseDetails.IdentifierNumberDetails.Single();
            var officialNumberDate = _caseDetails.EventDetails.Single();

            Assert.Equal("EP1234", officialNumberModified.IdentifierNumberText);
            Assert.Equal("Publication", officialNumberModified.IdentifierNumberCode);
            Assert.Equal("2012-05-22", officialNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsPublicationNumberWhenMultipleDiffCountryDataPresent()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2011/42", "en", "EP", "1234", "20120522").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2014/12", "en", "US", "9999", "20140610").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2012/12", "en", "EP", "8888", "20140311").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var officialNumberModified = _caseDetails.IdentifierNumberDetails.Single();
            var officialNumberDate = _caseDetails.EventDetails.Single();

            Assert.Equal("EP8888", officialNumberModified.IdentifierNumberText);
            Assert.Equal("Publication", officialNumberModified.IdentifierNumberCode);
            Assert.Equal("2014-03-11", officialNumberDate.EventDate);
        }

        [Fact]
        public void ReturnsPublicationNumberWhenMultiplePresent()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2011/42", "en", "EP", "1234", "20120522").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2014/12", "en", "EP", "9999", "20140610").Build())
                             .WithChildElement(new OfficialNumbersBuilder(ElementNames.PublicationRef).WithPublicationNumber("2012/12", "en", "EP", "8888", "20140311").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var officialNumberModified = _caseDetails.IdentifierNumberDetails.Single();
            var officialNumberDate = _caseDetails.EventDetails.Single();

            Assert.Equal("EP9999", officialNumberModified.IdentifierNumberText);
            Assert.Equal("Publication", officialNumberModified.IdentifierNumberCode);
            Assert.Equal("2014-06-10", officialNumberDate.EventDate);
        }

        [Fact]
        public void WithNoOfficalNumbers()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithChildElement(null)
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            Assert.Empty(_caseDetails.IdentifierNumberDetails);
        }
    }
}