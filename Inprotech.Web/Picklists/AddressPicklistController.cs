using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/address")]
    public class AddressPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ICommonQueryService _commonQueryService;
        readonly IFormattedNameAddressTelecom _formattedNameAddressTelecom;

        public AddressPicklistController(IDbContext dbContext, ICommonQueryService commonQueryService, IFormattedNameAddressTelecom formattedNameAddressTelecom)
        {
            _dbContext = dbContext;
            _commonQueryService = commonQueryService;
            _formattedNameAddressTelecom = formattedNameAddressTelecom;
        }

        [HttpGet]
        [Route]
        public async Task<PagedResults<AddressPicklistItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                    CommonQueryParameters queryParameters = null, string search = "", int? associatedNameId = null)
        {
            var results = _commonQueryService.Filter(await GetData(search, associatedNameId), queryParameters);

            return Helpers.GetPagedResults(results, queryParameters,x => x.Id.ToString(), x => x.Address, search);
        }
        public async Task<IEnumerable<AddressPicklistItem>> GetData(string search, int? associatedNameId = null)
        {
            var queryTokens = search?.Split('\r', '\n', ' ').Where(v => v != string.Empty).Select(_ => _.ToLower());

            var interimResult = from na in _dbContext.Set<NameAddress>()
                                join a in _dbContext.Set<Address>() on na.AddressId equals a.Id into addresses
                                from a in addresses.DefaultIfEmpty()
                                join t in _dbContext.Set<TableCode>() on na.AddressType equals t.Id into type
                                from t in type.DefaultIfEmpty()
                                where na.NameId == associatedNameId
                                select new
                                {
                                    Id = na.AddressId,
                                    Status = na.AddressStatusTableCode.Name,
                                    Address = a,
                                    AddressType = t
                                };
            var addressIds = interimResult.Select(_ => _.Id).Distinct().ToArray();
            var formattedAddresses = await _formattedNameAddressTelecom.GetAddressesFormatted(addressIds);

            IEnumerable<AddressPicklistItem> result;
            if (queryTokens == null)
            {
                result = from r in await interimResult.ToArrayAsync()
                         select new AddressPicklistItem
                         {
                             Id = r.Id,
                             Status = r.Status,
                             Address = formattedAddresses[r.Id].Address,
                             AddressType = r.AddressType.Name
                         };
            }
            else
            {
                result = from r in await interimResult.ToArrayAsync()
                         let address = formattedAddresses[r.Address.Id].Address
                         where queryTokens.All(address.ToLower().Contains)
                         select new AddressPicklistItem
                         {
                             Id = r.Id,
                             Status = r.Status,
                             Address = address,
                             AddressType = r.AddressType.Name
                         };
            }

            return result;
        }
    }

    public class AddressPicklistItem
    {
        [PicklistKey]
        public int Id { get; set; }
        [PicklistDescription]
        public string Address { get; set; }
        public string AddressType { get; set; }
        public string Status { get; set; }
    }
}
