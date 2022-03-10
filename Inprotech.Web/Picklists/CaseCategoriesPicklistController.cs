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
using InprotechKaizen.Model.Components.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/caseCategories")]
    public class CaseCategoriesPicklistController : ApiController
    {
        readonly ICaseCategories _caseCategories;
        readonly ICaseCategoriesPicklistMaintenance _caseCategoriesPicklistMaintenance;
        readonly CommonQueryParameters _queryParameters;
        readonly IValidCategories _validCategories;
        readonly IMultipleClassApplicationCountries _multipleClassApplicationCountries;

        public CaseCategoriesPicklistController(ICaseCategories caseCategories,
                                                ICaseCategoriesPicklistMaintenance caseCategoriesPicklistMaintenance,
                                                IValidCategories validCategories,
                                                IMultipleClassApplicationCountries multipleClassApplicationCountries)
        {
            _caseCategories = caseCategories ?? throw new ArgumentNullException(nameof(caseCategories));
            _caseCategoriesPicklistMaintenance = caseCategoriesPicklistMaintenance ?? throw new ArgumentNullException(nameof(caseCategoriesPicklistMaintenance));
            _multipleClassApplicationCountries = multipleClassApplicationCountries ?? throw new ArgumentNullException(nameof(multipleClassApplicationCountries));

            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
            _validCategories = validCategories;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(CaseCategory), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route("multiclasscountries")]
        public IEnumerable<string> MultiClassApplicationCountries()
        {
            return _multipleClassApplicationCountries.Resolve().AsEnumerable();
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(CaseCategory), ApplicationTask.MaintainValidCombinations, true)]
        public PagedResults CaseCategories(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", string jurisdiction = "", string propertyType = "", string caseType = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search, jurisdiction, propertyType, caseType),
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("{caseCategoryId}")]
        [PicklistPayload(typeof(CaseCategory), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic CaseCategory(int caseCategoryId)
        {
            var listItem = _caseCategories.Get(caseCategoryId);
            return new CaseCategory(listItem.Id, listItem.CaseCategoryKey, listItem.CaseCategoryDescription)
                       {
                           CaseTypeDescription = listItem.CaseTypeDescription,
                           CaseTypeId = listItem.CaseTypeKey
                       };
        }

        [HttpGet]
        [Route("{caseCategoryCode}/{caseTypeKey}")]
        [PicklistPayload(typeof(CaseCategory), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic CaseCategory(string caseCategoryCode, string caseTypeKey)
        {
            var listItem = _caseCategories.Get(caseCategoryCode, caseTypeKey);
            return new CaseCategory(listItem.Id, listItem.CaseCategoryKey, listItem.CaseCategoryDescription)
            {
                CaseTypeDescription = listItem.CaseTypeDescription,
                CaseTypeId = listItem.CaseTypeKey
            };
        }

        [HttpGet]
        [Route("{caseCategoryId}")]
        [PicklistPayload(typeof(CaseCategory), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic CaseCategory(int caseCategoryId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            var validCategoryIdentifier = GetValidCategoryIdentifier(caseCategoryId, validCombinationKeys, isDefaultJurisdiction);
            var response = validCategoryIdentifier != null ? _validCategories.ValidCaseCategory(validCategoryIdentifier) : CaseCategory(caseCategoryId);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        ValidCategoryIdentifier GetValidCategoryIdentifier(int caseCategoryId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            if (string.IsNullOrEmpty(validCombinationKeys)) return null;

            var vai = JsonConvert.DeserializeObject<ValidCombinationKeys>(validCombinationKeys);
            if (isDefaultJurisdiction)
            {
                vai.Jurisdiction = KnownValues.DefaultCountryCode;
            }
            return !string.IsNullOrEmpty(vai.Jurisdiction) ? new ValidCategoryIdentifier(vai.Jurisdiction, vai.PropertyType, vai.CaseType , _caseCategories.Get(caseCategoryId).CaseCategoryKey) : null;
        }

        [HttpPut]
        [Route("{caseCategoryId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(int caseCategoryId, [FromBody] JObject caseCategory)
        {
            if (caseCategory == null) throw new ArgumentNullException(nameof(caseCategory));

            var response = caseCategory["validDescription"] != null ? _validCategories.Update(caseCategory.ToObject<CaseCategorySaveDetails>())
                : _caseCategoriesPicklistMaintenance.Save(caseCategory.ToObject<CaseCategory>(), Operation.Update);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate([FromBody] JObject caseCategory)
        {
            if (caseCategory == null) throw new ArgumentNullException(nameof(caseCategory));

            if (caseCategory["validDescription"] == null)
                return _caseCategoriesPicklistMaintenance.Save(caseCategory.ToObject<CaseCategory>(), Operation.Add);

            var response = _validCategories.Save(caseCategory.ToObject<CaseCategorySaveDetails>());
            return response.Result != "Error" ? response : response.AsErrorResponse();
        }

        [HttpDelete]
        [Route("{caseCategoryId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int caseCategoryId)
        {
            return _caseCategoriesPicklistMaintenance.Delete(caseCategoryId);
        }

        [HttpDelete]
        [Route("{caseCategoryId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int caseCategoryId, string deleteData)
        {
            var data = JsonConvert.DeserializeObject<JObject>(deleteData);
            if (data?["validCombinationKeys"] == null) return Delete(caseCategoryId);

            var validCategoryIdentifier = GetValidCategoryIdentifier(caseCategoryId, data["validCombinationKeys"].ToString(), bool.Parse(data["isDefaultJurisdiction"].ToString()));
            var response = _validCategories.Delete(new[] { validCategoryIdentifier });
            if (response == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            return response.HasError ? KnownSqlErrors.CannotDelete.AsHandled() : response;
        }

        IEnumerable<CaseCategory> MatchingItems(string search = "", string jurisdiction = "", string propertyType = "", string caseType = "")
        {
            var caseCategories = _caseCategories.GetCaseCategories(caseType, jurisdiction.AsArrayOrNull(), propertyType.AsArrayOrNull());

            var caseCategoryListItems = caseCategories as CaseCategoryListItem[] ?? caseCategories.ToArray();
            foreach (var caseCategory in caseCategoryListItems)
            {
                var caseCategoryItem = _caseCategories.Get(caseCategory.CaseCategoryKey, caseCategory.CaseTypeKey);
                caseCategory.Id = caseCategoryItem.Id;
                caseCategory.CaseTypeDescription = caseCategoryItem.CaseTypeDescription;
            }

            var result = caseCategoryListItems.Select(_ => new CaseCategory(_.Id, _.CaseCategoryKey, _.CaseCategoryDescription, _.IsDefaultCountry));

            if (!string.IsNullOrEmpty(search))
                result = result.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                           _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);

            return result;
        }
    }

    public sealed class CaseCategory
    {
        public CaseCategory() { }

        public CaseCategory(int id, string code, string description) : this(code, description)
        {
            Key = id;
        }

        public CaseCategory(string code, string description)
        {
            Code = code;
            Value = description;
        }

        public CaseCategory(int id, string code, string value, decimal isDefaultJurisdiction) : this(id, code, value)
        {
            IsDefaultJurisdiction = isDefaultJurisdiction == 1m;
        }

        [PicklistKey]
        public int Key { get; set; }

        [DisplayName(@"Code")]
        [PicklistCode]
        [MaxLength(2)]
        [DisplayOrder(1)]
        [Required]
        public string Code { get; set; }

        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        [Required]
        public string Value { get; set; }

        public string CaseTypeDescription { get; set; }

        public string CaseTypeId { get; set; }

        public bool IsDefaultJurisdiction { get; set; }
    }
}
