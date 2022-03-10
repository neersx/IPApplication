using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration
{
    public class GraphNotificationFacts : FactBase
    {
        [Fact]
        public void VerifySendAsyncMethod()
        {
            var f = new GraphNotificationFixture(Db);
            f.Subject.SendAsync(Fixture.RandomString(10), BackgroundProcessSubType.GraphIntegrationCheckStatus, Fixture.Integer());
            f.MessageClient.Received(1).SendAsync(Arg.Any<BackgroundProcessMessage>());
        }

        [Fact]
        public void VerifyDeleteAsyncMethod()
        {
            var f = new GraphNotificationFixture(Db);
            var userId = Fixture.Integer();
            new BackgroundProcess { IdentityId = userId, Id = Fixture.Integer(), ProcessType = BackgroundProcessSubType.GraphStatus.ToString(), ProcessSubType = BackgroundProcessSubType.GraphIntegrationCheckStatus.ToString() }.In(Db);
            f.MessageClient.DeleteBackgroundProcessMessages(Arg.Any<int[]>()).Returns(true);
            var result = f.Subject.DeleteAsync(userId);
            Assert.True(result.Result);
        }

        public class GraphNotificationFixture : IFixture<GraphNotification>
        {
            public GraphNotificationFixture(InMemoryDbContext db)
            {
                DbContext = db;
                MessageClient = Substitute.For<IBackgroundProcessMessageClient>();
                Subject = new GraphNotification(MessageClient, DbContext);
            }

            public IDbContext DbContext { get; set; }
            public IBackgroundProcessMessageClient MessageClient { get; set; }
            public GraphNotification Subject { get; set; }
        }
    }
}