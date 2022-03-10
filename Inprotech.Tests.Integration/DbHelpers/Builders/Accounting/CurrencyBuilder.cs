using System;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders.Accounting
{
    internal class CurrencyBuilder : Builder
    {
        public CurrencyBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public Currency Create(string code = null, decimal? buyRate = (decimal) 1.00, decimal? sellRate = (decimal) 1.00)
        {
            return Insert(new Currency
            {
                Id = GetOrCreateCurrencyCode(code),
                Description = code + " Currency",
                BuyRate = buyRate,
                SellRate = sellRate,
                BuyFactor = 1,
                SellFactor = 1,
                DateChanged = DateTime.Now
            });
        }

        static string GetOrCreateCurrencyCode(string code = null)
        {
            if (code == null) return Fixture.AlphaNumericString(3);
            if (code.Length > 3) code = code.Substring(0, 3);
            return code;
        }
    }
}