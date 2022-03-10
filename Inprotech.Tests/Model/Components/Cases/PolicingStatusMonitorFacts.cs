using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.System.Messages;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class PolicingStatusMonitorFacts : FactBase
    {
        [Fact]
        public void TestComposition()
        {
            var caseId = Fixture.Integer();
            var caseIds = new[] {caseId};
            var status = Fixture.String();
            var statusReader = Substitute.For<IPolicingStatusReader>();
            var caseIdProvider = Substitute.For<IPolicingChangeCaseIdProvider>();
            var bus = Substitute.For<IBus>();

            caseIdProvider.CaseIds.Returns(caseIds);
            var data = new Dictionary<int, string> {{caseId, null}};
            caseIdProvider.PublishedData.Returns(data);
            statusReader.ReadMany(Arg.Is<IEnumerable<int>>(_ => _.Single() == caseId)).ReturnsForAnyArgs(new Dictionary<int, string> {{caseId, status}});

            var monitor = new PolicingStatusMonitor(statusReader, bus, caseIdProvider);

            monitor.Run();

            bus.Received(1).Publish(
                                    Arg.Is<BroadcastMessageToClient>(m => m.Topic.Equals("policing.change." + caseId) &&
                                                                     m.Data.Equals(status)));
        }
    }
}