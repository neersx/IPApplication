using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Configuration.DMSIntegration;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class SettingsControllerFacts : FactBase
    {
        public SettingsControllerFacts()
        {
            _settings = Substitute.For<IDmsIntegrationSettings>();
            _fileHelpers = Substitute.For<IFileHelpers>();
            _configureJob = Substitute.For<IConfigureJob>();
            _iMangeSettingsManager = Substitute.For<IIMangeSettingsManager>();
            var siteControls = Substitute.For<ISiteControlCache>();
            var settingTester = Substitute.For<ISettingTester>();
            _fileHelpers.DirectoryExists(null).ReturnsForAnyArgs(true);
            _fileHelpers.FilePathValid(null).ReturnsForAnyArgs(true);

            _controller = new SettingsController(_settings, _fileHelpers, _configureJob, _iMangeSettingsManager, Db, siteControls, settingTester);
        }

        readonly IDmsIntegrationSettings _settings;
        readonly SettingsController _controller;
        readonly IFileHelpers _fileHelpers;
        readonly IConfigureJob _configureJob;
        readonly IIMangeSettingsManager _iMangeSettingsManager;

        [Theory]
        [InlineData(DataSourceType.UsptoPrivatePair)]
        [InlineData(DataSourceType.UsptoTsdr)]
        public async Task ShouldBeAbleToEnableDms(DataSourceType dataSourceType)
        {
            await _controller.Update(new SettingsController.DmsModel
            {
                DataDownload = new[]
                {
                    new SettingsController.SettingsForDataSource
                    {
                        DataSource = dataSourceType,
                        IsEnabled = true,
                        Location = @"c:\",
                        Job = new SettingsController.SettingsForDataSourceJob()
                    }
                },
                IManageSettings = new IManageSettingsModel()
            });

            _settings.Received().SetEnabledFor(dataSourceType, true);
        }

        [Theory]
        [InlineData(DataSourceType.UsptoPrivatePair)]
        [InlineData(DataSourceType.UsptoTsdr)]
        public async Task ShouldBeAbleToDisableDms(DataSourceType dataSourceType)
        {
            await _controller.Update(new SettingsController.DmsModel
            {
                DataDownload = new[]
                {
                    new SettingsController.SettingsForDataSource
                    {
                        DataSource = dataSourceType,
                        IsEnabled = false,
                        Job = new SettingsController.SettingsForDataSourceJob()
                    }
                },
                IManageSettings = new IManageSettingsModel()
            });

            _settings.Received().SetEnabledFor(dataSourceType, false);
        }

        [Theory]
        [InlineData(DataSourceType.UsptoPrivatePair)]
        [InlineData(DataSourceType.UsptoTsdr)]
        public async Task ShouldBeAbleToChangeLocation(DataSourceType dataSourceType)
        {
            await _controller.Update(new SettingsController.DmsModel
            {
                DataDownload = new[]
                {
                    new SettingsController.SettingsForDataSource
                    {
                        DataSource = dataSourceType,
                        Location = "a",
                        Job = new SettingsController.SettingsForDataSourceJob()
                    }
                },
                IManageSettings = new IManageSettingsModel()
            });

            _settings.Received().SetLocationFor(dataSourceType, "a");
        }

        [Theory]
        [InlineData(DataSourceType.UsptoPrivatePair)]
        [InlineData(DataSourceType.UsptoTsdr)]
        public async Task ShouldRaiseExceptionIfPathIsInvalid(DataSourceType dataSourceType)
        {
            _fileHelpers.DirectoryExists(null).ReturnsForAnyArgs(false);

            var ex = await _controller.Update(new SettingsController.DmsModel
            {
                DataDownload = new[]
                {
                    new SettingsController.SettingsForDataSource
                    {
                        DataSource = dataSourceType,
                        IsEnabled = true,
                        Location = "a",
                        Job = new SettingsController.SettingsForDataSourceJob()
                    }
                },
                IManageSettings = new IManageSettingsModel()
            });

            Assert.Equal("Invalid" + dataSourceType + "Location", ex.Result.Error);
        }

        [Theory]
        [InlineData(DataSourceType.UsptoPrivatePair)]
        [InlineData(DataSourceType.UsptoTsdr)]
        public async Task ShouldReturnErrorIfFilePathIsNotValid(DataSourceType dataSourceType)
        {
            _fileHelpers.FilePathValid(null).ReturnsForAnyArgs(false);

            var ex = await _controller.Update(new SettingsController.DmsModel
            {
                DataDownload = new[]
                {
                    new SettingsController.SettingsForDataSource
                    {
                        DataSource = dataSourceType,
                        IsEnabled = true,
                        Location = "a",
                        Job = new SettingsController.SettingsForDataSourceJob()
                    }
                },
                IManageSettings = new IManageSettingsModel()
            });

            Assert.Equal("Invalid" + dataSourceType + "Location", ex.Result.Error);
        }
        
        [Fact]
        public async Task ShouldAcknowledgeJobStatusIfIntegrationDisabled()
        {
            await _controller.Update(new SettingsController.DmsModel
            {
                DataDownload = new[]
                {
                    new SettingsController.SettingsForDataSource
                    {
                        DataSource = DataSourceType.UsptoPrivatePair,
                        IsEnabled = false,
                        Job = new SettingsController.SettingsForDataSourceJob
                        {
                            JobExecutionId = 1
                        }
                    }
                },
                IManageSettings = new IManageSettingsModel()
            });

            _configureJob.Received(1).Acknowledge(1)
                         .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public void ShouldCallValidateUrl()
        {
            var validate = new SettingsController.ValidationModel {Url = Fixture.String()};
            var returnedValue = Fixture.Boolean();
            _iMangeSettingsManager.ValidateUrl(Arg.Any<string>(), Arg.Any<string>()).Returns(returnedValue);

            var response = _controller.ValidateUrl(validate);

            _iMangeSettingsManager.Received(1).ValidateUrl(validate.Url, validate.IntegrationType);
            Assert.Equal(returnedValue, response);
        }

        [Fact]
        public async Task ShouldNotAcknowledgeJobStatusWithNoJob()
        {
            await _controller.Update(new SettingsController.DmsModel
            {
                DataDownload = new[]
                {
                    new SettingsController.SettingsForDataSource
                    {
                        DataSource = DataSourceType.UsptoPrivatePair,
                        IsEnabled = false,
                        Job = new SettingsController.SettingsForDataSourceJob()
                    }
                },
                IManageSettings = new IManageSettingsModel()
            });

            _configureJob.DidNotReceiveWithAnyArgs().Acknowledge(1)
                         .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}