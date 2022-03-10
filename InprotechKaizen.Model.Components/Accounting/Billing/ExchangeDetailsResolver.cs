using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;
using WipCategory = InprotechKaizen.Model.Accounting.Work.WipCategory;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public interface IExchangeDetailsResolver
    {
        Task<ExchangeDetails> Resolve(int userId,
                                      string currencyCode = null, string wipCategory = null, string wipTypeId = null,
                                      DateTime? transactionDate = null,
                                      int? caseId = null, int? nameId = null, bool? isSupplier = false,
                                      SystemIdentifier? systemIdentifier = SystemIdentifier.TimeAndBilling);
    }

    public class ExchangeDetailsResolver : IExchangeDetailsResolver
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IGetExchangeDetailsCommand _getExchangeDetailsCommand;
        readonly Func<DateTime> _now;

        public ExchangeDetailsResolver(IDbContext dbContext, ISiteControlReader siteControlReader, IGetExchangeDetailsCommand getExchangeDetailsCommand, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _getExchangeDetailsCommand = getExchangeDetailsCommand;
            _now = now;
        }

        public async Task<ExchangeDetails> Resolve(int userId,
                                                   string currencyCode = null, string wipCategory = null, string wipTypeId = null,
                                                   DateTime? transactionDate = null,
                                                   int? caseId = null, int? nameId = null, bool? isSupplier = false,
                                                   SystemIdentifier? systemIdentifier = SystemIdentifier.TimeAndBilling)
        {
            var settings = _siteControlReader.ReadMany<bool>(SiteControls.HistoricalExchRate, SiteControls.HistExchForOpenPeriod);

            var useHistoricalRates = await ResolveHistoricalRatesSetting(wipCategory, settings);

            var effectiveTransactionDate = await ResolveTransactionDate(transactionDate, systemIdentifier ?? SystemIdentifier.TimeAndBilling, settings);

            return await _getExchangeDetailsCommand.Run(userId, currencyCode, effectiveTransactionDate, useHistoricalRates,
                                                        caseId, nameId, isSupplier, wipTypeId);
        }
        
        async Task<DateTime?> ResolveTransactionDate(DateTime? transactionDate, SystemIdentifier systemIdentifier, Dictionary<string, bool> settings)
        {
            var effectiveTransactionDate = transactionDate ?? _now().Date;

            if (!settings.Get(SiteControls.HistExchForOpenPeriod))
            {
                return effectiveTransactionDate;
            }

            var openPeriodStart = await (from p in _dbContext.Set<Period>()
                                         where (p.ClosedForModules == null || (p.ClosedForModules & systemIdentifier) == systemIdentifier) &&
                                               p.EndDate.Date >= effectiveTransactionDate.Date &&
                                               p.PostingCommenced != null
                                         orderby p.Id
                                         select p.StartDate)
                .FirstOrDefaultAsync();

            return effectiveTransactionDate < openPeriodStart
                ? openPeriodStart
                : effectiveTransactionDate;
        }

        async Task<bool> ResolveHistoricalRatesSetting(string wipCategory, Dictionary<string, bool> settings)
        {
            return string.IsNullOrWhiteSpace(wipCategory)
                ? settings.Get(SiteControls.HistoricalExchRate)
                : await (from wc in _dbContext.Set<WipCategory>()
                         where wc.Id == wipCategory
                         select wc.HistoricalExchangeRate)
                    .SingleOrDefaultAsync() ?? false;
        }
    }

    public interface IGetExchangeDetailsCommand
    {
        Task<ExchangeDetails> Run(int userId, string currencyCode, DateTime? effectiveTransactionDate, bool useHistoricalRates, int? caseId, int? nameId, bool? isSupplier, string wipTypeId);
    }

    public class GetExchangeDetailsCommand : IGetExchangeDetailsCommand
    {
        readonly IDbContext _dbContext;

        public GetExchangeDetailsCommand(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<ExchangeDetails> Run(int userId, string currencyCode, DateTime? effectiveTransactionDate, bool useHistoricalRates, int? caseId, int? nameId, bool? isSupplier, string wipTypeId)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetExchangeDetails,
                                                                        new Parameters
                                                                        {
                                                                            { "@pnUserIdentityId", userId },
                                                                            { "@pnBankRate", null },
                                                                            { "@pnBuyRate", null },
                                                                            { "@pnSellRate", null },
                                                                            { "@pnDecimalPlaces", null },
                                                                            { "@pnRoundBilledValues", null },
                                                                            { "@psCurrencyCode", currencyCode },
                                                                            { "@pdtTransactionDate", effectiveTransactionDate },
                                                                            { "@pbUseHistoricalRates", useHistoricalRates },
                                                                            { "@pnCaseID", caseId },
                                                                            { "@pnNameNo", nameId },
                                                                            { "@pbIsSupplier", isSupplier },
                                                                            { "@psWIPTypeId", wipTypeId }
                                                                        });

            await command.ExecuteNonQueryAsync();

            return new ExchangeDetails
            {
                BankRate = command.Parameters["@pnBankRate"].GetValueOrDefault<decimal?>(),
                BuyRate = command.Parameters["@pnBuyRate"].GetValueOrDefault<decimal?>(),
                SellRate = command.Parameters["@pnSellRate"].GetValueOrDefault<decimal?>(),
                DecimalPlaces = command.Parameters["@pnDecimalPlaces"].GetValueOrDefault<byte>(),
                RoundBilledValues = command.Parameters["@pnRoundBilledValues"].GetValueOrDefault<short?>()
            };
        }
    }

    public class ExchangeDetails
    {
        public decimal? BankRate { get; set; }

        public decimal? BuyRate { get; set; }

        public decimal? SellRate { get; set; }

        public int DecimalPlaces { get; set; }

        public int? RoundBilledValues { get; set; }
    }
}
