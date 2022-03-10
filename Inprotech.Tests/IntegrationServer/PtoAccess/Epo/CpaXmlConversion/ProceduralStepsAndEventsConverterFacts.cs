using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion;
using Inprotech.IntegrationServer.PtoAccess.Epo.OPS;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    public class ProceduralStepsAndEventsConverterFacts
    {
        public ProceduralStepsAndEventsConverterFacts()
        {
            _opsProcedureOrEventsResolver = Substitute.For<IOpsProcedureOrEventsResolver>();
        }

        readonly IOpsProcedureOrEventsResolver _opsProcedureOrEventsResolver;

        [Fact]
        public void EachOpsProcedureOrEventIsAddedToCpaXml()
        {
            var opsProceduresAndEvents = new[]
            {
                new OpsProcedureOrEvent
                {
                    Comments = "A",
                    Date = Fixture.Today(),
                    FormattedDescription = "AAA",
                    Type = "Type A"
                },
                new OpsProcedureOrEvent
                {
                    Comments = "B",
                    Date = Fixture.PastDate(),
                    FormattedDescription = "BBB",
                    Type = "Type B"
                }
            };

            _opsProcedureOrEventsResolver.Resolve(Arg.Any<registerdocument>())
                                         .Returns(opsProceduresAndEvents);

            var caseDetails = new CaseDetails("Patent", "EP");
            var subject = new ProceduralStepsAndEventsConverter(_opsProcedureOrEventsResolver);
            subject.Convert(new registerdocument(), caseDetails);

            Assert.Equal(2, caseDetails.EventDetails.Count);

            var event1 = caseDetails.EventDetails[0];
            var event2 = caseDetails.EventDetails[1];

            Assert.Equal("A", event1.EventText);
            Assert.Equal("AAA", event1.EventDescription);
            Assert.Equal(Fixture.Today().ToString("yyyy-MM-dd"), event1.EventDate);
            Assert.Equal("Type A", event1.EventCode);

            Assert.Equal("B", event2.EventText);
            Assert.Equal("BBB", event2.EventDescription);
            Assert.Equal(Fixture.PastDate().ToString("yyyy-MM-dd"), event2.EventDate);
            Assert.Equal("Type B", event2.EventCode);
        }
    }
}