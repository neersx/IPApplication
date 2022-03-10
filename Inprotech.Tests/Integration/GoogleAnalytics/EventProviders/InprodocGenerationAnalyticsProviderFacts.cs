using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class InprodocGenerationAnalyticsProviderFacts
    {
        class InprodocGenerationAnalyticsProviderFixture : IFixture<InprodocGenerationAnalyticsProvider>
        {
            public InprodocGenerationAnalyticsProviderFixture()
            {
                ServerTransactionDataQueue = Substitute.For<IServerTransactionDataQueue>();
                Subject = new InprodocGenerationAnalyticsProvider(ServerTransactionDataQueue);
            }

            public IServerTransactionDataQueue ServerTransactionDataQueue { get; }
            public InprodocGenerationAnalyticsProvider Subject { get; }
        }

        [Fact]
        public async Task ShouldReturnGroupedResultsTheirCountAndAppropriateKeys()
        {
            var fixture = new InprodocGenerationAnalyticsProviderFixture();
            var version1 = Fixture.String();
            var version2 = Fixture.String();
            var sessions = new[]
            {
                Guid.NewGuid(),
                Guid.NewGuid(),
                Guid.NewGuid()
            };
            fixture.ServerTransactionDataQueue.Dequeue<InprodocGenerationAnalyticsProvider.InprodocAnalytics>(TransactionalEventTypes.InprodocAdHocGeneration).Returns(new[]
            {
                new InprodocGenerationAnalyticsProvider.InprodocAnalytics {Value = $"{version1}^{sessions[0]}"},
                new InprodocGenerationAnalyticsProvider.InprodocAnalytics {Value = $"{version1}^{sessions[1]}"},
                new InprodocGenerationAnalyticsProvider.InprodocAnalytics {Value = $"{version2}^{sessions[2]}"}
            });

            var result = (await fixture.Subject.Provide(Fixture.Date())).ToList();

            Assert.Equal(2, result.Count);
            Assert.Equal(2.ToString(), result.First().Value);
            Assert.Equal($"{AnalyticsEventCategories.StatisticsAdHocDocGeneratedInprodocPrefix} ({version1})", result.First().Name);

            Assert.Equal(1.ToString(), result.Last().Value);
            Assert.Equal($"{AnalyticsEventCategories.StatisticsAdHocDocGeneratedInprodocPrefix} ({version2})", result.Last().Name);
        }
    }
}