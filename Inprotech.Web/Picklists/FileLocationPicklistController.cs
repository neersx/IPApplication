using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/fileLocations")]
    public class FileLocationPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public FileLocationPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        public PagedResults<FileLocationPicklistItem> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();

            var results = from t in _dbContext.Set<TableCode>().Where(_ => _.TableTypeId == (short)TableTypes.FileLocation)
                          join o in _dbContext.Set<FileLocationOffice>() on t.Id equals o.FileLocationId into ot
                          from o in ot.DefaultIfEmpty()
                          select new
                          {
                              t.Id,
                              Name = DbFuncs.GetTranslation(t.Name, null, t.NameTId, culture),
                              OfficeName = o != null ? DbFuncs.GetTranslation(o.Office.Name, null, o.Office.NameTId, culture) : null,
                              t.UserCode
                          };

            if (!string.IsNullOrEmpty(search))
                results = results.Where(_ => _.Name.Contains(search) || _.OfficeName.Contains(search));

            results = results.OrderBy(_ => _.Name);

            return Helpers.GetPagedResults(results.Select(_ => new FileLocationPicklistItem
            {
                Key = _.Id,
                Value = _.Name,
                Office = _.OfficeName,
                UserCode = _.UserCode
            }),
                                           queryParameters,
                                           null, x => x.Value, search);
        }

        public class FileLocationPicklistItem
        {
            public int Key { get; set; }
            public string Value { get; set; }
            public string Office { get; set; }
            public string UserCode { get; set; }
        }
    }
}