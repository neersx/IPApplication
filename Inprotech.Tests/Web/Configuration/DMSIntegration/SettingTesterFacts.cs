using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Web.Configuration.DMSIntegration;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class SettingTesterFacts : FactBase
    {
        class SettingTesterFixture : IFixture<SettingTester>
        {
            public SettingTesterFixture()
            {
                DmsEventSink = Substitute.For<IDmsEventSink>();
                DmsEventCapture = Substitute.For<IDmsEventCapture>();
                Logger = Substitute.For<ILogger<SettingTestController>>();
                CredentialsResolver = Substitute.For<ICredentialsResolver>();
                CredentialsResolver.Resolve(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Returns(new DmsCredential());
                WorkSiteManagerFactory = Substitute.For<IWorkSiteManagerFactory>();
                Subject = new SettingTester(WorkSiteManagerFactory, CredentialsResolver, DmsEventSink, Logger, DmsEventCapture);
            }

            public IDmsEventSink DmsEventSink { get; }

            public IDmsEventCapture DmsEventCapture { get; }

            public ILogger<SettingTestController> Logger { get; }

            public ICredentialsResolver CredentialsResolver { get; }

            public IWorkSiteManagerFactory WorkSiteManagerFactory { get; }

            public SettingTester Subject { get; }
        }
        
        [Fact]
        public async Task ShouldReturnEmptyIfNoRecords()
        {
            var fixture = new SettingTesterFixture();
            var settings = new ConnectionTestRequestModel
            {
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
            };

            var response = await fixture.Subject.TestConnections(settings);

            Assert.Empty(response);
        }
        
        [Fact]
        public async Task ShouldReturnResultsForEachRecord()
        {
            var fixture = new SettingTesterFixture();
            var settings = new ConnectionTestRequestModel
            {
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
                {
                    new IManageSettings.SiteDatabaseSettings(),
                    new IManageSettings.SiteDatabaseSettings() 
                }
            };

            var response = await fixture.Subject.TestConnections(settings);

            Assert.Equal(2, response.Count());
        }
        
        [Fact]
        public async Task ShouldReturnSuccessIfSuccess()
        {
            var fixture = new SettingTesterFixture();
            var settings = new ConnectionTestRequestModel
            {
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
                {
                    new IManageSettings.SiteDatabaseSettings(),
                    new IManageSettings.SiteDatabaseSettings() 
                }
            };

            fixture.WorkSiteManagerFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);
            var response = (await fixture.Subject.TestConnections(settings)).ToList();

            Assert.Equal(2, response.Count());
            Assert.True(response.First().Success);
            Assert.True(response.Last().Success);
        }
        
        [Fact]
        public async Task ShouldReturnFailIfFail()
        {
            var fixture = new SettingTesterFixture();
            var settings = new ConnectionTestRequestModel
            {
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
                {
                    new IManageSettings.SiteDatabaseSettings(),
                    new IManageSettings.SiteDatabaseSettings() 
                }
            };

            fixture.WorkSiteManagerFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(false);
            var response = (await fixture.Subject.TestConnections(settings)).ToList();

            Assert.Equal(2, response.Count());
            Assert.False(response.First().Success);
            Assert.False(response.Last().Success);
        }

        [Fact]
        public async Task ShouldReturnFailIfThrowsException()
        {
            var fixture = new SettingTesterFixture();
            var settings = new ConnectionTestRequestModel
            {
                Settings = new List<IManageSettings.SiteDatabaseSettings>()
                {
                    new IManageSettings.SiteDatabaseSettings(),
                    new IManageSettings.SiteDatabaseSettings() 
                }
            };

            fixture.WorkSiteManagerFactory.GetWorkSiteManager(Arg.Any<IManageSettings.SiteDatabaseSettings>()).Connect(Arg.Any<IManageSettings.SiteDatabaseSettings>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Throws<Exception>();
            var response = (await fixture.Subject.TestConnections(settings)).ToList();

            Assert.Equal(2, response.Count());
            Assert.False(response.First().Success);
            Assert.False(response.Last().Success);
            fixture.Logger.Received(2).Exception(Arg.Any<Exception>());
        }
    }
}