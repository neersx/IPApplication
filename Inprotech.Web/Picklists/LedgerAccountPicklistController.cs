using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/ledgerAccount")]
    public class LedgerAccountPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;

        public LedgerAccountPicklistController(IDbContext dbContext)
        {
            _dbContext = dbContext;
            _queryParameters = new CommonQueryParameters { SortBy = "Id" };
        }

        [HttpGet]
        [Route]
        public async Task<PagedResults<LedgerAccountPicklistItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var parentAccountIds = _dbContext.Set<LedgerAccount>().Where(_ => _.ParentAccountId != null).Select(_ => _.ParentAccountId).ToList();

            var ledgerAccount1 = _dbContext.Set<LedgerAccount>().Where(_ => !parentAccountIds.Contains(_.Id));
            var tableCodes = _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == (short)TableTypes.LedgerAccountType);
            var ledgerAccount2 = _dbContext.Set<LedgerAccount>();

            var query = search ?? string.Empty;

            var interimResult = from la1 in ledgerAccount1
                                    join tc in tableCodes on la1.AccountType equals tc.Id into ledgerAccountDetails
                                    from tcD in ledgerAccountDetails.DefaultIfEmpty()
                                    join la2 in ledgerAccount2 on la1.ParentAccountId equals la2.Id into ledgerAccount2Details
                                    from la2D in ledgerAccount2Details.DefaultIfEmpty()
                                    where la1.IsActive == 1 && ( la1.Description.ToLower().Contains(query) || la1.AccountCode.ToLower().Contains(query))
                                    select new LedgerAccountPicklistItem
                                    {
                                        Id = la1.Id,
                                        Code = la1.AccountCode,
                                        Description = la1.Description,
                                        AccountType = tcD == null ? null : tcD.Name,
                                        BudgetMovement = la1.BudgetMovement == 1 ? "Movement" : "Balance",
                                        ParentAccountCode = la2D == null ? null : la2D.AccountCode,
                                        ParentAccountDesc = la2D == null ? null : la2D.Description,
                                        DisburseToWip = la1.DisburseToWip == 1
                                    };

            var results = from r in await interimResult.ToArrayAsync()
                          let isContains = r.Code.IgnoreCaseContains(query) || r.Description.IgnoreCaseContains(query)
                          let isStartsWith = r.Code.IgnoreCaseStartsWith(query) || r.Description.IgnoreCaseStartsWith(query)
                          orderby isStartsWith descending, isContains descending
                          select new LedgerAccountPicklistItem
                          {
                              Id = r.Id,
                              Code = r.Code,
                              Description = r.Description,
                              AccountType = r.AccountType,
                              BudgetMovement = r.BudgetMovement,
                              ParentAccountCode = r.ParentAccountCode,
                              ParentAccountDesc = r.ParentAccountDesc,
                              DisburseToWip = r.DisburseToWip
                          };
            
            return Helpers.GetPagedResults(results,
                                           extendedQueryParams ?? new CommonQueryParameters(),
                                           x => x.Code, x => x.Description, search);
        }
        public class LedgerAccountPicklistItem
        {
            [PicklistKey]
            public int Id { get; set; }
            [PicklistCode]
            public string Code { get; set; }
            [PicklistDescription]
            public string Description { get; set; }
            public string AccountType { get; set; }
            public string ParentAccountCode { get; set; }
            public string ParentAccountDesc { get; set; }
            public bool DisburseToWip { get; set; }
            public string BudgetMovement { get; set; }
        }
    }
}