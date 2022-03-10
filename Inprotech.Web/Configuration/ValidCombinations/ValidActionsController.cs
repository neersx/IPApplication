using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.ModelBinding;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    [RoutePrefix("api/configuration/validcombination/action")]
    [Authorize]
    public class ValidActionsController : ApiController, IValidCombinationBulkController
    {
        readonly IDbContext _dbContext;
        readonly IValidActions _validActions;
        readonly ISimpleExcelExporter _excelExporter;

        static readonly CommonQueryParameters SortByParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
                                                     {
                                                         SortBy = "Country",
                                                         SortDir = "asc"
                                                     });

        public ValidActionsController(IDbContext dbContext, IValidActions validActions, ISimpleExcelExporter excelExporter)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _validActions = validActions ?? throw new ArgumentNullException(nameof(validActions));
            _excelExporter = excelExporter ?? throw new ArgumentNullException(nameof(excelExporter));
        }

        [HttpGet]
        [Route("search")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public PagedResults Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            return GetPagedResults(SearchValidAction(searchCriteria), SortByParameters.Extend(queryParameters));
        }

        [HttpGet]
        [Route("exportToExcel")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public HttpResponseMessage ExportToExcel(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] ValidCombinationSearchCriteria searchCriteria,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (queryParameters != null) queryParameters.Take = Int32.MaxValue;
            var data = GetPagedResults(SearchValidAction(searchCriteria), SortByParameters.Extend(queryParameters));

            return _excelExporter.Export(data, "Search Result.xlsx");
        }

        [HttpGet]
        [Route("validactions")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public ValidActionsOrderResponse ValidActions(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] ActionOrderCriteria actionOrderCriteria)
        {
            if(actionOrderCriteria == null) throw new ArgumentNullException("actionOrderCriteria");

            if(string.IsNullOrEmpty(actionOrderCriteria.Jurisdiction)
                    || string.IsNullOrEmpty(actionOrderCriteria.CaseType)
                    || string.IsNullOrEmpty(actionOrderCriteria.PropertyType))
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var filtered = _dbContext.Set<ValidAction>()
                                .Where(_ => _.CountryId == actionOrderCriteria.Jurisdiction
                                         && _.PropertyTypeId == actionOrderCriteria.PropertyType
                                         && _.CaseTypeId == actionOrderCriteria.CaseType);

            var response = new ValidActionsOrderResponse {OrderCriteria = actionOrderCriteria};

            var results = filtered.ToArray().OrderBy(_ => _.DisplaySequence).Select(_ => new ValidActionsOrder
                                                { 
                                                    Id = new ValidActionIdentifier(_.CountryId, _.PropertyTypeId, _.CaseTypeId, _.ActionId),
                                                    Code = _.ActionId,
                                                    Description = _.Action.Name,
                                                    Cycles = _.Action.NumberOfCyclesAllowed,
                                                    Renewal =
                                                        _.Action.ActionType.HasValue &&
                                                        _.Action.ActionType == 1m,
                                                    Examination =
                                                        _.Action.ActionType.HasValue &&
                                                        _.Action.ActionType == 2m,
                                                    DisplaySequence = _.DisplaySequence
                                                }).ToArray();

            response.ValidActions = results;
            return response;
        }

        [HttpPost]
        [Route("updateactionsequence")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic UpdateActionSequence(ValidActionsOrderResponse saveDetails)
        {
            if(saveDetails == null) throw new ArgumentNullException("saveDetails");

            if (saveDetails.OrderCriteria == null 
                    || string.IsNullOrEmpty(saveDetails.OrderCriteria.Jurisdiction)
                    || string.IsNullOrEmpty(saveDetails.OrderCriteria.CaseType)
                    || string.IsNullOrEmpty(saveDetails.OrderCriteria.PropertyType))
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            if (saveDetails.ValidActions == null || !saveDetails.ValidActions.Any())
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var filtered = _dbContext.Set<ValidAction>()
                                .Where(_ => _.CountryId == saveDetails.OrderCriteria.Jurisdiction
                                         && _.PropertyTypeId == saveDetails.OrderCriteria.PropertyType
                                         && _.CaseTypeId == saveDetails.OrderCriteria.CaseType).ToArray();

            if(filtered.Count() != saveDetails.ValidActions.Count())
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            foreach (var record in filtered)
            {
                var validAction = saveDetails.ValidActions.Single(_ => _.Code == record.ActionId);
                record.DisplaySequence = validAction.DisplaySequence;
            }

            _dbContext.SaveChanges();

            return new
                   {
                       Result = "success"
                   };
        }

        internal IQueryable<ValidAction> SearchValidAction(ValidCombinationSearchCriteria searchCriteria)
        {
            var result = _dbContext.Set<ValidAction>().AsQueryable();

            if (!string.IsNullOrEmpty(searchCriteria.PropertyType))
                result = result.Where(_ => _.PropertyTypeId == searchCriteria.PropertyType);

            if (!string.IsNullOrEmpty(searchCriteria.CaseType))
                result = result.Where(_ => _.CaseTypeId == searchCriteria.CaseType);

            if (!string.IsNullOrEmpty(searchCriteria.Action))
                result = result.Where(_ => _.ActionId == searchCriteria.Action);

            if (searchCriteria.Jurisdictions.Any())
                result = result.Where(_ => searchCriteria.Jurisdictions.Contains(_.Country.Id));

            return result;
        }

        internal PagedResults GetPagedResults(IQueryable<ValidAction> results, CommonQueryParameters queryParameters)
        {
            var total = results.Count();

            var executedResults =
                results.OrderByProperty(MapColumnName(queryParameters.SortBy),
                    queryParameters.SortDir)
                    .Skip(queryParameters.Skip.GetValueOrDefault())
                    .Take(queryParameters.Take.GetValueOrDefault());

            var data = executedResults
                .Include(_ => _.Country)
                .Include(_ => _.PropertyType)
                .Include(_ => _.CaseType)
                .Include(_ => _.Action)
                .ToArray()
                .Select(_ =>
                    new ValidActionRow
                        {
                            Id = new ValidActionIdentifier(_.CountryId, _.PropertyTypeId, _.CaseTypeId, _.ActionId),
                            Country = _.Country != null ? _.Country.Name : null,
                            PropertyType =
                                _.PropertyType != null ? _.PropertyType.Name : null,
                            CaseType = _.CaseType != null ? _.CaseType.Name : null,
                            Action = _.Action != null ? _.Action.Name : null,
                            ValidDescription = _.ActionName
                        }).ToArray();

            return new PagedResults(data, total);
        }

        static string MapColumnName(string name)
        {
            if (name == "validDescription")
                return "ActionName";

            return string.Format("{0}.{1}", name, "Name");
        }
        [HttpGet]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public dynamic ValidAction([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "entitykey")] ValidActionIdentifier validActionIdentifier)
        {
            var validAction = _validActions.GetValidAction(validActionIdentifier);
            return validAction ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Save(ActionSaveDetails actionSaveDetails)
        {
            return _validActions.Save(actionSaveDetails);
        }

        [HttpPut]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(ActionSaveDetails actionSaveDetails)
        {
            var result = _validActions.Update(actionSaveDetails);
            return result ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        [HttpPost]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        [NoEnrichment]
        public DeleteResponseModel<ValidActionIdentifier> Delete(ValidActionIdentifier[] deleteRequestModel)
        {
            var response = _validActions.Delete(deleteRequestModel);
            return response ?? throw new HttpResponseException(HttpStatusCode.NotFound);
        }

        public void Copy(CountryModel fromJurisdiction, CountryModel[] toJurisdictions)
        {
            if (fromJurisdiction == null) throw new ArgumentNullException("fromJurisdiction");
            if (toJurisdictions == null || !toJurisdictions.Any()) throw new ArgumentNullException("toJurisdictions");
            
            var validActions = _dbContext.Set<ValidAction>().Where(_ => _.Country.Id == fromJurisdiction.Code).ToArray();
            foreach (var jurisdiction in toJurisdictions)
            {
                foreach (var va in validActions.Where(va => !_dbContext.Set<ValidAction>()
                    .Any(_ => _.CountryId == jurisdiction.Code && _.PropertyTypeId == va.PropertyTypeId && _.CaseTypeId == va.CaseTypeId 
                        && _.ActionId == va.ActionId)))
                {

                    Save(new ActionSaveDetails
                    {
                       Jurisdictions = new[] { jurisdiction },
                       Action = new Picklists.Action(va.Action.Code, va.Action.Name),
                       ValidDescription = va.ActionName,
                       PropertyType = new Picklists.PropertyType(va.PropertyType.Code, va.PropertyType.Name),
                       CaseType = new Picklists.CaseType(va.CaseType.Code, va.CaseType.Name),
                       DeterminingEvent = va.DateOfLawEventNo.HasValue ? new Picklists.Event {Key = va.DateOfLawEventNo.Value} : null,
                       RetrospectiveEvent = va.RetrospectiveEventNo.HasValue ? new Picklists.Event {Key = va.RetrospectiveEventNo.Value} : null,
                       SkipDuplicateCheck = true
                    });
                    
                }
            }

            _dbContext.SaveChanges();
        }

        public class ActionOrderCriteria
        {
            public string Jurisdiction { get; set; }
            public string PropertyType { get; set; }
            public string CaseType { get; set; }
        }

        public class ValidActionsOrderResponse
        {
            public ValidActionsOrder[] ValidActions { get; set; }
            public ActionOrderCriteria OrderCriteria { get; set; }
        }

        public class ValidActionsOrder
        {
            private short? _cycles;
            public ValidActionIdentifier Id { get; set; }
            public string Code { get; set; }
            public string Description { get; set; }

            public short? Cycles
            {
                get { return _cycles.GetValueOrDefault(1); }
                set { _cycles = value; }
            }

            public bool Renewal { get; set; }
            public bool Examination { get; set; }
            public short? DisplaySequence { get; set; }
        }

        public class ValidActionRow
        {
            public ValidActionIdentifier Id { get; set; }

            [ExcelHeader("Case Type")]
            public string CaseType { get; set; }

            [ExcelHeader("Jurisdiction")]
            public string Country { get; set; }

            [ExcelHeader("Property Type")]
            public string PropertyType { get; set; }

            [ExcelHeader("Action")]
            public string Action { get; set; }

            [ExcelHeader("Valid Description")]
            public string ValidDescription { get; set; }
        }
    }
}
