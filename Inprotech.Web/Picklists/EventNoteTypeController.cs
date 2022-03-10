using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/eventNoteType")]
    public class EventNoteTypeController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public EventNoteTypeController(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        public PagedResults Get([ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                                    = null, string search = "", string mode = "all", bool isExternal = false)
        {
            var culture = _preferredCultureResolver.Resolve();

            var result = _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventNoteType>().Where(e => (!isExternal) || e.IsExternal).ToArray().Select(_ => new EventNoteTypeModel()
            {
                Key = _.Id.ToString(),
                Value = DbFuncs.GetTranslation(string.Empty, _.Description, _.DescriptionTId, culture),
                IsExternal = _.IsExternal
            }).AsEnumerable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ =>
                                          string.Equals(_.Key, search, StringComparison.InvariantCultureIgnoreCase) ||
                                          _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return Helpers.GetPagedResults(result,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key, x => x.Value, search);
        }

        public EventNoteTypeModel[] GetEventNoteTypeByKeys(int[] keys)
        {
            if (keys == null)
            {
                return new EventNoteTypeModel[0];
            }

            var culture = _preferredCultureResolver.Resolve();
            return _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventNoteType>()
                             .Where(e => keys.Contains(e.Id)).ToArray()
                             .Select(_ => new EventNoteTypeModel()
                            {
                                Key = _.Id.ToString(),
                                Value = DbFuncs.GetTranslation(string.Empty, _.Description, _.DescriptionTId, culture),
                                IsExternal = _.IsExternal
                            }).ToArray();
        } 
    }

    public class EventNoteTypeModel
    {
        public EventNoteTypeModel() { }

        public EventNoteTypeModel(string key, string value, bool isExternal)
        {
            Key = key;
            Value = value;
            IsExternal = isExternal;
        }

        public string Key { get; set; }
        public string Value { get; set; }
        public bool IsExternal { get; set; }
    }
}
