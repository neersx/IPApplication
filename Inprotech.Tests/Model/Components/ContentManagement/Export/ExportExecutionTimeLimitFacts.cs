using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Profiles;
using Xunit;

namespace Inprotech.Tests.Model.Components.ContentManagement.Export
{
    public class ExportExecutionTimeLimitFacts : FactBase
    {
        public ExportExecutionTimeLimitFacts()
        {
            _exportExecutionTimeLimit = new ExportExecutionTimeLimit(Db);
            SetupData();
        }

        readonly IExportExecutionTimeLimit _exportExecutionTimeLimit;

        void SetupData()
        {
            new SettingDefinition
            {
                SettingId = KnownSettingIds.SearchReportGenerationTimeout,
                Name = "Search Reports generation timeout",
                Description = "Specify the time duration (in seconds) from initial request, for which to push the generation of exported Search Report to the background. Default value is 15. Maximum valid value is 90."
            }.In(Db);
            new SettingValues
            {
                SettingId = 34,
                IntegerValue = 15
            }.In(Db);
        }

        [Fact]
        public void ReturnIfTimeDoesNotLapse()
        {
            var r = _exportExecutionTimeLimit.IsLapsed(Fixture.Today().ToUniversalTime(),  Fixture.Today().AddSeconds(16).ToUniversalTime(), Fixture.String(string.Empty), Fixture.Integer());

            Assert.True(r);
        }

        [Fact]
        public void ReturnIfTimeLapsed()
        {
            var r = _exportExecutionTimeLimit.IsLapsed(Fixture.Today().AddSeconds(14).ToUniversalTime(),Fixture.Today().ToUniversalTime(), Fixture.String(string.Empty), Fixture.Integer());

            Assert.False(r);
        }

        [Fact]
        public void ReturnOnTime()
        {
            var r = _exportExecutionTimeLimit.IsLapsed(Fixture.Today().ToUniversalTime(),Fixture.Today().ToUniversalTime(), Fixture.String(string.Empty), Fixture.Integer());

            Assert.False(r);
        }
    }
}