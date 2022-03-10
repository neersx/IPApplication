using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class TaskPlannerAnalyticsProviderFacts
    {
        [Fact]
        public async Task ShouldReturnGroupedResultsTheirCountAndUserids()
        {
            var fixture = new TaskPlannerAnalyticsProviderFixture();
            var userId1 = Fixture.Integer();
            var userId2 = Fixture.Integer();

            fixture.ServerTransactionDataQueue.Dequeue<TaskPlannerAnalyticsProvider.TaskPlannerAnalytics>(TransactionalEventTypes.TaskPlannerAccessed).Returns(new[]
            {
                new TaskPlannerAnalyticsProvider.TaskPlannerAnalytics { Value = userId1.ToString(), Id = 1 },
                new TaskPlannerAnalyticsProvider.TaskPlannerAnalytics { Value = userId1.ToString(), Id = 2 },
                new TaskPlannerAnalyticsProvider.TaskPlannerAnalytics { Value = userId2.ToString(), Id = 3 }
            });

            var result = (await fixture.Subject.Provide(Fixture.Date())).ToList();
            Assert.Equal(2, result.Count);

            var ae = result.Single(_ => _.Name.Equals(AnalyticsEventCategories.StatisticsTaskPlannerUsersPrefix));
            Assert.Equal("2", ae.Value);

            ae = result.Single(_ => _.Name.Equals(AnalyticsEventCategories.StatisticsTaskPlannerAccessedPrefix));
            Assert.Equal("3", ae.Value);
        }

        internal class TaskPlannerAnalyticsProviderFixture : IFixture<TaskPlannerAnalyticsProvider>
        {
            public TaskPlannerAnalyticsProviderFixture()
            {
                ContentHasher = Substitute.For<IContentHasher>();
                ServerTransactionDataQueue = Substitute.For<IServerTransactionDataQueue>();
                Subject = new TaskPlannerAnalyticsProvider(ServerTransactionDataQueue);
            }

            public IServerTransactionDataQueue ServerTransactionDataQueue { get; }

            public IContentHasher ContentHasher { get; }
            public TaskPlannerAnalyticsProvider Subject { get; }
        }
    }
}