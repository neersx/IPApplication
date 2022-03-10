using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public class CaseComparisonEventFacts
    {
        public class ApplyMethod : FactBase
        {
            [Fact]
            public void ReturnsNullWhenSiteControlNotSet()
            {
                var f = new CaseComparisonEventFixture(Db);

                var @case = new CaseBuilder().Build();

                var result = f.Subject.Apply(@case);

                Assert.Null(result);
            }

            [Fact]
            public void ShouldAddNewCycleToCaseComparisonEventIfExisted()
            {
                var f = new CaseComparisonEventFixture(Db);

                var eventDef = EventBuilder.ForCyclicEvent().Build().In(Db);
                f.SiteControlReader.Read<int?>(SiteControls.CaseComparisonEvent).Returns(eventDef.Id);

                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {Cycle = 1, EventNo = eventDef.Id, EventDate = Fixture.PastDate()}.BuildForCase(@case);

                var result = f.Subject.Apply(@case);

                Assert.NotNull(result);

                Assert.Equal(2, result.CaseEvent.Cycle);
                Assert.Equal(eventDef.Id, result.CaseEvent.EventId);
            }

            [Fact]
            public void ShouldAddNewCycleToCaseComparisonEventIfNonExisted()
            {
                var f = new CaseComparisonEventFixture(Db);

                var eventDef = EventBuilder.ForCyclicEvent().Build().In(Db);
                f.SiteControlReader.Read<int?>(SiteControls.CaseComparisonEvent).Returns(eventDef.Id);

                var @case = new CaseBuilder().Build();
                var result = f.Subject.Apply(@case);

                Assert.NotEmpty(@case.CaseEvents);
                Assert.Equal(Fixture.Today(), @case.CaseEvents.Single().EventDate);
                Assert.NotNull(result);
                Assert.Equal(1, @case.CaseEvents.Single().Cycle);
            }

            [Fact]
            public void ShouldAddSingleCycleCaseComparisonEvent()
            {
                var @case = new CaseBuilder().Build();
                var f = new CaseComparisonEventFixture(Db);
                var eventDef = EventBuilder.ForNonCyclicEvent().Build().In(Db);
                f.SiteControlReader.Read<int?>(SiteControls.CaseComparisonEvent).Returns(eventDef.Id);

                var result = f.Subject.Apply(@case);

                Assert.NotEmpty(@case.CaseEvents);
                Assert.Equal(Fixture.Today(), @case.CaseEvents.Single().EventDate);
                Assert.NotNull(result);
            }

            [Fact]
            public void ShouldUpdateMaxedCycleCaseComparisonEvent()
            {
                var f = new CaseComparisonEventFixture(Db);

                var eventDef = EventBuilder.ForCyclicEvent(2).Build().In(Db);
                f.SiteControlReader.Read<int?>(SiteControls.CaseComparisonEvent).Returns(eventDef.Id);

                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {Cycle = 1, EventNo = eventDef.Id, EventDate = Fixture.PastDate()}.BuildForCase(@case);
                new CaseEventBuilder {Cycle = 2, EventNo = eventDef.Id, EventDate = Fixture.PastDate()}.BuildForCase(@case);

                var result = f.Subject.Apply(@case);

                Assert.NotNull(result);
                
                Assert.Equal(2, result.CaseEvent.Cycle);
                Assert.Equal(eventDef.Id, result.CaseEvent.EventId);
            }

            [Fact]
            public void ShouldUpdateSingleCycleCaseComparisonEvent()
            {
                var f = new CaseComparisonEventFixture(Db);

                var eventDef = EventBuilder.ForNonCyclicEvent().Build().In(Db);
                f.SiteControlReader.Read<int?>(SiteControls.CaseComparisonEvent).Returns(eventDef.Id);

                var @case = new CaseBuilder().Build();
                new CaseEventBuilder {Cycle = 1, EventNo = eventDef.Id, EventDate = Fixture.PastDate()}.BuildForCase(@case);

                var result = f.Subject.Apply(@case);

                Assert.Equal(Fixture.Today(), @case.CaseEvents.Single().EventDate);
                Assert.NotNull(result);
            }
        }

        public class CaseComparisonEventFixture : IFixture<CaseComparisonEvent>
        {
            public CaseComparisonEventFixture(IDbContext dbContext)
            {
                SiteControlReader = Substitute.For<ISiteControlReader>();

                Subject = new CaseComparisonEvent(dbContext, SiteControlReader, Fixture.Today);
            }

            public ISiteControlReader SiteControlReader { get; set; }
            public CaseComparisonEvent Subject { get; }
        }
    }
}