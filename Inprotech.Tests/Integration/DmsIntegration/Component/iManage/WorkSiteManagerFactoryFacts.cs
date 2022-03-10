using System;
using Autofac.Features.Indexed;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using NSubstitute;
using Xunit;
using Version = Inprotech.Integration.DmsIntegration.Component.iManage.Version;

namespace Inprotech.Tests.Integration.DmsIntegration.Component.iManage
{
    public class WorkSiteManagerFactoryFacts
    {
        [Theory]
        [InlineData(IManageSettings.IntegrationTypes.iManageWorkApiV2, Version.WorkApiV2)]
        [InlineData(IManageSettings.IntegrationTypes.iManageCOM, Version.iManageCom)]
        [InlineData(IManageSettings.IntegrationTypes.Demo, Version.Demo)]
        public void ShouldReturnExpectedFolderTypeForInput(string integrationType, Version expectedVersion)
        {
            var index = Substitute.For<IIndex<Version, Func<IWorkSiteManager>>>();
            var factory = new WorkSiteManagerFactory(index);

            factory.GetWorkSiteManager(new IManageSettings.SiteDatabaseSettings
            {
                IntegrationType = integrationType
            });

            index[expectedVersion].Received(1);
        }
        
        [Fact]
        public void ShouldReturnNullIfNotExpectedValue()
        {
            var integrationType = Fixture.String();
            var index = Substitute.For<IIndex<Version, Func<IWorkSiteManager>>>();
            var factory = new WorkSiteManagerFactory(index);

            var result = factory.GetWorkSiteManager(new IManageSettings.SiteDatabaseSettings
            {
                IntegrationType = integrationType
            });

            index[Arg.Any<Version>()].DidNotReceive();
            Assert.Null(result);
        }
    }
}