using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.ExchangeRateSchedule;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.ExchangeRateSchedule
{
    public class ExchangeRateScheduleServiceFacts
    {
        public class ExchangeRateScheduleServiceFixture : IFixture<ExchangeRateScheduleService>
        {
            public ExchangeRateScheduleServiceFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                Subject = new ExchangeRateScheduleService(db, PreferredCultureResolver);
            }

            public ISecurityContext SecurityContext { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ExchangeRateScheduleService Subject { get; set; }
        }

        public class GetExchangeRateSchedule : FactBase
        {
            [Fact]
            public async Task ReturnEmptyResultSetWhenNoData()
            {
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var results = (await f.Subject.GetExchangeRateSchedule()).ToArray();
                Assert.Empty(results);
            }

            [Fact]
            public async Task ReturnExchangeRateScheduleResultSet()
            {
                var e1 = new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = Fixture.String("AA"), Description = Fixture.String("AA")}.In(Db);
                new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = Fixture.String("BB"), Description = Fixture.String("BB")}.In(Db);
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var results = (await f.Subject.GetExchangeRateSchedule()).ToArray();
                Assert.Equal(2, results.Length);
                Assert.Equal(e1.ExchangeScheduleCode, results[0].Code);
            }
        }

        public class GetExchangeRateScheduleDetails : FactBase
        {
            [Fact]
            public async Task GetCurrencyDetails()
            {
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var e1 = new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = Fixture.String(), Description = "Code Abc"}.In(Db);
                var result = await f.Subject.GetExchangeRateScheduleDetails(e1.Id);
                Assert.Equal(e1.Id, result.Id);

                var result1 = await f.Subject.GetExchangeRateScheduleDetails(e1.Id);
                Assert.Equal(e1.ExchangeScheduleCode, result1.Code);
            }

            [Fact]
            public async Task ShouldThrowErrorWhenIdNotExist()
            {
                new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = Fixture.String(), Description = "Code Abc"}.In(Db);
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => { await f.Subject.GetExchangeRateScheduleDetails(0); });
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class SubmitExchangeRateSchedules : FactBase
        {
            [Fact]
            public async Task ShouldAddExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var e1 = new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = Fixture.String(), Description = Fixture.String()}.In(Db);

                var request = new ExchangeRateSchedulePicklistController.ExchangeRateSchedulePicklistItem
                {
                    Code = e1.ExchangeScheduleCode,
                    Description = Fixture.String()
                };

                var result = await f.Subject.SubmitExchangeRateSchedule(request);
                var k1 = Db.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().First(_ => _.ExchangeScheduleCode == result);

                Assert.Equal(request.Code, k1.ExchangeScheduleCode);
                Assert.Equal(e1.ExchangeScheduleCode, result);
            }

            [Fact]
            public async Task ShouldEditExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var e1 = new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = Fixture.String(), Description = Fixture.String()}.In(Db);
                var request = new ExchangeRateSchedulePicklistController.ExchangeRateSchedulePicklistItem
                {
                    Code = e1.ExchangeScheduleCode,
                    Description = Fixture.String()
                };

                var result = await f.Subject.SubmitExchangeRateSchedule(request);
                Assert.Equal(e1.ExchangeScheduleCode, result);
                Assert.Equal(request.Code, e1.ExchangeScheduleCode);
            }

            [Fact]
            public async Task ShouldThrowErrorWhenIdNoModelPassed()
            {
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.SubmitExchangeRateSchedule(null); });
                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class Delete : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorWhenIdNotExist()
            {
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.Delete(new DeleteRequestModel());
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldDeleteExchangeRateSchedule()
            {
                var f = new ExchangeRateScheduleServiceFixture(Db);
                var e1 = new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = "ABC" , Description = "ABC"}.In(Db);

                var result = await f.Subject.Delete(new DeleteRequestModel {Ids = new List<int> {e1.Id}});
                Assert.False(result.HasError);
            }
        }
    }
}