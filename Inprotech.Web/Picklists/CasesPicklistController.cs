using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using Inprotech.Web.Search.Case;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/cases")]
    public class CasesPicklistController : ApiController
    {
        protected readonly IListCase _listCase;
        protected readonly CommonQueryParameters _queryParameters;

        public CasesPicklistController(IListCase listCase)
        {
            _listCase = listCase;
            _queryParameters = CommonQueryParameters.Default.Extend(new CommonQueryParameters {SortBy = "Code"});
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Case))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Case))]
        public PagedResults Cases(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
            CommonQueryParameters queryParameters
                = null, string search = "", int? nameKey = null, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "searchFilter")] CaseSearchFilter searchFilter = null)
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            int rowCount;
            var cases = _listCase.Get(out rowCount, search, MapColumn(extendedQueryParams.SortBy), extendedQueryParams.SortDir, extendedQueryParams.Skip, extendedQueryParams.Take, nameKey, null, searchFilter);

            var result = cases.Select(c => new Case
            {
                Key = c.Id,
                Code = c.CaseRef,
                Value = c.Title,
                OfficialNumber = c.OfficialNumber,
                PropertyTypeDescription = c.PropertyTypeDescription,
                CountryName = c.CountryName
            });

            return new PagedResults(result, rowCount);
        }

        protected static string MapColumn(string column)
        {
            switch (column?.ToLower())
            {
                case "code":
                    return "CaseRef";
                case "value":
                    return "Title";
                default:
                    return column;
            }
        }
    }

    public class Case
    {
        [PicklistKey]
        public int Key { get; set; }

        // CaseRef has to be the first Description for it to display as the selected item in the pick list field.
        [Required]
        [DisplayName(@"CaseRef")]
        [DisplayOrder(0)]
        public string Code { get; set; }

        [DisplayName(@"Title")]
        [DisplayOrder(1)]
        public string Value { get; set; }

        public string OfficialNumber { get; set; }

        [DisplayName(@"PropertyType")]
        [DisplayOrder(2)]
        public string PropertyTypeDescription { get; set; }

        [DisplayName(@"Country")]
        [DisplayOrder(3)]
        public string CountryName { get; set; }

        [DisplayName(@"Instructor")]
        public string InstructorName { get; set; }

        [DisplayName(@"InstructorId")]
        public int? InstructorNameId { get; set; }
    }
}