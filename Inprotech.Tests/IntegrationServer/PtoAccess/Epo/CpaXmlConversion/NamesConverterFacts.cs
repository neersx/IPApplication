using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class NamesConverterFacts
    {
        readonly NamesConverter _subject = new NamesConverter();
        readonly CaseDetails _caseDetails = new CaseDetails("Patent", "EP");
        WorldPatentFixture _fixture;

        [Fact]
        public void ReturnsApplicant()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Applicants).WithApplicantDetails("2014/42", "Applicant Name1", "all", "1").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var nameCreated = _caseDetails.NameDetails.Single();

            Assert.Equal("Applicant", nameCreated.NameTypeCode);
            Assert.Equal(1, nameCreated.NameSequenceNumber);
            Assert.Equal("Applicant Name1", nameCreated.AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsApplicantBasedOnGazetteNum()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Applicants)
                                          .WithApplicantDetails(null, "Applicant Name1", "all", "4")
                                          .Build())
                             .WithParties(new NamesBuilder(ElementNames.Applicants)
                                          .WithApplicantDetails("2014/42", "New Applicant Name1", null, "8")
                                          .Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var namesCreated = _caseDetails.NameDetails.OrderBy(_ => _.NameSequenceNumber).ToArray();
            Assert.Single(namesCreated);

            Assert.Equal("Applicant", namesCreated[0].NameTypeCode);
            Assert.Equal(8, namesCreated[0].NameSequenceNumber);
            Assert.Equal("New Applicant Name1", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsApplicants()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Applicants)
                                          .WithApplicantDetails("2014/42", "Applicant Name1", "all", "8")
                                          .WithApplicantDetails(null, "Applicant Name2", "all", "2")
                                          .WithApplicantDetails(null, "Applicant Name3", "all", "1")
                                          .Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var namesCreated = _caseDetails.NameDetails.OrderBy(_ => _.NameSequenceNumber).ToArray();
            Assert.Equal(3, namesCreated.Length);

            Assert.Equal("Applicant", namesCreated[0].NameTypeCode);
            Assert.Equal(1, namesCreated[0].NameSequenceNumber);
            Assert.Equal("Applicant Name3", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Applicant", namesCreated[1].NameTypeCode);
            Assert.Equal(2, namesCreated[1].NameSequenceNumber);
            Assert.Equal("Applicant Name2", namesCreated[1].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Applicant", namesCreated[2].NameTypeCode);
            Assert.Equal(8, namesCreated[2].NameSequenceNumber);
            Assert.Equal("Applicant Name1", namesCreated[2].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsApplicantsBasedOnGazetteNum()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Applicants)
                                          .WithApplicantDetails("2012/1", "Applicant Name1", "all", "8")
                                          .WithApplicantDetails(null, "Applicant Name2", "all", "2")
                                          .WithApplicantDetails(null, "Applicant Name3", "all", "1")
                                          .Build())
                             .WithParties(new NamesBuilder(ElementNames.Applicants)
                                          .WithApplicantDetails("2014/42", "New Applicant Name1", "all", "8")
                                          .WithApplicantDetails(null, "New Applicant Name2", "all", "2")
                                          .WithApplicantDetails(null, "New Applicant Name3", "all", "1")
                                          .Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var namesCreated = _caseDetails.NameDetails.OrderBy(_ => _.NameSequenceNumber).ToArray();
            Assert.Equal(3, namesCreated.Length);

            Assert.Equal("Applicant", namesCreated[0].NameTypeCode);
            Assert.Equal(1, namesCreated[0].NameSequenceNumber);
            Assert.Equal("New Applicant Name3", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Applicant", namesCreated[1].NameTypeCode);
            Assert.Equal(2, namesCreated[1].NameSequenceNumber);
            Assert.Equal("New Applicant Name2", namesCreated[1].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Applicant", namesCreated[2].NameTypeCode);
            Assert.Equal(8, namesCreated[2].NameSequenceNumber);
            Assert.Equal("New Applicant Name1", namesCreated[2].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsApplicantsNInventorBasedOnGazetteNum()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Inventors)
                                          .WithInventorDetails("2014/42", "Inventor Name1", "4")
                                          .Build())
                             .WithParties(new NamesBuilder(ElementNames.Inventors)
                                          .WithInventorDetails("2011/01", "New Inventor Name1", "8")
                                          .Build())
                             .WithParties(new NamesBuilder(ElementNames.Applicants)
                                          .WithApplicantDetails(null, "Applicant Name1", null, "4")
                                          .Build())
                             .WithParties(new NamesBuilder(ElementNames.Applicants)
                                          .WithApplicantDetails("2014/42", "New Applicant Name1", null, "8")
                                          .Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var namesCreated = _caseDetails.NameDetails.Where(_ => _.NameTypeCode == "Inventor").ToArray();
            Assert.Single(namesCreated);

            Assert.Equal(4, namesCreated[0].NameSequenceNumber);
            Assert.Equal("Inventor Name1", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            namesCreated = _caseDetails.NameDetails.Where(_ => _.NameTypeCode == "Applicant").ToArray();
            Assert.Single(namesCreated);

            Assert.Equal(8, namesCreated[0].NameSequenceNumber);
            Assert.Equal("New Applicant Name1", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsApplicantWithAddress()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Applicants).WithApplicantDetails("2014/42", "Applicant Name1", "all", "1", true, "DE").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var nameCreated = _caseDetails.NameDetails.Single();

            Assert.Equal("Applicant", nameCreated.NameTypeCode);
            Assert.Equal(1, nameCreated.NameSequenceNumber);
            Assert.Equal("Applicant Name1", nameCreated.AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
            Assert.Equal("Address line 1", nameCreated.AddressBook.FormattedNameAddress.Address.FormattedAddress.AddressLine.First());
            Assert.Equal("Address line 2", nameCreated.AddressBook.FormattedNameAddress.Address.FormattedAddress.AddressLine[1]);
            Assert.Equal("DE", nameCreated.AddressBook.FormattedNameAddress.Address.FormattedAddress.AddressCountryCode);
        }

        [Fact]
        public void ReturnsInventor()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Inventors).WithInventorDetails("2014/42", "Inventor Name1", "1").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var nameCreated = _caseDetails.NameDetails.Single();

            Assert.Equal("Inventor", nameCreated.NameTypeCode);
            Assert.Equal(1, nameCreated.NameSequenceNumber);
            Assert.Equal("Inventor Name1", nameCreated.AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsInventorBasedOnGazetteNum()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Inventors)
                                          .WithInventorDetails(null, "Inventor Name1", "4")
                                          .Build())
                             .WithParties(new NamesBuilder(ElementNames.Inventors)
                                          .WithInventorDetails("2014/42", "New Inventor Name1", "8")
                                          .Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var namesCreated = _caseDetails.NameDetails.OrderBy(_ => _.NameSequenceNumber).ToArray();
            Assert.Single(namesCreated);

            Assert.Equal("Inventor", namesCreated[0].NameTypeCode);
            Assert.Equal(8, namesCreated[0].NameSequenceNumber);
            Assert.Equal("New Inventor Name1", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsInventors()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Inventors)
                                          .WithInventorDetails("2014/42", "Inventor Name1", "8")
                                          .WithInventorDetails(null, "Inventor Name2", "2")
                                          .WithInventorDetails(null, "Inventor Name3", "1")
                                          .Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var namesCreated = _caseDetails.NameDetails.OrderBy(_ => _.NameSequenceNumber).ToArray();
            Assert.Equal(3, namesCreated.Length);

            Assert.Equal("Inventor", namesCreated[0].NameTypeCode);
            Assert.Equal(1, namesCreated[0].NameSequenceNumber);
            Assert.Equal("Inventor Name3", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Inventor", namesCreated[1].NameTypeCode);
            Assert.Equal(2, namesCreated[1].NameSequenceNumber);
            Assert.Equal("Inventor Name2", namesCreated[1].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Inventor", namesCreated[2].NameTypeCode);
            Assert.Equal(8, namesCreated[2].NameSequenceNumber);
            Assert.Equal("Inventor Name1", namesCreated[2].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsInventorsBasedOnGazetteNum()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Inventors)
                                          .WithInventorDetails("2012/1", "Inventor Name1", "8")
                                          .WithInventorDetails(null, "Inventor Name2", "2")
                                          .WithInventorDetails(null, "Inventor Name3", "1")
                                          .Build())
                             .WithParties(new NamesBuilder(ElementNames.Inventors)
                                          .WithInventorDetails("2014/42", "New Inventor Name1", "8")
                                          .WithInventorDetails(null, "New Inventor Name2", "2")
                                          .WithInventorDetails(null, "New Inventor Name3", "1")
                                          .Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var namesCreated = _caseDetails.NameDetails.OrderBy(_ => _.NameSequenceNumber).ToArray();
            Assert.Equal(3, namesCreated.Length);

            Assert.Equal("Inventor", namesCreated[0].NameTypeCode);
            Assert.Equal(1, namesCreated[0].NameSequenceNumber);
            Assert.Equal("New Inventor Name3", namesCreated[0].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Inventor", namesCreated[1].NameTypeCode);
            Assert.Equal(2, namesCreated[1].NameSequenceNumber);
            Assert.Equal("New Inventor Name2", namesCreated[1].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Inventor", namesCreated[2].NameTypeCode);
            Assert.Equal(8, namesCreated[2].NameSequenceNumber);
            Assert.Equal("New Inventor Name1", namesCreated[2].AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());
        }

        [Fact]
        public void ReturnsInventorWithAddress()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(new NamesBuilder(ElementNames.Inventors).WithInventorDetails("2014/42", "Inventor Name1", "1", true, "AU").Build())
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            var nameCreated = _caseDetails.NameDetails.Single();

            Assert.Equal("Inventor", nameCreated.NameTypeCode);
            Assert.Equal(1, nameCreated.NameSequenceNumber);
            Assert.Equal("Inventor Name1", nameCreated.AddressBook.FormattedNameAddress.Name.FreeFormatName.FreeFormatNameDetails.FreeFormatNameLine.First());

            Assert.Equal("Address line 1", nameCreated.AddressBook.FormattedNameAddress.Address.FormattedAddress.AddressLine.First());
            Assert.Equal("Address line 2", nameCreated.AddressBook.FormattedNameAddress.Address.FormattedAddress.AddressLine[1]);
            Assert.Equal("AU", nameCreated.AddressBook.FormattedNameAddress.Address.FormattedAddress.AddressCountryCode);
        }

        [Fact]
        public void WithNoNames()
        {
            var biblioData = new BiblioDataBuilder()
                             .WithBasicDefaultdata()
                             .WithParties(null)
                             .Build();

            var docBuilder = new XDocBuilder()
                             .WithChildElement(biblioData)
                             .Build();
            _fixture = new WorldPatentFixture().With(docBuilder);

            _subject.Convert(_fixture.Bibliographicdata, _caseDetails);

            Assert.Empty(_caseDetails.NameDetails);
        }
    }
}