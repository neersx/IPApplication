using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
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
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/propertyTypes")]
    public class PropertyTypesPicklistController : ApiController
    {
        readonly IPropertyTypes _propertyTypes;
        readonly CommonQueryParameters _queryParameters;
        readonly IPropertyTypesPicklistMaintenance _propertyTypeMaintenance;
        readonly IValidPropertyTypes _validPropertyTypes;

        public PropertyTypesPicklistController(IPropertyTypes propertyTypes, IPropertyTypesPicklistMaintenance propertyTypeMaintenance, IValidPropertyTypes validPropertyTypes)
        {
            _propertyTypes = propertyTypes ?? throw new ArgumentNullException(nameof(propertyTypes));
            _propertyTypeMaintenance = propertyTypeMaintenance ?? throw new ArgumentNullException(nameof(propertyTypeMaintenance));
            _validPropertyTypes = validPropertyTypes;

            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(PropertyType), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(PropertyType), ApplicationTask.MaintainValidCombinations, true)]
        public PagedResults PropertyTypes(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", string jurisdiction = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search, jurisdiction),
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("retrieve/{propertyTypeId}")]
        [PicklistPayload(typeof(PropertyType), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic PropertyType(string propertyTypeId)
        {
            var listItem = _propertyTypes.Get(propertyTypeId);
            return new PropertyType(listItem.Id, listItem.PropertyTypeKey, listItem.PropertyTypeDescription, listItem.AllowSubClass, listItem.CrmOnly, listItem.Image);
        }

        [HttpGet]
        [Route("{propertyTypeId}")]
        [PicklistPayload(typeof(PropertyType), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic PropertyType(int propertyTypeId)
        {
            var listItem = _propertyTypes.Get(propertyTypeId);
            return new PropertyType(listItem.Id, listItem.PropertyTypeKey, listItem.PropertyTypeDescription, listItem.AllowSubClass, listItem.CrmOnly, listItem.Image);
        }

        [HttpGet]
        [Route("{propertyTypeId}")]
        [PicklistPayload(typeof(PropertyType), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic PropertyType(int propertyTypeId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            var validPropertyIdentifier = GetValidPropertyIdentifier(_propertyTypes.Get(propertyTypeId).PropertyTypeKey, validCombinationKeys, isDefaultJurisdiction);
            var response = validPropertyIdentifier != null ? _validPropertyTypes.GetValidPropertyType(validPropertyIdentifier) : PropertyType(propertyTypeId);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        ValidPropertyIdentifier GetValidPropertyIdentifier(string propertyTypeId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            if (string.IsNullOrEmpty(validCombinationKeys)) return null;

            var vai = JsonConvert.DeserializeObject<ValidCombinationKeys>(validCombinationKeys);
            if (isDefaultJurisdiction)
            {
                vai.Jurisdiction = KnownValues.DefaultCountryCode;
            }
            return !string.IsNullOrEmpty(vai.Jurisdiction) ? new ValidPropertyIdentifier(vai.Jurisdiction, propertyTypeId) : null;
        }

        [HttpPut]
        [Route("{propertyTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(int propertyTypeId, [FromBody] JObject propertyType)
        {
            if (propertyType == null) throw new ArgumentNullException(nameof(propertyType));

            var response = propertyType["validDescription"] != null ? _validPropertyTypes.Update(propertyType.ToObject<PropertyTypeSaveDetails>())
                : _propertyTypeMaintenance.Save(propertyType.ToObject<PropertyType>(), Operation.Update);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate([FromBody] JObject propertyType)
        {
            if (propertyType == null) throw new ArgumentNullException(nameof(propertyType));

            if (propertyType["validDescription"] == null)
                return _propertyTypeMaintenance.Save(propertyType.ToObject<PropertyType>(), Operation.Add);

            var response = _validPropertyTypes.Save(propertyType.ToObject<PropertyTypeSaveDetails>());
            return response.Result != "Error" ? response : response.AsErrorResponse();
        }

        [HttpDelete]
        [Route("{propertyTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int propertyTypeId)
        {
            return _propertyTypeMaintenance.Delete(propertyTypeId);
        }

        [HttpDelete]
        [Route("{propertyTypeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int propertyTypeId, string deleteData)
        {
            var data = JsonConvert.DeserializeObject<JObject>(deleteData);
            if (data?["validCombinationKeys"] == null) return Delete(propertyTypeId);

            var validPropertyIdentifier = GetValidPropertyIdentifier(_propertyTypes.Get(propertyTypeId).PropertyTypeKey, data["validCombinationKeys"].ToString(), bool.Parse(data["isDefaultJurisdiction"].ToString()));
            var response = _validPropertyTypes.Delete(new[] { validPropertyIdentifier });
            if (response == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return response.HasError ? KnownSqlErrors.CannotDelete.AsHandled() : response;
        }

        IEnumerable<PropertyType> MatchingItems(string search = "", string jurisdiction = "")
        {
            var propertyTypes = _propertyTypes.GetPropertyTypes(jurisdiction.AsArrayOrNull());
            if (string.IsNullOrEmpty(jurisdiction))
            {
                var result = _propertyTypes.Get(propertyTypes.Select(_ => _.PropertyTypeKey).ToArray());
                var propertyTypeResult = result.Select(_ => new PropertyType(_.Id, _.PropertyTypeKey, _.PropertyTypeDescription, _.Image) { AllowSubClass = _.AllowSubClass });
                if (!string.IsNullOrEmpty(search))
                {
                    propertyTypeResult = propertyTypeResult.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                                                       _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
                }
                return propertyTypeResult;
            }
            else
            {
                var propertyTypeListItems = propertyTypes as PropertyTypeListItem[] ?? propertyTypes.ToArray();
                foreach (var propType in propertyTypeListItems)
                {
                    propType.Id = _propertyTypes.Get(new[] { propType.PropertyTypeKey }).First().Id;
                }
                var result = propertyTypeListItems.Select(_ => new PropertyType(_.Id, _.PropertyTypeKey, _.PropertyTypeDescription, _.Image) { IsDefaultJurisdiction = _.IsDefaultCountry == 1m, AllowSubClass = _.AllowSubClass });
                if (!string.IsNullOrEmpty(search))
                {
                    result = result.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                               _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
                }
                return result;
            }
        }
    }

    public class PropertyType
    {
        public PropertyType() { }

        public PropertyType(int id, string code, string description) : this(code, description)
        {
            Key = id;
        }

        public PropertyType(string code, string description)
        {
            Code = code;
            Value = description;
        }

        public PropertyType(int id, string code, string description, decimal allowSubClass, bool crmOnly, Image image) : this(id, code, description)
        {
            AllowSubClass = allowSubClass;
            CrmOnly = crmOnly;
            if (image == null) return;
            Image = image.Id;
            ImageData = new ImageModel
            {
                Key = image.Id,
                Image = image.ImageData,
                Description = image.Detail.ImageDescription
            };
        }

        public PropertyType(int id, string code, string description, Image image) : this(id, code, description)
        {
            Image = image?.Id;
        }

        [PicklistKey]
        public int Key { get; set; }

        [Required]
        [DisplayName(@"Code")]
        [PicklistCode]
        [MaxLength(1)]
        [DisplayOrder(1)]
        public string Code { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        [Required]
        public decimal AllowSubClass { get; set; }

        [DisplayName(@"Image")]
        [PicklistColumn(false)]
        public int? Image { get; set; }

        public ImageModel ImageData { get; set; }

        public bool CrmOnly { get; set; }

        public bool IsDefaultJurisdiction { get; set; }
    }
}
