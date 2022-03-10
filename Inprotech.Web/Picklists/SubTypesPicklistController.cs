using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/subtypes")]
    public class SubTypesPicklistController : ApiController
    {
        readonly ISubTypes _subTypes;
        readonly CommonQueryParameters _queryParameters;
        readonly ISubTypesPicklistMaintenance _subTypesPicklistMaintenance;
        readonly IValidSubTypes _validSubTypes;

        public SubTypesPicklistController(ISubTypes subTypes, ISubTypesPicklistMaintenance subTypesPicklistMaintenance, IValidSubTypes validSubTypes)
        {
            _subTypes = subTypes ?? throw new ArgumentNullException(nameof(subTypes));
            _subTypesPicklistMaintenance = subTypesPicklistMaintenance ?? throw new ArgumentNullException(nameof(subTypesPicklistMaintenance));
            _validSubTypes = validSubTypes ?? throw new ArgumentNullException(nameof(validSubTypes));

            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(SubType), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(SubType), ApplicationTask.MaintainValidCombinations, true)]
        public PagedResults SubTypes([ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", string caseType = "", string jurisdiction = "", string propertyType = "",
            string caseCategory = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var subTypes = _subTypes.GetSubTypes(caseType, jurisdiction.AsArrayOrNull(), propertyType.AsArrayOrNull(),
                caseCategory.AsArrayOrNull());

            var result = subTypes.Select(s => new SubType(_subTypes.Get(s.SubTypeKey).Key, s.SubTypeKey, s.SubTypeDescription, s.IsDefaultCountry));

            if (!string.IsNullOrEmpty(search))
            {
                result = result.Where(_ => _.Code.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                           _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return Helpers.GetPagedResults(result, extendedQueryParams, x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("{subTypeId}")]
        [PicklistPayload(typeof(SubType), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Get(int subTypeId)
        {
            return _subTypesPicklistMaintenance.Get(subTypeId);
        }
        
        [HttpGet]
        [Route("{subTypeId}")]
        [PicklistPayload(typeof(SubType), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Get(int subTypeId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            var validSubTypeIdentifier = GetValidSubTypeIdentifier(_subTypesPicklistMaintenance.Get(subTypeId).Code, validCombinationKeys, isDefaultJurisdiction);
            var result = validSubTypeIdentifier != null ? _validSubTypes.GetValidSubType(validSubTypeIdentifier) : Get(subTypeId);
            return result ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPut]
        [Route("{subTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(int subTypeId, [FromBody] JObject subTypeSaveData)
        {
            if (subTypeSaveData == null) throw new ArgumentNullException(nameof(subTypeSaveData));

            var response = subTypeSaveData["validDescription"] != null ? _validSubTypes.Update(subTypeSaveData.ToObject<SubTypeSaveDetails>())
                : _subTypesPicklistMaintenance.Save(subTypeSaveData.ToObject<SubType>(), Operation.Update);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate([FromBody] JObject subTypeSaveData)
        {
            if (subTypeSaveData == null) throw new ArgumentNullException(nameof(subTypeSaveData));

            if (subTypeSaveData["validDescription"] == null)
                return _subTypesPicklistMaintenance.Save(subTypeSaveData.ToObject<SubType>(), Operation.Add);

            var response = _validSubTypes.Save(subTypeSaveData.ToObject<SubTypeSaveDetails>());
            return response.Result != "Error" ? response : response.AsErrorResponse();
        }

        [HttpDelete]
        [Route("{subTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int subTypeId)
        {
            return _subTypesPicklistMaintenance.Delete(subTypeId);
        }

        [HttpDelete]
        [Route("{subTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int subTypeId, string deleteData)
        {
            var data = JsonConvert.DeserializeObject<JObject>(deleteData);
            if (data?["validCombinationKeys"] == null) return Delete(subTypeId);

            var validSubTypeIdentifier = GetValidSubTypeIdentifier(_subTypesPicklistMaintenance.Get(subTypeId).Code, data["validCombinationKeys"].ToString(), bool.Parse(data["isDefaultJurisdiction"].ToString()));
            var response = _validSubTypes.Delete(new[] { validSubTypeIdentifier });
            if (response == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);
            return response.HasError ? KnownSqlErrors.CannotDelete.AsHandled() : response;
        }

        ValidSubTypeIdentifier GetValidSubTypeIdentifier(string subTypeId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            if (string.IsNullOrEmpty(validCombinationKeys)) return null;

            var vai = JsonConvert.DeserializeObject<ValidCombinationKeys>(validCombinationKeys);
            if (isDefaultJurisdiction)
            {
                vai.Jurisdiction = KnownValues.DefaultCountryCode;
            }
            if (!string.IsNullOrEmpty(vai.CaseType) && !string.IsNullOrEmpty(vai.PropertyType) && !string.IsNullOrEmpty(vai.Jurisdiction))
                return new ValidSubTypeIdentifier(vai.Jurisdiction, vai.PropertyType, vai.CaseType, vai.CaseCategory, subTypeId);

            return null;
        }
    }

    public class SubType
    {
        public SubType() { }

        public SubType(string code, string description)
        {
            Code = code;
            Value= description;
        }

        public SubType(int id, string code, string description) : this(code, description)
        {
            Key = id;
            Code = code;
            Value = description;
        }

        public SubType(int id, string code, string description, decimal isDefaultJurisdiction) : this (code, description)
        {
            Key = id;
            IsDefaultJurisdiction = isDefaultJurisdiction == 1m;
        }

        [PicklistKey]
        public int Key { get; set; }

        [Required]
        [DisplayName(@"Code")]
        [PicklistCode]
        [MaxLength(2)]
        [DisplayOrder(1)]
        public string Code { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        public bool IsDefaultJurisdiction { get; set; }
    }
}