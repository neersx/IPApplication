using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Names
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting/name")]
    public class NameBalancesController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IAccountingProvider _accountingProvider;
        readonly ISubjectSecurityProvider _subjectSecurity;

        public NameBalancesController(IDbContext dbContext, ISubjectSecurityProvider subjectSecurity, Func<DateTime> now, IAccountingProvider accountingProvider)
        {
            _dbContext = dbContext;
            _subjectSecurity = subjectSecurity;
            _now = now;
            _accountingProvider = accountingProvider;
        }

        [HttpGet]
        [Route("{nameId:int}/receivables")]
        [RequiresNameAuthorization]
        public async Task<dynamic> GetReceivables(int nameId)
        {
            if (!_subjectSecurity.HasAccessToSubject(ApplicationSubject.ReceivableItems)) return null;
            var now = _now();
            var closePostDate = now.AddDays(1);
            var receivables = from o in _dbContext.Set<OpenItem>()
                                     where o.Status != (short) TransactionStatus.Draft
                                           && o.AccountDebtorId == nameId
                                           && o.ItemDate <= now
                                           && o.ClosePostDate >= closePostDate
                                     select o.LocalBalance;

            var receivableBalance = (await receivables.DefaultIfEmpty().ToArrayAsync()).Sum();

            return new
                   {
                       Data = new
                              {
                                  ReceivableBalance = receivableBalance
                              }
                   };
        }

        [HttpGet]
        [Route("{nameId:int}/agedReceivableBalances")]
        [RequiresNameAuthorization]
        public async Task<dynamic> GetAgedReceivables(int nameId)
        {
            if (!_subjectSecurity.HasAccessToSubject(ApplicationSubject.ReceivableItems)) return null;
            var brackets = await _accountingProvider.GetAgeingBrackets();
            return await _accountingProvider.GetAgedReceivableTotals(nameId, brackets.BaseDate, brackets.Current, brackets.Previous, brackets.Last);
        }
    }
}