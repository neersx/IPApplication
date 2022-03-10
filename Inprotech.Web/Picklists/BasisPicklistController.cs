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
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/basis")]
    public class BasisPicklistController : ApiController
    {
        readonly IBasis _basis;
        readonly IBasisPicklistMaintenance _basisPicklistMaintenance;
        readonly CommonQueryParameters _queryParameters;
        readonly IValidBasisImp _validBasisImp;

        public BasisPicklistController(IBasis basis, IBasisPicklistMaintenance basisPicklistMaintenance, IValidBasisImp validBasisImp)
        {
            _basis = basis;
            _basisPicklistMaintenance = basisPicklistMaintenance;
            _validBasisImp = validBasisImp;

            _queryParameters = new CommonQueryParameters {SortBy = "Value"};
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Basis), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Basis), ApplicationTask.MaintainValidCombinations, true)]
        public PagedResults Basis(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", string caseType = "", string jurisdiction = "", string propertyType = "", string caseCategory = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search, caseType, jurisdiction, propertyType, caseCategory),
                                           extendedQueryParams,
                                           x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("{basisId}")]
        [PicklistPayload(typeof(Basis), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic BasisDetail(int basisId)
        {
            var basis = _basisPicklistMaintenance.Get(basisId);
            return basis;
        }

        [HttpGet]
        [Route("{basisId}")]
        [PicklistPayload(typeof(Basis), ApplicationTask.MaintainValidCombinations, true)]
        public dynamic BasisDetail(int basisId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            var validBasisIdentifier = GetValidBasisIdentifier(_basisPicklistMaintenance.Get(basisId).Code, validCombinationKeys, isDefaultJurisdiction);
            var response = validBasisIdentifier != null ? _validBasisImp.GetValidBasis(validBasisIdentifier) : BasisDetail(basisId);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        ValidBasisIdentifier GetValidBasisIdentifier(string basisId, string validCombinationKeys, bool isDefaultJurisdiction)
        {
            if (string.IsNullOrEmpty(validCombinationKeys)) return null;

            var vai = JsonConvert.DeserializeObject<ValidCombinationKeys>(validCombinationKeys);
            if (isDefaultJurisdiction)
            {
                vai.Jurisdiction = KnownValues.DefaultCountryCode;
            }
            return !string.IsNullOrEmpty(vai.Jurisdiction) ? new ValidBasisIdentifier(vai.Jurisdiction, vai.PropertyType, basisId, vai.CaseType, vai.CaseCategory) : null;
        }

        [HttpPut]
        [Route("{basisId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(string basisId, [FromBody] JObject basis)
        {
            if (basis == null) throw new ArgumentNullException(nameof(basis));

            var response = basis["validDescription"] != null ? _validBasisImp.Update(basis.ToObject<BasisSaveDetails>()) : _basisPicklistMaintenance.Save(basis.ToObject<Basis>(), Operation.Update);

            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate([FromBody] JObject basis)
        {
            if (basis == null) throw new ArgumentNullException(nameof(basis));

            if (basis["validDescription"] == null)
            {
                return _basisPicklistMaintenance.Save(basis.ToObject<Basis>(), Operation.Add);
            }

            var response = _validBasisImp.Save(basis.ToObject<BasisSaveDetails>());
            return response.Result != "Error" ? response : response.AsErrorResponse();
        }

        [HttpDelete]
        [Route("{basisId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int basisId)
        {
            return _basisPicklistMaintenance.Delete(basisId);
        }

        [HttpDelete]
        [Route("{basisId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(int basisId, string deleteData)
        {
            var data = JsonConvert.DeserializeObject<JObject>(deleteData);
            if (data?["validCombinationKeys"] == null) return Delete(basisId);

            var validBasisIdentifier = GetValidBasisIdentifier(_basisPicklistMaintenance.Get(basisId).Code, data["validCombinationKeys"].ToString(), bool.Parse(data["isDefaultJurisdiction"].ToString()));
            var response = _validBasisImp.Delete(new[] {validBasisIdentifier});
            if (response == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }
            return response.HasError ? KnownSqlErrors.CannotDelete.AsHandled() : response;
        }

        IEnumerable<Basis> MatchingItems(string search = "", string caseType = "", string jurisdiction = "", string propertyType = "", string caseCategory = "")
        {
            var bases = _basis.GetBasis(caseType, jurisdiction.AsArrayOrNull(), propertyType.AsArrayOrNull(), caseCategory.AsArrayOrNull());
            if (string.IsNullOrEmpty(jurisdiction))
            {
                var result = _basis.Get(bases.Select(_ => _.ApplicationBasisKey).ToArray());

                var basisResult = result.Select(_ => new Basis(_.Id, _.ApplicationBasisKey, _.ApplicationBasisDescription, _.Convention));

                if (!string.IsNullOrEmpty(search))
                {
                    basisResult = basisResult.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                                         _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
                }

                return basisResult;
            }
            else
            {
                var result = bases.ToArray()
                                  .Select(_ => new Basis(_basis.Get(_.ApplicationBasisKey).Id, _.ApplicationBasisKey, _.IsDefaultCountry, _.ApplicationBasisDescription));

                if (!string.IsNullOrEmpty(search))
                {
                    result = result.Where(_ => _.Code.Equals(search, StringComparison.InvariantCultureIgnoreCase) ||
                                               _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
                }

                return result;
            }
        }
    }

    public sealed class Basis
    {
        public Basis()
        {
        }

        public Basis(string code, string description)
        {
            Code = code;
            Value = description;
        }

        public Basis(int id, string code, string value, decimal convention) : this(code, value)
        {
            Key = id;
            Convention = convention == 1m;
        }

        public Basis(int id, string code, decimal isDefaultJurisdiction, string value) : this(code, value)
        {
            Key = id;
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

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        public bool Convention { get; set; }

        public bool IsDefaultJurisdiction { get; set; }
    }
}