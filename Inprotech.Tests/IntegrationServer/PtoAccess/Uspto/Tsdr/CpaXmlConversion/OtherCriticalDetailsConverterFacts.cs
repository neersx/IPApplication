using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public class OtherCriticalDetailsConverterFacts
    {
        readonly OtherCriticalDetailsConverter _subject = new OtherCriticalDetailsConverter();
        readonly CaseDetails _caseDetails = new CaseDetails("Trademark", "US");
        TsdrSourceFixture _fixture;

        [Fact]
        public void ReturnsDisclaimer()
        {
            var source =
                new TrademarkBuilder
                {
                    DisclaimerText = "THE REPRESENTATION OF THE CHRISTIAN FISH SYMBOL"
                }.Build().InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("THE REPRESENTATION OF THE CHRISTIAN FISH SYMBOL",
                         _caseDetails.DescriptionDetails.Single(_ => _.DescriptionCode == "Disclaimer")
                                     .DescriptionText.Single()
                                     .Value);
        }

        [Fact]
        public void ReturnsMarkDescription()
        {
            var source =
                new TrademarkBuilder
                {
                    MarkDescription = "The mark consists of the letters &quot;FISHFLIX&quot; in stylized form with a fish outline located at the top of the letters."
                }.Build().InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("The mark consists of the letters &quot;FISHFLIX&quot; in stylized form with a fish outline located at the top of the letters.",
                         _caseDetails.DescriptionDetails.Single(_ => _.DescriptionCode == "Mark Description")
                                     .DescriptionText.Single()
                                     .Value);
        }

        [Fact]
        public void ReturnsShortTitle()
        {
            var source =
                new TrademarkBuilder
                {
                    MarkVerbalElement = "FISHFLIX"
                }.Build().InTrademarkBag();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("FISHFLIX",
                         _caseDetails.DescriptionDetails.Single(_ => _.DescriptionCode == "Short Title")
                                     .DescriptionText.Single()
                                     .Value);
        }

        [Fact]
        public void ReturnsStatusCode()
        {
            _fixture = new TsdrSourceFixture().With(new TrademarkBuilder
            {
                StatusCode = "1234",
                StatusDescription = string.Empty
            }.Build().InTrademarkBag());

            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("1234", _caseDetails.CaseStatus);
        }

        [Fact]
        public void ReturnsStatusCodeAndDescription()
        {
            _fixture = new TsdrSourceFixture().With(new TrademarkBuilder
            {
                StatusCode = "1234",
                StatusDescription = "abcd"
            }.Build().InTrademarkBag());

            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("1234 - abcd", _caseDetails.CaseStatus);
        }

        [Fact]
        public void ReturnsStatusDate()
        {
            _fixture = new TsdrSourceFixture().With(new TrademarkBuilder
            {
                StatusCode = "a",
                StatusDescription = "b",
                StatusDate = Fixture.Today()
            }.Build().InTrademarkBag());

            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal(Fixture.Today().ToString("yyyy-MM-dd"),
                         _caseDetails.EventDetails.Single(_ => _.EventCode == "Status").EventDate);
        }

        [Fact]
        public void ReturnsStatusDescription()
        {
            _fixture = new TsdrSourceFixture().With(new TrademarkBuilder
            {
                StatusCode = string.Empty,
                StatusDescription = "abcd"
            }.Build().InTrademarkBag());
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal("abcd", _caseDetails.CaseStatus);
        }
    }
}