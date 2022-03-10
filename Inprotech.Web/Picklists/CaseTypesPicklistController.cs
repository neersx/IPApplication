using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists.ResponseShaping;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/casetypes")]
    public class CaseTypesPicklistController : ApiController
    {
        readonly ICaseTypes _caseTypes;
        readonly ICaseTypesPicklistMaintenance _caseTypesPicklistMaintenance;
        readonly CommonQueryParameters _queryParameters;

        public CaseTypesPicklistController(ICaseTypes caseTypes, ICaseTypesPicklistMaintenance caseTypesPicklistMaintenance)
        {
            _caseTypes = caseTypes ?? throw new ArgumentNullException(nameof(caseTypes));
            _caseTypesPicklistMaintenance = caseTypesPicklistMaintenance ?? throw new ArgumentNullException(nameof(caseTypesPicklistMaintenance));

            _queryParameters = new CommonQueryParameters {SortBy = "Value"};
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof (CaseType), ApplicationTask.MaintainValidCombinations)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof (CaseType), ApplicationTask.MaintainValidCombinations)]
        public PagedResults CaseTypes(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var caseTypes = _caseTypes.GetCaseTypesWithDetails();

            if (!string.IsNullOrEmpty(search))
                caseTypes = caseTypes.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) || _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0);

            return Helpers.GetPagedResults(caseTypes,
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("actual")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public PagedResults ActualCaseTypes(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var caseTypes = _caseTypes.Get().Select(_ => new CaseType(_.Key, _.Value));

            if (!string.IsNullOrEmpty(search))
            {
                caseTypes = caseTypes.Where(_ => _.Value.StartsWith(search, StringComparison.InvariantCultureIgnoreCase));
            }

            return Helpers.GetPagedResults(caseTypes,
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("{caseTypeId}")]
        [PicklistPayload(typeof (CaseType), ApplicationTask.MaintainValidCombinations)]
        public dynamic Get(int caseTypeId)
        {
            return _caseTypes.GetCaseType(caseTypeId);
        }

        [HttpPut]
        [Route("{caseTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(int caseTypeId, CaseType caseType)
        {
            if (caseType == null) throw new ArgumentNullException(nameof(caseType));

            return _caseTypesPicklistMaintenance.Save(caseType, Operation.Update);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate(CaseType caseType)
        {
            if (caseType == null) throw new ArgumentNullException(nameof(caseType));

            return _caseTypesPicklistMaintenance.Save(caseType, Operation.Add);
        }

        [HttpDelete]
        [Route("{caseTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int caseTypeId)
        {
            return _caseTypesPicklistMaintenance.Delete(caseTypeId);
        }
    }

    public class CaseType
    {
        public CaseType()
        {
        }

        public CaseType(string code, string description)
        {
            Code = code;
            Value = description;
        }

        public CaseType(int id, string code, string description) : this(code, description)
        {
            Key = id;
        }

        [PicklistKey]
        public int Key { get; set; }

        [MaxLength(1)]
        [DisplayName(@"Code")]
        [Required]
        [PicklistCode]
        [DisplayOrder(1)]
        public string Code { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        public CaseType ActualCaseType { get; set; }
    }
}