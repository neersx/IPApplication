using System;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions.Uspto.Tsdr;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class EnsureScheduleValidFacts : FactBase
    {
        readonly ITsdrSettings _tsdrSettings = Substitute.For<ITsdrSettings>();
        readonly int _savedQueryId = Fixture.Integer();
        readonly int _runAs = Fixture.Integer();

        [Fact]
        public async Task ThrowsExceptionIfApiKeyNotAvailable()
        {
            var tsdrSchedule = new Schedule
            {
                Id = 1,
                Name = "Schedule1",
                DataSourceType = DataSourceType.UsptoTsdr,
                ExtendedSettings = new JObject
                {
                    {"SavedQueryId", _savedQueryId},
                    {"RunAsUserId", _runAs}
                }.ToString()
            }.In(Db).GetExtendedSettings<TsdrSchedule>();

            _tsdrSettings.ApiKey.Returns((string) null);

            var subject = new EnsureScheduleValid(_tsdrSettings);

            var ex = await Assert.ThrowsAsync<Exception>(async () => await subject.ValidateRequiredSettings(tsdrSchedule));

            Assert.Equal("Exception", ex.GetType().Name);
            Assert.Equal("USPTO TSDR scheduled download requires API Key provided by the USPTO. Register for the API key from https://account.uspto.gov/api-manager", ex.Message);
        }

        [Fact]
        public async Task ThrowsExceptionIfQueryIdIsMissing()
        {
            var tsdrSchedule = new Schedule
            {
                Id = 1,
                Name = "Schedule1",
                DataSourceType = DataSourceType.UsptoTsdr,
                ExtendedSettings = new JObject
                {
                    {"SavedQueryId", null},
                    {"RunAsUserId", _runAs}
                }.ToString()
            }.In(Db).GetExtendedSettings<TsdrSchedule>();

            _tsdrSettings.ApiKey.Returns(Fixture.String());

            var subject = new EnsureScheduleValid(_tsdrSettings);

            var ex = await Assert.ThrowsAsync<InvalidOperationException>(async () => await subject.ValidateRequiredSettings(tsdrSchedule));

            Assert.Equal("InvalidOperationException", ex.GetType().Name);
            Assert.Equal("Saved query id is missing from schedule.", ex.Message);
        }

        [Fact]
        public async Task ThrowsExceptionIfRunAsUserIsMissing()
        {
            var tsdrSchedule = new Schedule
            {
                Id = 1,
                Name = "Schedule1",
                DataSourceType = DataSourceType.UsptoTsdr,
                ExtendedSettings = new JObject
                {
                    {"SavedQueryId", _savedQueryId},
                    {"RunAsUserId", null}
                }.ToString()
            }.In(Db).GetExtendedSettings<TsdrSchedule>();

            _tsdrSettings.ApiKey.Returns(Fixture.String());

            var subject = new EnsureScheduleValid(_tsdrSettings);

            var ex = await Assert.ThrowsAsync<InvalidOperationException>(async () => await subject.ValidateRequiredSettings(tsdrSchedule));

            Assert.Equal("InvalidOperationException", ex.GetType().Name);
            Assert.Equal("Run as user is missing from schedule.", ex.Message);
        }
    }
}