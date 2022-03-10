using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class TimeRecordingAnalyticsProviderFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnUniqueUsersWhoAccessedTimeRecordingAndCount()
        {
            var fixture = new TimeRecordingAnalyticsProviderFixture();
            var userId1 = Fixture.Integer();
            var userId2 = Fixture.Integer();
            var userId3 = Fixture.Integer();

            fixture.ServerTransactionDataQueue.Dequeue<TimeRecordingAnalyticsProvider.TimeRecordingAnalytics>(TransactionalEventTypes.TimeRecordingAccessed).Returns(new[]
            {
                new TimeRecordingAnalyticsProvider.TimeRecordingAnalytics { Value = userId1.ToString(), Id = 1 },
                new TimeRecordingAnalyticsProvider.TimeRecordingAnalytics { Value = userId1.ToString(), Id = 2 },
                new TimeRecordingAnalyticsProvider.TimeRecordingAnalytics { Value = userId2.ToString(), Id = 3 },
                new TimeRecordingAnalyticsProvider.TimeRecordingAnalytics { Value = userId3.ToString(), Id = 4 },
                new TimeRecordingAnalyticsProvider.TimeRecordingAnalytics { Value = userId3.ToString(), Id = 5 }
            });

            var result = (await fixture.Subject.Provide(Fixture.Date())).ToList();
            Assert.Equal(2, result.Count);
            var ae = result.Single(_ => _.Name.Equals(AnalyticsEventCategories.StatisticsTimeRecordingUsersPrefix));
            Assert.Equal("3", ae.Value);
            ae = result.Single(_ => _.Name.Equals(AnalyticsEventCategories.StatisticsTimeRecordingAccessedPrefix));
            Assert.Equal("5", ae.Value);
        }

        class TimeRecordingAnalyticsProviderFixture : IFixture<TimeRecordingAnalyticsProvider>
        {
            public TimeRecordingAnalyticsProviderFixture()
            {
                ServerTransactionDataQueue = Substitute.For<IServerTransactionDataQueue>();
                Subject = new TimeRecordingAnalyticsProvider(ServerTransactionDataQueue);
            }

            public TimeRecordingAnalyticsProvider Subject { get; }
            public IServerTransactionDataQueue ServerTransactionDataQueue { get; }
        }

    }
}
