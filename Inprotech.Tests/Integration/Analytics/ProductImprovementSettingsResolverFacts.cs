using System;
using System.Collections.Generic;
using Inprotech.Infrastructure;
using Inprotech.Integration.Analytics;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Analytics
{
    public class ProductImprovementSettingsResolverFacts
    {
        [Theory]
        [InlineData(true, true)]
        [InlineData(false, true)]
        [InlineData(true, false)]
        [InlineData(false, false)]
        public void ShouldResolveStoredValues(bool firm, bool user)
        {
            var fixture = new ProductImprovementSettingsResolverFixture(new Dictionary<string, string>
            {
                {
                    KnownAppSettingsKeys.ProductImprovement, JsonConvert.SerializeObject(new
                    {
                        FirmUsageStatisticsConsented = firm,
                        UserUsageStatisticsConsented = user
                    })
                }
            });

            var result = fixture.Subject.Resolve();

            Assert.Equal(firm, result.FirmUsageStatisticsConsented);
            Assert.Equal(user, result.UserUsageStatisticsConsented);
        }

        class ProductImprovementSettingsResolverFixture : IFixture<ProductImprovementSettingsResolver>
        {
            public ProductImprovementSettingsResolverFixture(Dictionary<string, string> values)
            {
                var groupedConfig = Substitute.For<Func<string, IGroupedConfig>>();
                var config = Substitute.For<IGroupedConfig>();
                config.GetValues(KnownAppSettingsKeys.ProductImprovement).Returns(values);
                groupedConfig("InprotechServer.AppSettings").Returns(config);

                Subject = new ProductImprovementSettingsResolver(groupedConfig);
            }

            public ProductImprovementSettingsResolver Subject { get; }
        }

        [Fact]
        public void ShouldResolveDefaultForNoValue()
        {
            var fixture = new ProductImprovementSettingsResolverFixture(new Dictionary<string, string>());

            var result = fixture.Subject.Resolve();

            Assert.False(result.FirmUsageStatisticsConsented);
            Assert.False(result.UserUsageStatisticsConsented);
        }

        [Fact]
        public void ShouldResolveFalseIfNull()
        {
            var fixture = new ProductImprovementSettingsResolverFixture(new Dictionary<string, string>
            {
                {
                    KnownAppSettingsKeys.ProductImprovement, JsonConvert.SerializeObject(new
                    {
                        FirmUsageStatisticsConsented = (bool?) null,
                        UserUsageStatisticsConsented = (bool?) null
                    })
                }
            });

            var result = fixture.Subject.Resolve();

            Assert.False(result.FirmUsageStatisticsConsented);
            Assert.False(result.UserUsageStatisticsConsented);
        }
    }
}