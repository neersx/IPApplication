using System.Linq;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion;
using Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion.Builders;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.CpaXmlConversion
{
    public class EventsConverterFacts
    {
        readonly CaseDetails _caseDetails = new CaseDetails("Trademark", "US");
        readonly EventsConverter _subject = new EventsConverter();
        TsdrSourceFixture _fixture;

        [Fact]
        public void ReturnsAsManyEvents()
        {
            var source =
                new MarkEventBagBuilder()
                    .WithMarkEvent("A", "AAA", Fixture.PastDate())
                    .WithMarkEvent("B", "BBB", Fixture.Today())
                    .WithMarkEvent("C", "CCC", Fixture.PastDate())
                    .Build()
                    .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            Assert.Equal(3, _caseDetails.EventDetails.Count);

            Assert.Equal(new[] {"A", "B", "C"}, _caseDetails.EventDetails.Select(_ => _.EventCode));
            Assert.Equal(new[] {"AAA", "BBB", "CCC"}, _caseDetails.EventDetails.Select(_ => _.EventDescription));
        }

        [Fact]
        public void ReturnsEventDetails()
        {
            var source =
                new MarkEventBagBuilder()
                    .WithMarkEvent("PRA7O", "REVIEW OF CORRESPONDENCE COMPLETE - INFORMATION MADE OF RECORD", Fixture.PastDate(), "National prosecution history entry")
                    .Build()
                    .AsTsdrSource();

            _fixture = new TsdrSourceFixture().With(source);
            _subject.Convert(_fixture.Trademark, _fixture.Resolver, _caseDetails);

            var @event = _caseDetails.EventDetails.Single();

            Assert.Equal("National prosecution history entry", @event.EventText);
            Assert.Equal("PRA7O", @event.EventCode);
            Assert.Equal(Fixture.PastDate().ToString("yyyy-MM-dd"), @event.EventDate);
            Assert.Equal("REVIEW OF CORRESPONDENCE COMPLETE - INFORMATION MADE OF RECORD", @event.EventDescription);
        }
    }
}