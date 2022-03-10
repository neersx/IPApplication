using Inprotech.Infrastructure.Messaging;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.System.Messages;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class GlobalNameChangeMonitorFacts : FactBase
    {
        public GlobalNameChangeMonitorFacts()
        {
            _caseIdProvider = Substitute.For<IGlobalNameChangeCaseIdProvider>();
            _bus = Substitute.For<IBus>();
            _monitor = new GlobalNameChangeMonitor(Db, _bus, _caseIdProvider);
        }

        readonly IGlobalNameChangeCaseIdProvider _caseIdProvider;
        readonly IBus _bus;
        readonly GlobalNameChangeMonitor _monitor;

        [Fact]
        public void ReturnsIdsOfAllCompleteCases()
        {
            new GlobalNameChangeRequest {CaseId = 1}.In(Db);
            _caseIdProvider.CaseIds.Returns(new[] {2});

            _monitor.Run();

            _bus.Received(1).Publish(
                                     Arg.Is<BroadcastMessageToClient>(m => m.Topic.Equals("globalName.change.2") &&
                                                                      m.Data.Equals("Complete")));
        }

        [Fact]
        public void ReturnsIdsOfAllRunningCases()
        {
            new GlobalNameChangeRequest {CaseId = 1}.In(Db);
            new GlobalNameChangeRequest {CaseId = 2}.In(Db);
            _caseIdProvider.CaseIds.Returns(new[] {1});

            _monitor.Run();

            _bus.Received(1).Publish(
                                     Arg.Is<BroadcastMessageToClient>(m => m.Topic.Equals("globalName.change.1") &&
                                                                      m.Data.Equals("Running")));
        }
    }
}