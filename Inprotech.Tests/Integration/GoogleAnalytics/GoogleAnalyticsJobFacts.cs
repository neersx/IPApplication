using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Instrumentation;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics
{
    public class GoogleAnalyticsJobFacts : FactBase
    {
        [Fact]
        public async Task DoesNotRunIfSettingsNotDefined()
        {
            var f = new GoogleAnalyticsJobFixture(Db);
            await f.Subject.CollectAndSend();
            f.SettingsResolver.Received(1).IsEnabled();
            f.Db.DidNotReceive().Set<User>();
            f.Client.DidNotReceiveWithAnyArgs().Post(Arg.Any<IGoogleAnalyticsRequest>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task PostsInformation()
        {
            var f = new GoogleAnalyticsJobFixture(Db).WithSetting();
            await f.Subject.CollectAndSend();

            f.Client.Received(1).Post(Arg.Any<IGoogleAnalyticsRequest[]>()).IgnoreAwaitForNSubstituteAssertion();
            f.Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task PostsInformationHandlesErrorInProvider()
        {
            var f = new GoogleAnalyticsJobFixture(Db).WithSetting().WithErrorAnalyticsProvider();
            await f.Subject.CollectAndSend();

            f.Client.Received(1).Post(Arg.Any<IGoogleAnalyticsRequest[]>()).IgnoreAwaitForNSubstituteAssertion();
            f.Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
            f.BackgroundProcessLogger.Received(1).Exception(Arg.Any<Exception>());
        }

        [Fact]
        public async Task DoesNotPostsInformationIfNoChangeInData()
        {
            var key = Fixture.String();
            var value = Fixture.String();
            var f = new GoogleAnalyticsJobFixture(Db).WithSetting().WithErrorAnalyticsProvider(key, value);
            new ServerAnalyticsData() { Event = key, Value = value, LastSent = Fixture.PastDate() }.In(Db);
            await f.Subject.CollectAndSend();

            f.Client.DidNotReceiveWithAnyArgs().Post(Arg.Any<IGoogleAnalyticsRequest[]>()).IgnoreAwaitForNSubstituteAssertion();
            f.Db.DidNotReceive().SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData("Users.")]
        [InlineData("AuthenticationType.")]
        [InlineData("Integrations.")]
        [InlineData("Statistics.")]
        public async Task AlwaysPostsTransactionalData(string prefix)
        {
            var key = prefix + Fixture.String();
            var value = Fixture.String();
            var f = new GoogleAnalyticsJobFixture(Db).WithSetting().WithErrorAnalyticsProvider(key, value);
            new ServerAnalyticsData() { Event = key, Value = value, LastSent = Fixture.PastDate() }.In(Db);
            await f.Subject.CollectAndSend();

            f.Client.Received(1).Post(Arg.Any<IGoogleAnalyticsRequest[]>()).IgnoreAwaitForNSubstituteAssertion();
            f.Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
        }

        class GoogleAnalyticsJobFixture : IFixture<ServerAnalyticsJob>
        {
            public GoogleAnalyticsJobFixture(InMemoryDbContext dbContext)
            {
                Db = dbContext;
                SettingsResolver = Substitute.For<IGoogleAnalyticsSettingsResolver>();
                Client = Substitute.For<IGoogleAnalyticsClient>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();

                var anyProvider = Substitute.For<IAnalyticsEventProvider>();
                anyProvider.Provide(Arg.Any<DateTime>()).ReturnsForAnyArgs(new List<AnalyticsEvent>()
                {
                    new AnalyticsEvent(Fixture.String(), Fixture.String())
                });
                AnalyticsEventProviders = new[] { anyProvider };
                BackgroundProcessLogger = Substitute.For<IBackgroundProcessLogger<ServerAnalyticsJob>>();
                AnalyticsRuntimeSettings = new AnalyticsRuntimeSettings { IdentifierKey = Fixture.String() };

                Subject = new ServerAnalyticsJob(SettingsResolver, Client, Fixture.Today,
                                                 AnalyticsEventProviders, dbContext, BackgroundProcessLogger, AnalyticsRuntimeSettings);
            }

            public ServerAnalyticsJob Subject { get; set; }

            public InMemoryDbContext Db { get; }

            public IGoogleAnalyticsSettingsResolver SettingsResolver { get; }

            public IGoogleAnalyticsClient Client { get; }

            public IDisplayFormattedName DisplayFormattedName { get; }

            public IEnumerable<IAnalyticsEventProvider> AnalyticsEventProviders { get; set; }

            public IBackgroundProcessLogger<ServerAnalyticsJob> BackgroundProcessLogger { get; }

            public AnalyticsRuntimeSettings AnalyticsRuntimeSettings { get; }

            public GoogleAnalyticsJobFixture WithSetting()
            {
                SettingsResolver.IsEnabled().Returns(true);

                new User(Fixture.String("xyz"), false).In(Db);
                DisplayFormattedName.For(Arg.Any<int>()).Returns("abc");
                return this;
            }

            public GoogleAnalyticsJobFixture WithErrorAnalyticsProvider(string key = null, string value = null)
            {
                var anyProvider = Substitute.For<IAnalyticsEventProvider>();
                anyProvider.Provide(Arg.Any<DateTime>()).ReturnsForAnyArgs(new List<AnalyticsEvent>()
                {
                    new AnalyticsEvent(key ?? Fixture.String(), value ?? Fixture.String())
                });

                var exceptionProvider = Substitute.For<IAnalyticsEventProvider>();
                exceptionProvider.Provide(Arg.Any<DateTime>()).ThrowsForAnyArgs(new Exception());

                AnalyticsEventProviders = new[] { anyProvider, exceptionProvider };
                Subject = new ServerAnalyticsJob(SettingsResolver, Client, Fixture.Today,
                                                 AnalyticsEventProviders, Db, BackgroundProcessLogger, AnalyticsRuntimeSettings);
                return this;
            }
        }
    }
}