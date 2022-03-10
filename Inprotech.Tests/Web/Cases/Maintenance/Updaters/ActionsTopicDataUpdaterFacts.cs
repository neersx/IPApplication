using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Cases.Maintenance.Updaters;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance.Updaters
{
    public class ActionsTopicDataUpdaterFacts : FactBase
    {
        [Fact]
        public void ShouldSaveEventDateAndIsOccuredFlagForEachRow()
        {
            var fixture = new ActionsTopicValidatorFixture(Db);
            var @case = new Case().In(Db);
            var caseEvents = new[]
            {
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short())
            }.In(Db);
            caseEvents[0].EventDate = Fixture.Date();
            caseEvents[1].EventDate = Fixture.Date();
            caseEvents[2].EventDate = Fixture.Date();
            @case.CaseEvents.AddRange(caseEvents);
            var eventSaveModel = new EventTopicSaveModel()
            {
                Rows = new[]
                {
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[0].EventNo,
                        Cycle = caseEvents[0].Cycle,
                        EventDate = null
                    },
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[1].EventNo,
                        Cycle = caseEvents[1].Cycle,
                        EventDate = null
                    },
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[2].EventNo,
                        Cycle = caseEvents[2].Cycle,
                        EventDate = Fixture.Date()
                    }
                }
            };
            var eventSaveModelJObject = JObject.FromObject(eventSaveModel);

            fixture.Subject.UpdateData(eventSaveModelJObject, null, @case);
            
            Assert.Equal(caseEvents[0].EventDate, null);
            Assert.Equal(caseEvents[0].IsOccurredFlag, 0);
            Assert.Equal(caseEvents[1].EventDate, null);
            Assert.Equal(caseEvents[1].IsOccurredFlag, 0);
            Assert.Equal(caseEvents[2].EventDate, eventSaveModel.Rows[2].EventDate?.Date);
        }

        [Fact]
        public void ShouldCreateCaseEventIfThereIsntOne()
        {
            var fixture = new ActionsTopicValidatorFixture(Db);
            var @case = new Case().In(Db);

            var eventSaveModel = new EventTopicSaveModel()
            {
                Rows = new[]
                {
                    new EventSaveModel()
                    {
                        EventNo = Fixture.Integer(),
                        Cycle = Fixture.Short(),
                        EventDate = null
                    }
                }
            };
            var eventSaveModelJObject = JObject.FromObject(eventSaveModel);

            fixture.Subject.UpdateData(eventSaveModelJObject, null, @case);

            Assert.Equal(@case.CaseEvents.Count(),1);
            Assert.Equal(@case.CaseEvents.First().EventNo, eventSaveModel.Rows[0].EventNo);
            Assert.Equal(@case.CaseEvents.First().Cycle, eventSaveModel.Rows[0].Cycle);
        }

        public class ActionsTopicValidatorFixture : IFixture<ActionsTopicDataUpdater>
        {
            public ActionsTopicValidatorFixture(IDbContext db)
            {
                Subject = new ActionsTopicDataUpdater();
            }

            public ActionsTopicDataUpdater Subject { get; }
        }
    }
}
