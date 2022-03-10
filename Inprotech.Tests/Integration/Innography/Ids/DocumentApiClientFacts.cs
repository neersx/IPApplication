using System;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.Ids;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography.Ids
{
    public class DocumentApiClientFacts : FactBase
    {
        public class DocumentsMethod
        {
            [Fact]
            public async Task ShouldCallTheApiClientWithExpectedFormatString()
            {
                var countryCode = Fixture.String();
                var number = Fixture.String();
                var kindCode = Fixture.String();
                var baseApi = new Uri("http://test");
                var platformClientId = Fixture.String();
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = true,
                    PlatformClientId = platformClientId,
                    ClientSecret = Fixture.String(),
                    ClientId = Fixture.String(),
                    ApiBase = baseApi
                });

                await fixture.Subject.Documents(countryCode, number, kindCode);

                fixture.InnographyClient.Received(1)
                       .Get<DocumentApiResponse>(Arg.Any<InnographyClientSettings>(), new Uri(baseApi, new Uri($"/documents/{countryCode}/{number}/{kindCode}?client_id={platformClientId}", UriKind.Relative)))
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.Bus.Received(1).PublishAsync(Arg.Is<TransactionalAnalyticsMessage>(_ => _.EventType == TransactionalEventTypes.PriorArtIdsDocuments))
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowExceptionIfCountryCodeEmpty()
            {
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = true
                });

                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Documents(string.Empty, Fixture.String(), Fixture.String()); });
            }

            [Fact]
            public async Task ShouldThrowExceptionIfIPIDNotEnabled()
            {
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = false
                });

                await Assert.ThrowsAsync<Exception>(async () => { await fixture.Subject.Documents(Fixture.String(), Fixture.String(), Fixture.String()); });
            }

            [Fact]
            public async Task ShouldThrowExceptionIfNumberEmpty()
            {
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = true
                });

                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Documents(Fixture.String(), string.Empty, Fixture.String()); });
            }
        }

        public class PdfMethod
        {
            [Fact]
            public async Task ShouldCallTheApiClientWithExpectedFormatString()
            {
                var countryCode = Fixture.String();
                var number = Fixture.String();
                var kindCode = Fixture.String();
                var baseApi = new Uri("http://test");
                var platformClientId = Fixture.String();
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = true,
                    PlatformClientId = platformClientId,
                    ClientSecret = Fixture.String(),
                    ClientId = Fixture.String(),
                    ApiBase = baseApi
                });

                await fixture.Subject.Pdf(countryCode, number, kindCode);

                fixture.InnographyClient.Received(1)
                       .Get<Stream>(Arg.Any<InnographyClientSettings>(), new Uri(baseApi, new Uri($"/documents/pdf/{countryCode}/{number}/{kindCode}?client_id={platformClientId}", UriKind.Relative)))
                       .IgnoreAwaitForNSubstituteAssertion();
                fixture.Bus.Received(1).PublishAsync(Arg.Is<TransactionalAnalyticsMessage>(_ => _.EventType == TransactionalEventTypes.PriorArtIdsPdf))
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowExceptionIfCountryCodeEmpty()
            {
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = true
                });

                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Pdf(string.Empty, Fixture.String(), Fixture.String()); });
            }

            [Fact]
            public async Task ShouldThrowExceptionIfIPIDNotEnabled()
            {
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = false
                });

                await Assert.ThrowsAsync<Exception>(async () => { await fixture.Subject.Pdf(Fixture.String(), Fixture.String(), Fixture.String()); });
            }

            [Fact]
            public async Task ShouldThrowExceptionIfNumberEmpty()
            {
                var fixture = new DocumentApiClientFixture(new InnographySetting
                {
                    IsIPIDIntegrationEnabled = true
                });

                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Pdf(Fixture.String(), string.Empty, Fixture.String()); });
            }
        }

        internal class DocumentApiClientFixture : IFixture<DocumentApiClient>
        {
            public DocumentApiClientFixture(InnographySetting settings)
            {
                Bus = Substitute.For<IBus>();
                Resolver = Substitute.For<IInnographySettingsResolver>();
                InnographyClient = Substitute.For<IInnographyClient>();
                Resolver.Resolve(Arg.Any<string>()).Returns(settings);
                Subject = new DocumentApiClient(Resolver, InnographyClient, Bus);
            }

            public IInnographySettingsResolver Resolver { get; set; }
            public IInnographyClient InnographyClient { get; set; }
            public IBus Bus { get; set; }
            public DocumentApiClient Subject { get; }
        }
    }
}