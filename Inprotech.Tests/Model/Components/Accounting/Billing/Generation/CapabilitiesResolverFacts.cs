using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Reporting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Generation
{
    public class CapabilitiesResolverFacts
    {
        static CapabilitiesResolver CreateSubject(ProviderInfo providerInfo = null)
        {
            var reportProvider = Substitute.For<IReportProvider>();
            if (providerInfo != null)
            {
                reportProvider.GetReportProviderInfo().Returns(providerInfo);
            }

            return new CapabilitiesResolver(reportProvider);
        }

        public class CanGenerateBills
        {
            [Fact]
            public async Task ShouldReturnCanGenerateBillsIfReportProviderIsReportingServices()
            {
                var subject = CreateSubject(new ProviderInfo
                {
                    Provider = ReportProviderType.MsReportingServices
                });

                var result = await subject.Resolve();

                Assert.True(result.CanGenerateBills);
            }

            [Fact]
            public async Task ShouldReturnUnableToGenerateBillsIfReportProviderIsNotReportingServices()
            {
                var subject = CreateSubject(new ProviderInfo
                {
                    Provider = ReportProviderType.Default
                });

                var result = await subject.Resolve();

                Assert.False(result.CanGenerateBills);
            }

            [Fact]
            public async Task ShouldReturnUnableToGenerateBillsIfReportProviderIsNotConfigured()
            {
                var subject = CreateSubject();

                var result = await subject.Resolve();

                Assert.False(result.CanGenerateBills);
            }
        }

        public class CanGeneratePrintPreviews
        {
            [Fact]
            public async Task ShouldReturnCanGeneratePrintPreviewIfReportProviderIsReportingServices()
            {
                var subject = CreateSubject(new ProviderInfo
                {
                    Provider = ReportProviderType.MsReportingServices
                });

                var result = await subject.Resolve();

                Assert.True(result.CanGeneratePrintPreview);
            }
            
            [Fact]
            public async Task ShouldReturnUnableToGeneratePrintPreviewIfReportProviderIsNotReportingServices()
            {
                var subject = CreateSubject(new ProviderInfo
                {
                    Provider = ReportProviderType.Default
                });

                var result = await subject.Resolve();

                Assert.False(result.CanGeneratePrintPreview);
            }
            
            [Fact]
            public async Task ShouldReturnUnableToGeneratePrintPreviewIfReportProviderIsNotConfigured()
            {
                var subject = CreateSubject();

                var result = await subject.Resolve();

                Assert.False(result.CanGeneratePrintPreview);
            }
        }
    }
}