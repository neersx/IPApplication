using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.ExchangeRateSchedule
{
    public class ExchangeRateScheduleDbSetup : DbSetup
    {
        public dynamic SetupExchangeRateSchedule()
        {
            var e1 = DbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Add(new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = "AAA" + Fixture.String(3), Description = Fixture.String(10)});
            var e2 = DbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Add(new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = "BBB" + Fixture.String(3), Description = Fixture.String(10)});
            var e3 = DbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Add(new InprotechKaizen.Model.Names.ExchangeRateSchedule {ExchangeScheduleCode = "CCC" + Fixture.String(3), Description = Fixture.String(10)});
            DbContext.SaveChanges();
            return new
            {
                e1,
                e2,
                e3
            };
        }

        public dynamic TotalExchangeRateScheduleCount()
        {
            return new { count = DbContext.Set<InprotechKaizen.Model.Names.ExchangeRateSchedule>().Count() };
        }
    }
}