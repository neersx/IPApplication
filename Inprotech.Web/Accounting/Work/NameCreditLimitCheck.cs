using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Work
{
    public interface INameCreditLimitCheck
    {
        Task<dynamic> For(int nameId);
    }

    public class NameCreditLimitCheck : INameCreditLimitCheck
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISiteControlReader _siteControlReader;

        public NameCreditLimitCheck(IDbContext dbContext, Func<DateTime> now, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _now = now;
            _siteControlReader = siteControlReader;
        }

        public async Task<dynamic> For(int nameId)
        {
            var limitPerc = _siteControlReader.Read<int?>(SiteControls.CreditLimitWarningPercentage);
            if (limitPerc.HasValue && limitPerc.Value == 0)
            {
                return null;
            }

            if (!limitPerc.HasValue || limitPerc.Value < 0)
            {
                limitPerc = 100;
            }

            var now = _now();
            var closePostDate = now.AddDays(1);
            var creditLimit = _dbContext.Set<ClientDetail>().Where(_ => _.Id == nameId && _.CreditLimit.HasValue).Select(_ => new {_.CreditLimit, _.Id});
            var receivables = await (from o in _dbContext.Set<OpenItem>()
                                     join c in creditLimit on o.AccountDebtorId equals c.Id
                                     where o.Status != (short) TransactionStatus.Draft
                                           && o.AccountDebtorId == nameId
                                           && o.ItemDate <= now
                                           && o.ClosePostDate >= closePostDate
                                     group new {o, c} by o.AccountDebtorId
                                     into balances
                                     select new
                                     {
                                         Id = balances.Key,
                                         ReceivableBalance = balances.Sum(_ => _.o.LocalBalance),
                                         balances.FirstOrDefault().c.CreditLimit
                                     }).SingleOrDefaultAsync();

            return new
            {
                receivables?.ReceivableBalance,
                receivables?.CreditLimit,
                Exceeded = receivables?.CreditLimit * limitPerc / 100 < receivables?.ReceivableBalance,
                LimitPercentage = limitPerc
            };
        }
    }
}