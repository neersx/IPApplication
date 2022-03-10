using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.DMSIntegration;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.DMSIntegration
{
    public class SettingsViewControllerFacts
    {
        static JobStatus BuildStatus()
        {
            return new JobStatus
            {
                State = JObject.FromObject(new
                {
                    Acknowledged = true,
                    TotalDocuments = 1,
                    SentDocuments = 2
                })
            };
        }

        public class SettingsViewInitialViewDataFacts : FactBase
        {
            public SettingsViewInitialViewDataFacts()
            {
                var job1 = BuildStatus();
                var job2 = BuildStatus();

                _fixture = new SettingsViewControllerFixture(Db)
                           .WithJob(DataSourceHelper.PrivatePairJobType, job1)
                           .WithJob(DataSourceHelper.TsdrJobType, job2)
                           .WithIManageSettings();
            }

            readonly SettingsViewControllerFixture _fixture;

            [Fact]
            public async Task ShouldFillNameTypes()
            {
                var nameType1 = new NameType(Fixture.String(), Fixture.String()).In(Db);
                var nameType2 = new NameType(Fixture.String(), Fixture.String()).In(Db);
                var nameType3 = new NameType(Fixture.String(), Fixture.String()).In(Db);
                var settings = new IManageSettingsModel
                {
                    NameTypes = new[]
                    {
                        new IManageSettingsModel.NameSettings {NameType = nameType1.NameTypeCode},
                        new IManageSettingsModel.NameSettings {NameType = nameType2.NameTypeCode},
                        new IManageSettingsModel.NameSettings {NameType = $"{nameType1.NameTypeCode},{nameType2.NameTypeCode}"},
                        new IManageSettingsModel.NameSettings {NameType = $"{nameType1.NameTypeCode},{nameType2.NameTypeCode},{nameType3.NameTypeCode}"}
                    }
                };
                _fixture.WithIManageSettings(settings);

                var viewData = (await _fixture.Subject.Get()).ViewData;

                var imanage = viewData.IManage as IManageSettingsModel;
                Assert.NotNull(imanage?.NameTypes);
                Assert.Equal(4, imanage.NameTypes.Count());
                Assert.Equal(2, imanage.NameTypes.Count(_ => _.NameTypePicklist.Count == 1));
                Assert.Equal(1, imanage.NameTypes.Count(_ => _.NameTypePicklist.Count == 2));
                Assert.Equal(1, imanage.NameTypes.Count(_ => _.NameTypePicklist.Count == 3));
            }

            [Fact]
            public async Task ShouldReturnDataItem()
            {
                var searchDocItemName = "caseSearch";
                var nameDocItemName = "nameSearch";
                _fixture.WithSiteControl(SiteControls.DMSCaseSearchDocItem, searchDocItemName)
                        .WithDataItem(searchDocItemName);
                _fixture.WithSiteControl(SiteControls.DMSNameSearchDocItem, nameDocItemName)
                        .WithDataItem(nameDocItemName);
                var viewData = (await _fixture.Subject.Get()).ViewData;

                var imanage = viewData.IManage as IManageSettingsModel;
                Assert.NotNull(imanage?.DataItems?.CaseSearch);
                Assert.Equal(searchDocItemName, imanage?.DataItems?.CaseSearch?.Code);
                Assert.NotNull(imanage?.DataItems?.NameSearch);
                Assert.Equal(nameDocItemName, imanage?.DataItems?.NameSearch?.Code);
            }

            [Fact]
            public async Task ShouldReturnSettings()
            {
                var r = (await _fixture
                               .WithSettings("a:\\abc", "c:\\abc", true, true).Subject.Get()).ViewData.DataDownload;

                Assert.Equal("UsptoPrivatePair", r[0].DataSource);
                Assert.Equal("1", r[0].Location);
                Assert.Equal(true, r[0].IsEnabled);
                Assert.Equal("UsptoTsdr", r[1].DataSource);
                Assert.Equal("2", r[1].Location);
                Assert.Equal(true, r[1].IsEnabled);
            }
        }

        public class SettingsViewGetDataDownloadFacts : FactBase
        {
            public SettingsViewGetDataDownloadFacts()
            {
                var job1 = BuildStatus();
                var job2 = BuildStatus();

                _fixture = new SettingsViewControllerFixture(Db)
                           .WithJob(DataSourceHelper.PrivatePairJobType, job1)
                           .WithJob(DataSourceHelper.TsdrJobType, job2)
                           .WithIManageSettings();
            }

            readonly SettingsViewControllerFixture _fixture;

            [Fact]
            public async Task ShouldReturnActualJobStatusWhenCalled()
            {
                var jobStatus = new JobStatus
                {
                    Status = "Completed",
                    State = new JObject()
                };

                _fixture.WithJob(DataSourceHelper.PrivatePairJobType, jobStatus);
                var r = (await _fixture.Subject.GetDataDownload((int) DataSourceType.UsptoPrivatePair)).DataDownload;
                Assert.Equal("Completed", r.Job.Status);
            }

            [Fact]
            public async Task ShouldReturnDocuments()
            {
                await _fixture
                      .WithDocuments(DataSourceType.UsptoPrivatePair, 1)
                      .WithDocuments(DataSourceType.UsptoTsdr, 2)
                      .Subject.Get();

                var data = (await _fixture.Subject.GetDataDownload((int) DataSourceType.UsptoPrivatePair)).DataDownload;
                Assert.Equal(1, data.Documents);
                var data2 = (await _fixture.Subject.GetDataDownload((int) DataSourceType.UsptoTsdr)).DataDownload;
                Assert.Equal(2, data2.Documents);
            }

            [Fact]
            public async Task ShouldReturnFailedJobStatusWhenCompletedHasErrors()
            {
                var jobStatus = new JobStatus
                {
                    Status = "Completed",
                    HasErrors = true,
                    State = new JObject()
                };

                _fixture.WithJob(DataSourceHelper.PrivatePairJobType, jobStatus);
                var r = (await _fixture.Subject.GetDataDownload((int) DataSourceType.UsptoPrivatePair)).DataDownload;

                Assert.Equal("Failed", r.Job.Status);
            }

            [Fact]
            public async Task ShouldReturnIdleJobStatusWhenAcknowledged()
            {
                var jobStatus = new JobStatus
                {
                    State = JObject.FromObject(new
                    {
                        Acknowledged = true
                    })
                };

                _fixture.WithJob(DataSourceHelper.PrivatePairJobType, jobStatus);
                var r = (await _fixture.Subject.GetDataDownload((int) DataSourceType.UsptoPrivatePair)).DataDownload;

                Assert.Equal("Idle", r.Job.Status);
            }

            [Fact]
            public async Task ShouldReturnIdleJobStatusWhenNull()
            {
                _fixture.WithJob(DataSourceHelper.PrivatePairJobType, new JobStatus {State = new JObject()});
                var r = (await _fixture.Subject.GetDataDownload((int) DataSourceType.UsptoPrivatePair)).DataDownload;

                Assert.Equal("Idle", r.Job.Status);
            }

            [Fact]
            public async Task ShouldReturnStartedJobStatusWhenIsActive()
            {
                var jobStatus = new JobStatus
                {
                    IsActive = true,
                    State = new JObject()
                };

                _fixture.WithJob(DataSourceHelper.PrivatePairJobType, jobStatus);
                var r = (await _fixture.Subject.GetDataDownload((int) DataSourceType.UsptoPrivatePair)).DataDownload;

                Assert.Equal("Started", r.Job.Status);
            }
        }
    }

    public class SettingsViewControllerFixture : IFixture<SettingsViewController>
    {
        public SettingsViewControllerFixture(InMemoryDbContext db)
        {
            Settings = Substitute.For<IDmsIntegrationSettings>();
            ConfigureJob = Substitute.For<IConfigureJob>();
            DocumentLoader = Substitute.For<IDocumentLoader>();
            IMangeSettingsManager = Substitute.For<IIMangeSettingsManager>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Db = db;
            Subject = new SettingsViewController(Settings, ConfigureJob, DocumentLoader, IMangeSettingsManager, SiteControlReader, db, PreferredCultureResolver);
        }

        public IDocumentLoader DocumentLoader { get; set; }

        public IDmsIntegrationSettings Settings { get; set; }

        public IConfigureJob ConfigureJob { get; set; }

        public IIMangeSettingsManager IMangeSettingsManager { get; set; }

        public ISiteControlReader SiteControlReader { get; set; }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public InMemoryDbContext Db { get; set; }

        public SettingsViewController Subject { get; set; }

        public SettingsViewControllerFixture WithSettings(string ppLocation, string tsdrLocation, bool ppEnabled,
                                                          bool tsdrEnabled)
        {
            Settings.PrivatePairLocation.Returns("1");
            Settings.GetLocationFor(DataSourceType.UsptoPrivatePair).Returns("1");
            Settings.TsdrLocation.Returns("2");
            Settings.GetLocationFor(DataSourceType.UsptoTsdr).Returns("2");
            Settings.PrivatePairIntegrationEnabled.Returns(true);
            Settings.IsEnabledFor(DataSourceType.UsptoPrivatePair).Returns(true);
            Settings.TsdrIntegrationEnabled.Returns(true);
            Settings.IsEnabledFor(DataSourceType.UsptoTsdr).Returns(true);

            return this;
        }

        public SettingsViewControllerFixture WithJob(string job, JobStatus jobStatus)
        {
            ConfigureJob.GetJobStatus(job).Returns(jobStatus);

            return this;
        }

        public SettingsViewControllerFixture WithDocuments(DataSourceType dataSource, int count)
        {
            DocumentLoader.CountDocumentsFromSource(dataSource).Returns(count);

            return this;
        }

        public SettingsViewControllerFixture WithIManageSettings(IManageSettingsModel iManageSettings = null)
        {
            IMangeSettingsManager.Resolve().Returns(iManageSettings ?? new IManageSettingsModel());

            return this;
        }

        public SettingsViewControllerFixture WithSiteControl<T>(string siteControl, T value)
        {
            SiteControlReader.Read<T>(siteControl).Returns(value);

            return this;
        }

        public SettingsViewControllerFixture WithDataItem(string name)
        {
            new DocItem {Name = name}.In(Db);

            return this;
        }
    }
}