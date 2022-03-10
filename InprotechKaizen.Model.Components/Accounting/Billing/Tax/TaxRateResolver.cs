using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.System.Compatibility;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Tax
{
    public interface ITaxRateResolver
    {
        Task<TaxRate> Resolve(int userIdentityId, string culture, string taxCode, int? staffId, int? entityId, DateTime? itemDate);
        Task<IEnumerable<TaxRate>> Resolve(int userIdentityId, string culture, int? staffId, int? entityId, DateTime? itemDate);
        Task<TaxRate> Resolve(int userIdentityId, string culture, string taxCode, string countryCode, int? staffId, int? entityId, DateTime? itemDate);
    }

    public class TaxRateResolver : ITaxRateResolver
    {
        readonly IDbContext _dbContext;
        readonly IStoredProcedureParameterHandler _compatibleParameterHandler;

        public TaxRateResolver(IDbContext dbContext, IStoredProcedureParameterHandler compatibilityHandler)
        {
            _dbContext = dbContext;
            _compatibleParameterHandler = compatibilityHandler;
        }

        public async Task<TaxRate> Resolve(int userIdentityId, string culture, string taxCode, int? staffId, int? entityId, DateTime? itemDate)
        {
            if (taxCode == null) throw new ArgumentNullException(nameof(taxCode));

            return (await ResolveAll(userIdentityId, culture, taxCode, staffId, entityId, itemDate))
                .SingleOrDefault();
        }

        public async Task<TaxRate> Resolve(int userIdentityId, string culture, string taxCode, string countryCode, int? staffId, int? entityId, DateTime? itemDate)
        {
            if (taxCode == null) throw new ArgumentNullException(nameof(taxCode));

            return await ResolveEffective(userIdentityId, culture, taxCode, countryCode, staffId, entityId, itemDate);
        }

        public async Task<IEnumerable<TaxRate>> Resolve(int userIdentityId, string culture, int? staffId, int? entityId, DateTime? itemDate)
        {
            return await ResolveAll(userIdentityId, culture, null, staffId, entityId, itemDate);
        }

        async Task<IEnumerable<TaxRate>> ResolveAll(int userIdentityId, string culture, string taxCode, int? staffId, int? entityId, DateTime? itemDate)
        {
            var parameters = new Parameters
            {
                { "@pnUserIdentityId", userIdentityId },
                { "@psCulture", culture },
                { "@psTaxCode", taxCode },
                { "@pnStaffKey", staffId },
                { "@pnEntityKey", entityId },
                { "@pdtItemDate", itemDate }
            };

            _compatibleParameterHandler.Handle(StoredProcedures.Billing.GetTaxRate, parameters);

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetTaxRate, parameters);

            using var dr = await command.ExecuteReaderAsync();

            var taxRates = new List<TaxRate>();

            var hasTaxCode = !string.IsNullOrWhiteSpace(taxCode);

            while (await dr.ReadAsync())
            {
                taxRates.Add(new TaxRate
                {
                    Code = hasTaxCode ? taxCode : dr.GetField<string>("TaxCode"),
                    Description = hasTaxCode ? null : dr.GetField<string>("TaxDescription"),
                    Rate = dr.GetField<decimal>("TaxRate")
                });
            }

            return taxRates;
        }

        async Task<TaxRate> ResolveEffective(int userIdentityId, string culture, string taxCode, string countryCode, int? staffId, int? entityId, DateTime? itemDate)
        {
            var parameters = new Parameters
            {
                { "@pnUserIdentityId", userIdentityId },
                { "@psCulture", culture },
                { "@psTaxCode", taxCode },
                { "@psCountryCode", countryCode },
                { "@pnStaffKey", staffId },
                { "@pnEntityKey", entityId },
                { "@pdtTransDate", itemDate }
            };

            _compatibleParameterHandler.Handle(StoredProcedures.Billing.GetEffectiveTaxRate, parameters);

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetEffectiveTaxRate, parameters);

            var rate = await command.ExecuteScalarAsync() as decimal?;

            return new TaxRate
            {
                Code = taxCode,
                Rate = rate.GetValueOrDefault()
            };
        }
    }

    public class TaxRate
    {
        public string Code { get; set; }

        public string Description { get; set; }

        public decimal Rate { get; set; }
    }
}
