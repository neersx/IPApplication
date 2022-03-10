using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class SchemaMappingGeneratedAnalyticsProviderFacts : FactBase
    {
        class SchemaMappingGeneratedAnalyticsProviderFixture : IFixture<SchemaMappingGeneratedAnalyticsProvider>
        {
            public SchemaMappingGeneratedAnalyticsProviderFixture(IDbContext db)
            {
                DataQueue = Substitute.For<IServerTransactionDataQueue>();
                Subject = new SchemaMappingGeneratedAnalyticsProvider(db, DataQueue);
            }

            public IServerTransactionDataQueue DataQueue { get; }
            public SchemaMappingGeneratedAnalyticsProvider Subject { get; }
        }

        [Fact]
        public async Task ShouldDequeueMessagesFromDataQueue()
        {
            var fixture = new SchemaMappingGeneratedAnalyticsProviderFixture(Db);

            fixture.Subject.Provide(Fixture.Date());

            fixture.DataQueue.Received(1).Dequeue<RawEventData>(TransactionalEventTypes.SchemaMappingGeneratedViaApi);
        }

        [Fact]
        public async Task ShouldMapAppropriately()
        {
            var fixture = new SchemaMappingGeneratedAnalyticsProviderFixture(Db);
            var value1 = Fixture.Integer();
            var value2 = Fixture.Integer();
            var rawData = new List<RawEventData>
            {
                new RawEventData {Id = Fixture.Integer(), Value = value1.ToString()},
                new RawEventData {Id = Fixture.Integer(), Value = value1.ToString()},
                new RawEventData {Id = Fixture.Integer(), Value = value2.ToString()}
            };
            fixture.DataQueue.Dequeue<RawEventData>(TransactionalEventTypes.SchemaMappingGeneratedViaApi).Returns(rawData);
            var schemaMapping1 = new InprotechKaizen.Model.SchemaMappings.SchemaMapping {Id = value1, Name = Fixture.String()}.In(Db);
            var schemaMapping2 = new InprotechKaizen.Model.SchemaMappings.SchemaMapping {Id = value2, Name = Fixture.String()}.In(Db);

            var response = (await fixture.Subject.Provide(Fixture.Date())).ToList();

            fixture.DataQueue.Received(1).Dequeue<RawEventData>(TransactionalEventTypes.SchemaMappingGeneratedViaApi);
            Assert.Equal(2, response.Count);
            Assert.Equal(2.ToString(), response.First().Value);
            Assert.Equal($"{AnalyticsEventCategories.StatisticsSchemaMappingViaApiPrefix} ({schemaMapping1.Name})", response.First().Name);

            Assert.Equal(1.ToString(), response.Last().Value);
            Assert.Equal($"{AnalyticsEventCategories.StatisticsSchemaMappingViaApiPrefix} ({schemaMapping2.Name})", response.Last().Name);
        }
    }
}