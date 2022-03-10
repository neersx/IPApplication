using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    public class NameTypesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _defaultQueryParameters;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public NameTypesPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (preferredCultureResolver == null) throw new ArgumentNullException("preferredCultureResolver");

            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;

            _defaultQueryParameters = CommonQueryParameters.Default.Extend(new CommonQueryParameters { SortBy = "Value" });
        }

        [HttpGet]
        [Route("api/configuration/nametypepicklist")]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", bool usedByStaff = false)
        {
            var culture = _preferredCultureResolver.Resolve();
            var extendedQueryParams = _defaultQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            
            var nameTypes = _dbContext.Set<NameType>().AsQueryable();

            if(usedByStaff)
                nameTypes = nameTypes.StaffNames();

            var nameTypeModels =
                (from _ in nameTypes
                 select new NameTypeModel
                 {
                     Key = _.Id,
                     Code = _.NameTypeCode,
                     Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) ?? string.Empty
                 }).ToArray();

            var result = !string.IsNullOrWhiteSpace(search)
                ? nameTypeModels.Where(_ => _.Code.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 || _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1)
                : nameTypeModels;

            return Helpers.GetPagedResults(result,
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }
    }

    public class NameTypeModel
    {
        public NameTypeModel() {}

        public NameTypeModel(int key, string value, string code)
        {
            Key = key;
            Value = value;
            Code = code;
        }
        
        public int Key { get; set; }
       
        public string Code { get; set; }
 
        public string Value { get; set; }
    }
}
