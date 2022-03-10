using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public class CriticalDatesConverterFacts
    {
        readonly CaseDetails _caseDetails = new CaseDetails("Trademark", "US");
        readonly CriticalDatesConverter _subject = new CriticalDatesConverter();
        TsdrSourceFixture _fixture;

        [Fact]
        public void ReturnsAbandonDate()
        {
            var source = new TrademarkBuilder
                         {
                             AbandonDate = Fixture.PastDate()
                         }
                         .Build()
                         .InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal(Fixture.PastDate().ToString("yyyy-MM-dd"),
                         _caseDetails.EventDetails.Single(_ => _.EventCode == "Abandon")
                                     .EventDate);
        }

        [Fact]
        public void ReturnsApplicationDate()
        {
            var source = new TrademarkBuilder
                         {
                             ApplicationDate = Fixture.PastDate()
                         }
                         .Build()
                         .InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal(Fixture.PastDate().ToString("yyyy-MM-dd"),
                         _caseDetails.EventDetails.Single(_ => _.EventCode == "Application")
                                     .EventDate);
        }

        [Fact]
        public void ReturnsApplicationNumber()
        {
            var source = new TrademarkBuilder
                         {
                             ApplicationNumber = "123456"
                         }
                         .Build()
                         .InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("123456",
                         _caseDetails.IdentifierNumberDetails.Single(_ => _.IdentifierNumberCode == "Application")
                                     .IdentifierNumberText);
        }

        [Fact]
        public void ReturnsPublicationDate()
        {
            var source = new TrademarkBuilder
                         {
                             PublicationDate = Fixture.PastDate()
                         }
                         .Build()
                         .InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal(Fixture.PastDate().ToString("yyyy-MM-dd"),
                         _caseDetails.EventDetails.Single(_ => _.EventCode == "Publication")
                                     .EventDate);
        }

        [Fact]
        public void ReturnsRegistrationDate()
        {
            var source = new TrademarkBuilder
                         {
                             RegistrationDate = Fixture.PastDate()
                         }
                         .Build()
                         .InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal(Fixture.PastDate().ToString("yyyy-MM-dd"),
                         _caseDetails.EventDetails.Single(_ => _.EventCode == "Registration/Grant")
                                     .EventDate);
        }

        [Fact]
        public void ReturnsRegistrationNumber()
        {
            var source = new TrademarkBuilder
                         {
                             RegistrationNumber = "123456"
                         }
                         .Build()
                         .InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("123456",
                         _caseDetails.IdentifierNumberDetails.Single(_ => _.IdentifierNumberCode == "Registration/Grant")
                                     .IdentifierNumberText);
        }
    }
}