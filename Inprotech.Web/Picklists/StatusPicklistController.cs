using System;
using System.ComponentModel;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/status")]
    public class StatusPicklistController : ApiController
    {
        readonly CommonQueryParameters _queryParameters;
        readonly ICaseStatuses _statuses;

        public StatusPicklistController(ICaseStatuses statuses)
        {
            _statuses = statuses ?? throw new ArgumentNullException(nameof(statuses));

            _queryParameters = new CommonQueryParameters { SortBy = "Value" };
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Status))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Status))]
        public PagedResults Statuses(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                = null, string search = "", string jurisdiction = "", string propertyType = "", string caseType = "", bool? isRenewal = null, bool isPending = false, bool isRegistered = false, bool isDead = false)
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var statuses = _statuses.Get(caseType,
                                         jurisdiction.AsArrayOrNull(),
                                         propertyType.AsArrayOrNull(),
                                         isRenewal, isPending, isRegistered, isDead);

            var result = statuses.Select(s => new Status(s.StatusKey, s.StatusDescription, s.IsRenewal)
            {
                IsDefaultJurisdiction = s is ValidStatusListItem item && item.IsDefaultCountry,
                IsPending = s.IsPending,
                IsDead = s.IsDead,
                IsRegistered = s.IsRegistered,
                IsConfirmationRequired = s.IsConfirmationRequired
            });

            if (!string.IsNullOrEmpty(search))
            {
                result = result.Where(s =>
                                            s.Code.ToString().Contains(search) ||
                                            s.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return Helpers.GetPagedResults(result, extendedQueryParams, null, x => x.Value, search);
        }

        [HttpGet]
        [Route("isvalid/{id}")]
        public dynamic IsValid(short id, string jurisdiction = "", string propertyType = "", string caseType = "", bool? isRenewal = null)
        {
            return new
            {
                Result = _statuses.IsValid(id, caseType,
                                       jurisdiction.AsArrayOrNull(),
                                       propertyType.AsArrayOrNull(),
                                       isRenewal)
            };
        }
    }

    public class Status
    {
        public Status()
        {
        }

        public Status(short code, string value)
        {
            Code = code;
            Value = value;
        }

        public Status(short code, string value, bool? isRenewal) : this(code, value)
        {
            Type = isRenewal.HasValue && isRenewal.Value
                ? StatusOptions.Renewal.ToString()
                : StatusOptions.Case.ToString();
        }

        [PicklistKey]
        public short Key => Code;

        [PicklistCode]
        [DisplayName(@"Code")]
        [DisplayOrder(1)]
        [PicklistColumn]
        public short Code { get; set; }

        [PicklistDescription]
        [DisplayOrder(0)]
        [PicklistColumn]
        public string Value { get; set; }

        [DisplayOrder(2)]
        [PicklistColumn]
        public string Type { get; set; }
        public bool IsDefaultJurisdiction { get; set; }

        public bool? IsPending { get; set; }
        public bool? IsDead { get; set; }
        public bool? IsRegistered { get; set; }
        public bool IsConfirmationRequired { get; set; }
    }

    public enum StatusOptions
    {
        Case,
        Renewal,
        All
    }
}