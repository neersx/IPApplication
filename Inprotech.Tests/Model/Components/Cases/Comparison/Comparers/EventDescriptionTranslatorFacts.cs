using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Translations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Comparers
{
    public class EventDescriptionTranslatorFacts : FactBase
    {
        readonly IPreferredCultureResolver _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

        [Fact]
        public void ReturnTranslationsForBaseEvents()
        {
            var @event = new EventBuilder().Build().In(Db);

            var interimEventComparisonResult = new Event
            {
                EventNo = @event.Id
            };

            var subject = new EventDescriptionTranslator(Db, _preferredCultureResolver);

            var result = subject.Translate(new[]
            {
                interimEventComparisonResult
            });

            Assert.Equal(@event.Description, result.Single().EventType);
        }

        [Fact]
        public void ReturnTranslationsForEventControls()
        {
            var @event = new EventBuilder().Build().In(Db);

            var eventControl = new ValidEventBuilder
                {
                    Event = @event,
                    Description = Fixture.String()
                }.Build()
                 .In(Db);

            var interimEventComparisonResult = new Event
            {
                EventNo = eventControl.EventId,
                CriteriaId = eventControl.CriteriaId
            };

            var subject = new EventDescriptionTranslator(Db, _preferredCultureResolver);

            var result = subject.Translate(new[]
            {
                interimEventComparisonResult
            });

            Assert.Equal(eventControl.Description, result.Single().EventType);
        }
    }
}