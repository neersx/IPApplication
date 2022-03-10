using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;
using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/recordalTypes")]
    public class RecordalTypePicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly CommonQueryParameters _queryParameters;

        public RecordalTypePicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _queryParameters = new CommonQueryParameters {SortBy = "Value"};
        }
        
        [HttpGet]
        [Route]
        [PicklistPayload(typeof (RecordalTypePicklistItem))]
        public PagedResults RecordalTypes(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));
            var culture = _preferredCultureResolver.Resolve();

            var recordalTypes = _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>()
                                          .Select(_ => new RecordalTypePicklistItem
                                          {
                                              Key = _.Id,
                                              Value = _.RecordalTypeName,
                                              RecordEvent = _.RecordEvent != null ? DbFuncs.GetTranslation(_.RecordEvent.Description, null, _.RecordEvent.DescriptionTId, culture) : null,
                                              RequestEvent = _.RequestEvent != null ? DbFuncs.GetTranslation(_.RequestEvent.Description, null, _.RequestEvent.DescriptionTId, culture) : null
                                          }).AsEnumerable();          

            if (!string.IsNullOrEmpty(search))
            {
                recordalTypes = recordalTypes.Where(_ => _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 
                                                         || _.RecordEvent?.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 
                                                         || _.RequestEvent?.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            recordalTypes = recordalTypes.OrderBy(_ => _.Key);

            return Helpers.GetPagedResults(recordalTypes,
                                           extendedQueryParams, null,
                                           x => x.Value, search);
        }
    }

    public class RecordalTypePicklistItem
    {
        [PicklistKey]
        public int Key { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        [DisplayName("RequestEvent")]
        public string RequestEvent { get; set; }

        [DisplayName("RecordEvent")]
        public string RecordEvent { get; set; }
    }
}
