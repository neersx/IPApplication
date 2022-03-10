using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Names.TrustAccounting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Names.Details
{
    public interface ITrustAccountingResolver
    {
        Task<ResultResponse> Resolve(int nameId, CommonQueryParameters reqParams);
        Task<ResultDetailResponse> Details(int nameId, int bankId, int bankSeqId, int entityId, CommonQueryParameters queryParameters);
    }

    public class TrustAccountingResolver : ITrustAccountingResolver
    {
        readonly string _culture;
        readonly ICommonQueryService _commonQueryService;
        readonly ITrustAccounting _trustAccounting;
        readonly IDbContext _dbContext;
        readonly INameAccessSecurity _nameAccessSecurity;
        public TrustAccountingResolver(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ITrustAccounting trustAccounting, ICommonQueryService commonQueryService, INameAccessSecurity nameAccessSecurity)
        {
            _trustAccounting = trustAccounting;
            _commonQueryService = commonQueryService;
            _dbContext = dbContext;
            _nameAccessSecurity = nameAccessSecurity;
            _culture = preferredCultureResolver.Resolve();
        }

        public async Task<ResultResponse> Resolve(int nameId, CommonQueryParameters reqParams)
        {
            if (nameId == 0) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var result = _trustAccounting.GetTrustAccountingData(nameId, _culture)
                                         .GroupBy(l => l.Id )
                                         .Select(ta => new TrustAccounts
                                         {
                                             Id = ta.First().Id,
                                             EntityKey = ta.First().EntityKey,
                                             Entity = ta.First().Entity,
                                             BankAccount = ta.First().BankAccount,
                                             LocalBalance = ta.Sum(b => b.LocalBalance),
                                             BankAccountNameKey = ta.First().BankAccountNameKey,
                                             BankAccountSeqKey = ta.First().BankAccountSeqKey,
                                             Currency = ta.First().Currency,
                                             ForeignBalance = ta.First().ForeignBalance,
                                             LocalCurrency = ta.First().LocalCurrency
                                         });

            var trustAccountingData = (from rt in result
                                      join n in _dbContext.Set<Name>() on rt.EntityKey equals n.Id
                                      orderby rt.Entity
                                      select new TrustAccountingData
                                      {
                                          Id = rt.Id,
                                          EntityKey = rt.EntityKey,
                                          Entity = rt.Entity,
                                          BankAccount = rt.BankAccount,
                                          LocalBalance = rt.LocalBalance,
                                          BankAccountNameKey = rt.BankAccountNameKey,
                                          BankAccountSeqKey = rt.BankAccountSeqKey,
                                          Currency = rt.Currency,
                                          ForeignBalance = rt.ForeignBalance,
                                          LocalCurrency = rt.LocalCurrency,
                                          CanViewEntity = _nameAccessSecurity.CanView(n)
                                      }).ToArray();
            var lbTotal = (from num in trustAccountingData
                           select num.LocalBalance).Sum();

            var resultResponse = new ResultResponse
            {
                TotalLocalBalance = lbTotal,
                Result = trustAccountingData.Any() ? new PagedResults(_commonQueryService.GetSortedPage(trustAccountingData, reqParams), trustAccountingData.Length) : new PagedResults(trustAccountingData, 0)
            };

            return resultResponse;
        }

        public async Task<ResultDetailResponse> Details(int nameId, int bankId, int bankSeqId, int entityId, CommonQueryParameters queryParameters)
        {
            if (queryParameters == null) throw new ArgumentNullException(nameof(CommonQueryParameters));

            var result = _trustAccounting.GetTrustAccountingDetails(nameId, bankId, bankSeqId, entityId, _culture).ToArray();
            var lbTotal = (from num in result
                           select num.LocalBalance).Sum();

            var lvTotal = (from num in result
                           select num.LocalValue).Sum();

            var resultResponse = new ResultDetailResponse
            {
                TotalLocalBalance = lbTotal,
                TotalLocalValue = lvTotal,
                Result = result.Any() ? new PagedResults(_commonQueryService.GetSortedPage(result, queryParameters), result.Length) : new PagedResults(result, 0)
            };
            return resultResponse;
        }
    }

    public class ResultRequestParams
    {
        public CommonQueryParameters Params { get; set; }
    }

    public class ResultResponse
    {
        public PagedResults Result { get; set; }
        public decimal? TotalLocalBalance { get; set; }
    }

    public class ResultDetailResponse
    {
        public PagedResults Result { get; set; }
        public decimal? TotalLocalBalance { get; set; }
        public decimal? TotalLocalValue { get; set; }
    }

    public class TrustAccountingData
    {
        public string Id { get; set; }
        public int EntityKey { get; set; }
        public string Entity { get; set; }
        public int BankAccountNameKey { get; set; }
        public int BankAccountSeqKey { get; set; }
        public string BankAccount { get; set; }
        public decimal? LocalBalance { get; set; }
        public decimal? ForeignBalance { get; set; }
        public string LocalCurrency { get; set; }
        public string Currency { get; set; }
        public bool CanViewEntity { get; set; }
    }
}
