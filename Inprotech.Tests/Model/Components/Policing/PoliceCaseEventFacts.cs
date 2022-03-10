using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class PoliceCaseEventFacts
    {
        public class EnqueueMethod : FactBase
        {
            class CriteriaBuilder : Criteria
            {
                public CriteriaBuilder(int id)
                {
                    Id = id;
                }
            }

            [Fact]
            public void HandlesCaseEventPolicingWithoutDataEntryTask()
            {
                var caseEvent = new CaseEvent(1, 2, 3);
                var subject = new PoliceCaseEvent(caseEvent);
                var policingEngine = Substitute.For<IPolicingEngine>();

                subject.Enqueue(1, policingEngine);

                policingEngine.Received(1).PoliceEvent(caseEvent, null, 1, null);
            }

            [Fact]
            public void PassesDataEntryTaskCriteriaId()
            {
                var caseEvent = new CaseEvent(1, 2, 3);
                var dataEntryTask = new DataEntryTask(new CriteriaBuilder(999), 2);
                var subject = new PoliceCaseEvent(caseEvent, dataEntryTask);
                var policingEngine = Substitute.For<IPolicingEngine>();

                subject.Enqueue(888, policingEngine);

                policingEngine.Received(1).PoliceEvent(caseEvent, 999, 888, null);
            }
        }
    }
}