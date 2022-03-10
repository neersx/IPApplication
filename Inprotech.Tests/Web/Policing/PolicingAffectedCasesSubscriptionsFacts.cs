using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using Inprotech.Web.Policing;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingAffectedCasesSubscriptionsFacts
    {
        public PolicingAffectedCasesSubscriptions Subject { get; } = new PolicingAffectedCasesSubscriptions();

        PolicingAffectedCasesSubscribedMessage Subscribe(int? requestId = null, string connectionId = null)
        {
            return new PolicingAffectedCasesSubscribedMessage
            {
                ConnectionId = connectionId ?? Fixture.String(),
                RequestId = requestId ?? Fixture.Integer()
            };
        }

        [Fact]
        public void DisconnectShouldRemoveRequestIds()
        {
            var subscribed = Subscribe();
            var subscribed2 = Subscribe();
            var subscribed3 = Subscribe(subscribed2.RequestId);

            Subject.Handle(subscribed);
            Subject.Handle(subscribed2);
            Subject.Handle(subscribed3);

            var unSubscribed3 = new PolicingAffectedCasesUnsubscribedMessage
            {
                ConnectionId = subscribed3.ConnectionId
            };
            Subject.Handle(unSubscribed3);

            Assert.Equal(2, Subject.NewRequestids.Count());
            Assert.Contains(subscribed.RequestId, Subject.NewRequestids);
            Assert.Contains(subscribed2.RequestId, Subject.NewRequestids);
        }

        [Fact]
        public void NewRequestShouldCaterForInProgressRequests()
        {
            var subscribed = Subscribe();
            var subscribed2 = Subscribe();
            var subscribed3 = Subscribe();

            Subject.Handle(subscribed);
            Subject.Handle(subscribed2);
            Subject.Handle(subscribed3);

            Assert.Equal(3, Subject.NewRequestids.Count());
            Assert.Contains(subscribed.RequestId, Subject.NewRequestids);
            Assert.Contains(subscribed2.RequestId, Subject.NewRequestids);
            Assert.Contains(subscribed3.RequestId, Subject.NewRequestids);

            Subject.SetInprogress(new[] {subscribed.RequestId, subscribed2.RequestId, subscribed3.RequestId});

            Assert.Empty(Subject.NewRequestids);

            Subject.Handle(Subscribe());

            Assert.Single(Subject.NewRequestids);

            Subject.Handle(new PolicingAffectedCasesUnsubscribedMessage {ConnectionId = subscribed.ConnectionId});
            Subject.Handle(new PolicingAffectedCasesUnsubscribedMessage {ConnectionId = subscribed2.ConnectionId});
            Subject.Handle(new PolicingAffectedCasesUnsubscribedMessage {ConnectionId = subscribed3.ConnectionId});

            Assert.Single(Subject.NewRequestids);
        }

        [Fact]
        public void ShouldKeepRecordOfRequestIds()
        {
            var subscribed = Subscribe();
            Subject.Handle(subscribed);
            Assert.Single(Subject.NewRequestids);
            Assert.Contains(subscribed.RequestId, Subject.NewRequestids);

            var subscribed2 = Subscribe();
            Subject.Handle(subscribed2);
            Assert.Equal(2, Subject.NewRequestids.Count());
            Assert.Contains(subscribed2.RequestId, Subject.NewRequestids);
        }

        [Fact]
        public void ShouldOnlyReturnDistinctRequestIds()
        {
            var subscribed = Subscribe();
            var subscribed2 = Subscribe();
            var subscribed3 = Subscribe(subscribed2.RequestId);
            Subject.Handle(subscribed);
            Subject.Handle(subscribed2);
            Subject.Handle(subscribed3);

            Assert.Equal(2, Subject.NewRequestids.Count());
            Assert.Contains(subscribed.RequestId, Subject.NewRequestids);
            Assert.Contains(subscribed2.RequestId, Subject.NewRequestids);
        }
    }
}