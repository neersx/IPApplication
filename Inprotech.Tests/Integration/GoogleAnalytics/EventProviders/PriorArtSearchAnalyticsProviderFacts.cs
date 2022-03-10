using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class PriorArtSearchAnalyticsProviderFacts : FactBase
    {
        class PriorArtSearchAnalyticsProviderFixture : IFixture<PriorArtSearchAnalyticsProvider>
        {
            public PriorArtSearchAnalyticsProviderFixture()
            {
                DataQueue = Substitute.For<IServerTransactionDataQueue>();
                Subject = new PriorArtSearchAnalyticsProvider(DataQueue);
            }

            public IServerTransactionDataQueue DataQueue { get; }
            public PriorArtSearchAnalyticsProvider Subject { get; }
        }

        [Fact]
        public async Task ShouldDequeueMessagesFromDataQueue()
        {
            var fixture = new PriorArtSearchAnalyticsProviderFixture();

            fixture.Subject.Provide(Fixture.Date());

            fixture.DataQueue.Received(1).Dequeue<RawEventData>(TransactionalEventTypes.PriorArtIdsPdf, TransactionalEventTypes.PriorArtIdsDocuments, TransactionalEventTypes.PriorArtSearch);
        }

        [Fact]
        public async Task ShouldMapAppropriately()
        {
            var fixture = new PriorArtSearchAnalyticsProviderFixture();
            var value1 = TransactionalEventTypes.PriorArtIdsPdf;
            var value2 = TransactionalEventTypes.PriorArtIdsDocuments;
            var rawData = new List<RawEventData>
            {
                new RawEventData {Id = Fixture.Integer(), Value = value1},
                new RawEventData {Id = Fixture.Integer(), Value = value1},
                new RawEventData {Id = Fixture.Integer(), Value = value2}
            };
            fixture.DataQueue.Dequeue<RawEventData>(TransactionalEventTypes.PriorArtIdsPdf, TransactionalEventTypes.PriorArtIdsDocuments, TransactionalEventTypes.PriorArtSearch).Returns(rawData);

            var response = (await fixture.Subject.Provide(Fixture.Date())).ToList();

            fixture.DataQueue.Received(1).Dequeue<RawEventData>(TransactionalEventTypes.PriorArtIdsPdf, TransactionalEventTypes.PriorArtIdsDocuments, TransactionalEventTypes.PriorArtSearch);
            Assert.Equal(2, response.Count);
            Assert.Equal(2.ToString(), response.First().Value);
            Assert.Equal(AnalyticsEventCategories.StatisticsInnographyIdsPdf, response.First().Name);

            Assert.Equal(1.ToString(), response.Last().Value);
            Assert.Equal(AnalyticsEventCategories.StatisticsInnographyIdsDocuments, response.Last().Name);
        }
    }
}