using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.Documents;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Storage;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;
using Action = System.Action;
using Case = Inprotech.Integration.Case;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class IntegrationsStatusProviderFacts : FactBase
    {
        public IntegrationsStatusProviderFacts()
        {
            CryptoService = Substitute.For<ICryptoService>();
        }

        [Fact]
        public async Task ReturnsSchemaMappings()
        {
            var f = Subject();

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping().In(Db);
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping().In(Db);
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping().In(Db);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(3, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsSchemaMapping).Value));
        }

        [Fact]
        public async Task ReturnsVatSubmission()
        {
            var f = Subject();

            new VatReturn() { IsSubmitted = true, LastModified = Fixture.Today() }.In(Db);
            new VatReturn() { IsSubmitted = true, LastModified = Fixture.Today() }.In(Db);
            new VatReturn() { IsSubmitted = true, LastModified = Fixture.Today() }.In(Db);
            new VatReturn() { IsSubmitted = true, LastModified = Fixture.PastDate().AddDays(-1) }.In(Db);
            new VatReturn() { LastModified = Fixture.Today() }.In(Db);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(true.ToString(), r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsHmrcVatReturns).Value);
        }

        [Fact]
        public async Task FirstToFileEnabled()
        {
            var f = Subject();

            new ExternalSettings(KnownExternalSettings.FirstToFile) { IsComplete = true }.In(Db);
            var c = new Criteria() { RuleInUse = 1 }.In(Db);
            new TopicControl()
            {
                Name = KnownCaseScreenTopics.FirstToFile,
                WindowControl = new WindowControl(c.Id, Fixture.String())
            }.In(Db);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(true.ToString(), r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsFirstToFileView).Value);
        }

        [Fact]
        public async Task Ip1dData()
        {
            var f = Subject();

            void Loop(Action c, int count = 2)
            {
                for (int i = 0; i < count; i++)
                {
                    c();
                }
            }

            Loop(() => new CaseNotification() { Case = new Case() { Source = DataSourceType.UsptoPrivatePair }.In(Db), UpdatedOn = Fixture.Today() }.In(Db));
            new CaseNotification() { Case = new Case() { Source = DataSourceType.Epo }.In(Db), UpdatedOn = Fixture.Today() }.In(Db);

            Loop(() => new Document() { UpdatedOn = Fixture.Today(), Source = DataSourceType.File }.In(Db));
            new Document() { UpdatedOn = Fixture.Today(), Source = DataSourceType.IpOneData }.In(Db);

            Loop(() => new MessageStore() { MessageTimestamp = Fixture.Today(), ServiceType = "USPTO" }.In(Db), 5);
            new MessageStore() { MessageTimestamp = Fixture.Today(), ServiceType = "FILE" }.In(Db);

            Loop(() => SetupNewCase());
            Loop(() => SetupNewCase(KnownPropertyTypes.Design), 3);
            Loop(() => SetupNewCase(KnownPropertyTypes.TradeMark), 4);
            Loop(() => SetupNewCase(KnownPropertyTypes.Patent), 5);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(2, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsCasesPrefix + "USPTO.PrivatePAIR").Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsCasesPrefix + "EPO").Value));

            Assert.Equal(2, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsDocumentsPrefix + "FILE").Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsDocumentsPrefix + "IPOneData").Value));

            Assert.Equal(5, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIp1dServiceTypePrefix + "USPTO").Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIp1dServiceTypePrefix + "FILE").Value));

            Assert.Equal(2, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIp1dMatchedPrefix + "Others").Value));
            Assert.Equal(3, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIp1dMatchedPrefix + "Designs").Value));
            Assert.Equal(4, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIp1dMatchedPrefix + "Trademarks").Value));
            Assert.Equal(5, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIp1dMatchedPrefix + "Patents").Value));
        }

        [Fact]
        public async Task IManageData()
        {
            var f = Subject();

            new ExternalSettings(KnownExternalSettings.IManage) { IsComplete = true }.In(Db);
            CryptoService.Decrypt(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(new IManageSettings
            {
                Databases = new[]
                {
                    new IManageSettings.SiteDatabaseSettings(){IntegrationType = "API V1"},
                    new IManageSettings.SiteDatabaseSettings(){IntegrationType = "API V2"},
                },
                Disabled = false
            }));

            var c = new Criteria() { RuleInUse = 1 }.In(Db);
            new TopicControl()
            {
                Name = KnownCaseScreenTopics.Dms,
                WindowControl = new WindowControl(c.Id, Fixture.String())
            }.In(Db);

            new InprotechKaizen.Model.SchemaMappings.SchemaMapping().In(Db);
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping().In(Db);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();

            Assert.Equal(true.ToString(), r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIManageView).Value);
            Assert.Equal("API V1, API V2", r.Single(_ => _.Name == AnalyticsEventCategories.IntegrationsIManageType).Value);
        }

        IntegrationsStatusProvider Subject() => new IntegrationsStatusProvider(Db, Db, CryptoService);

        ICryptoService CryptoService { get; }

        int ToInt(string text) => Convert.ToInt32(text);

        void SetupNewCase(string propertyTypeId = null, int? caseId = null)
        {
            var @case = new CaseBuilder()
            {
                PropertyType = new PropertyType(propertyTypeId ?? Fixture.String(), Fixture.String()).In(Db)
            }.BuildWithId(caseId ?? Fixture.Integer()).In(Db);
            new CpaGlobalIdentifier() { CaseId = @case.Id, IsActive = true, LastChanged = Fixture.Today() }.In(Db);
        }
    }
}
