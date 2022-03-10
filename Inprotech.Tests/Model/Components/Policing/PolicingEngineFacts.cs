using System.Linq;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class PolicingEngineFacts
    {
        public class IsPoliceImmediatelyMethod : FactBase
        {
            [Fact]
            public void GeneratesABatchNumberForPoliceImmediate()
            {
                var f = new PolicingEngineFixture(Db);
                var @case = new CaseBuilder().Build();
                new CaseEventBuilder().BuildForCase(@case);
                @case.In(Db);
                var policeCaseEvent = new PoliceCaseEvent(@case.CaseEvents.First());
                //f.Subject.EnqueuePolicingRequests(new List<PoliceCaseEvent> { policeCaseEvent} );
            }
        }
    }

    public class PolicingEngineFixture : IFixture<PolicingEngine>
    {
        public PolicingEngineFixture(InMemoryDbContext db)
        {
            var securityContext = Substitute.For<ISecurityContext>();
            PolicingUtility = Substitute.For<IPolicingUtility>();

            Subject = new PolicingEngine(db, securityContext, Substitute.For<IBus>());
        }

        public IPolicingUtility PolicingUtility { get; }
        public PolicingEngine Subject { get; }
    }
}