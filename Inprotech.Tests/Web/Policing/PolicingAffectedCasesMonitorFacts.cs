using System.Collections.Generic;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Forecast;
using InprotechKaizen.Model.Components.System.Messages;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingAffectedCasesMonitorFacts
    {
        class Fixture : IFixture<PolicingAffectedCasesMonitor>
        {
            public Fixture()
            {
                Bus = Substitute.For<IBus>();
                Subscriptions = Substitute.For<IPolicingAffectedCasesSubscriptions>();
                RequestSps = Substitute.For<IPolicingRequestSps>();
                Subject = new PolicingAffectedCasesMonitor(Bus, Subscriptions, RequestSps);
            }

            public IBus Bus { get; }
            public IPolicingAffectedCasesSubscriptions Subscriptions { get; }
            public IPolicingRequestSps RequestSps { get; }
            public PolicingAffectedCasesMonitor Subject { get; }

            public Fixture WithAffectedCases(int noOfCases = 5, bool isSupported = true)
            {
                RequestSps.GetNoOfAffectedCases(Arg.Any<int>()).ReturnsForAnyArgs(new PolicingRequestAffectedCases
                {
                    NoOfCases = noOfCases,
                    IsSupported = isSupported
                });

                return this;
            }

            public Fixture WithSubscriptionFor(int requestId)
            {
                Subscriptions.NewRequestids.Returns(new List<int> {requestId});
                return this;
            }
        }

        [Fact]
        public void RunShouldCallSp()
        {
            var noOfCases = 10;
            var isSupported = true;
            var requestId = 1;
            var f = new Fixture()
                    .WithAffectedCases(noOfCases)
                    .WithSubscriptionFor(requestId);
            f.Subject.Run();

            f.RequestSps.Received(1).GetNoOfAffectedCases(requestId);

            f.Bus.Received(1).Publish(Arg.Do<BroadcastMessageToClient>(publishedMessage =>
            {
                Assert.Equal($"policing.affected.cases.{requestId}", publishedMessage.Topic);
                Assert.Equal(noOfCases, ((PolicingRequestAffectedCases) publishedMessage.Data).NoOfCases);
                Assert.Equal(isSupported, ((PolicingRequestAffectedCases) publishedMessage.Data).IsSupported);
            }));
        }

        [Fact]
        public void RunShouldNotCallSpAgainIfRequestIsAlreadyInProcess()
        {
            var noOfCases = 10;
            var isSupported = true;
            var requestId = 1;
            var f = new Fixture()
                    .WithAffectedCases(noOfCases)
                    .WithSubscriptionFor(requestId);

            f.Subject.Run();

            f.Subscriptions.NewRequestids.Returns(new List<int>());
            f.RequestSps.Received(1).GetNoOfAffectedCases(requestId);

            f.Bus.Received(1).Publish(Arg.Do<BroadcastMessageToClient>(publishedMessage =>
            {
                Assert.Equal($"policing.affected.cases.{requestId}", publishedMessage.Topic);
                Assert.Equal(noOfCases, ((PolicingRequestAffectedCases) publishedMessage.Data).NoOfCases);
                Assert.Equal(isSupported, ((PolicingRequestAffectedCases) publishedMessage.Data).IsSupported);
            }));

            f.Subject.Run();
            f.RequestSps.Received(1).GetNoOfAffectedCases(requestId);

            f.Bus.Received(1).Publish(Arg.Any<BroadcastMessageToClient>());
        }
    }
}