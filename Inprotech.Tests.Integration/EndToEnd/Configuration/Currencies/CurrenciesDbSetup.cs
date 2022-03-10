using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Currencies
{
    public class CurrenciesDbSetup : DbSetup
    {
        public dynamic SetupCurrencies()
        {
            var c1 = new CurrencyBuilder(DbContext).Create(Fixture.String(3)).Description = "Currency 1";
            var c2 = new CurrencyBuilder(DbContext).Create(Fixture.String(3)).Description = "Currency 2";
            var c3 = new CurrencyBuilder(DbContext).Create(Fixture.String(3)).Description = "Currency 3";
            new CurrencyBuilder(DbContext).Create("AAA").Description = "AAA Description";

            return new
            {
                c1,
                c2,
                c3
            };
        }

        public dynamic TotalCurrencyCount()
        {
            return new { count = DbContext.Set<Currency>().Count() };
        }
    }
}
