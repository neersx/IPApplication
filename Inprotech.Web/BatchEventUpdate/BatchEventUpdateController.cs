using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.DependencyInjection;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.TempStorage;
using Newtonsoft.Json.Linq;
using Resources = Inprotech.Web.Properties.Resources;

namespace Inprotech.Web.BatchEventUpdate
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BatchEventUpdate)]
    [UseDefaultContractResolver]
    public class BatchEventUpdateController : ApiController
    {
        readonly IBatchEventsModelBuilder _batchEventsModelBuilder;
        readonly ICaseAuthorization _caseAuthorization;

        readonly ICycleSelection _cycleSelection;
        readonly IDbContext _dbContext;
        readonly ILifetimeScope _lifetimeScope;
        readonly IPolicingEngine _policingEngine;
        readonly ISecurityContext _securityContext;

        public BatchEventUpdateController(
            IDbContext dbContext,
            ISecurityContext securityContext,
            IPolicingEngine policingEngine,
            ILifetimeScope lifetimeScope,
            IBatchEventsModelBuilder batchEventsModelBuilder,
            ICaseAuthorization caseAuthorization,
            ICycleSelection cycleSelection)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _policingEngine = policingEngine;
            _lifetimeScope = lifetimeScope;
            _batchEventsModelBuilder = batchEventsModelBuilder;
            _caseAuthorization = caseAuthorization;
            _cycleSelection = cycleSelection;
        }

        [HttpGet]
        [ActionName("Index")]
        [NoEnrichment]
        public HttpResponseMessage Get(string caseIds)
        {
            return Index(caseIds);
        }

        [HttpPost]
        [ActionName("Index")]
        [NoEnrichment]
        public dynamic Post([FromBody] JObject caseIds)
        {
            if (caseIds == null) throw new ArgumentNullException("caseIds");
            dynamic ids = caseIds;
            return Index(ids.caseIds.Value.ToString());
        }

        dynamic Index(string caseIds)
        {
            if (string.IsNullOrEmpty(caseIds))
            {
                throw new HttpResponseException(
                                                new HttpResponseMessage(HttpStatusCode.BadRequest)
                                                {
                                                    ReasonPhrase = Resources.ValidationAtLeastOneCaseIdMustBeSpecified
                                                });
            }

            var tempStorageId = SaveCaseIds(caseIds);
            var response = Request.CreateResponse(HttpStatusCode.Redirect);
            response.Content = new StringContent(string.Empty);
            response.Content.Headers.ContentType = new MediaTypeHeaderValue("text/plain");
            response.Headers.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true,
                NoStore = true,
                MaxAge = TimeSpan.Zero
            };
            response.Headers.Location = new Uri(Request.RequestUri.RelativeUri("batcheventupdate") + "BatchEventUpdate/?tempStorageId=" + tempStorageId);
            return response;
        }

        long SaveCaseIds(string caseIds)
        {
            var tempStorage = new TempStorage(caseIds);
            _dbContext.Set<TempStorage>().Add(tempStorage);
            _dbContext.SaveChanges();
            return tempStorage.Id;
        }

        [HttpPost]
        [Route("api/BatchEventUpdate/BatchEvent")]
        public dynamic BatchEventUpdate([FromBody] JObject caseIds)
        {
            if (caseIds == null) throw new ArgumentNullException(nameof(caseIds));
            dynamic ids = caseIds;
            var caseId = ids.caseIds.Value.ToString();
            var tempStorageId = SaveCaseIds(caseId);
            return Request.RequestUri.RelativeUri("api") + "BatchEventUpdate/?tempStorageId=" + tempStorageId;
        }

        [HttpGet]
        [Route("api/BatchEventUpdate/menu/{tempStorageId}")]
        public async Task<OpenActionModel[]> Menu(long tempStorageId)
        {
            var caseIds = GetCaseIdsFromTempStorage(tempStorageId);
            var firstAccessibleCase = await GetFirstUpdatableCase(LoadCasesInRequestedOrder(caseIds));

            var accessibleDataEntryTasks = GetAccessibleDataEntryTasks(
                                                                       firstAccessibleCase,
                                                                       out var accessibleDataEntryTasksWithoutExtraTabs);

            var cyclicalEvents = GetReferencedCyclicalEvents(accessibleDataEntryTasks).ToList();
            var validActionsForFirstAvailableCase = firstAccessibleCase
                .GetAllValidActionsForCase(_dbContext);
            var openActionCycles = GetOpenActionCycles(firstAccessibleCase, caseIds);
            return firstAccessibleCase.OpenActions
                                      .Where(oa => oa.Criteria != null)
                                      .Where(
                                             oa =>
                                                 validActionsForFirstAvailableCase.Any(va => va.ActionId == oa.ActionId) &&
                                                 oa.Criteria.DataEntryTasks.Any(
                                                                                accessibleDataEntryTasksWithoutExtraTabs
                                                                                    .Contains))
                                      .OrderBy(oa => oa.Action.Name).ThenBy(oa => oa.Cycle)
                                      .GroupBy(oa => oa.Criteria).Select(grp => grp.Last())
                                      .Select(
                                              oa => new OpenActionModel(
                                                                        oa,
                                                                        validActionsForFirstAvailableCase
                                                                            .Single(va => va.ActionId == oa.ActionId),
                                                                        firstAccessibleCase,
                                                                        accessibleDataEntryTasksWithoutExtraTabs,
                                                                        cyclicalEvents,
                                                                        openActionCycles.SingleOrDefault(oac => oac.ActionId == oa.Action.Id)?.Cycles))
                                      .ToArray();
        }

        IEnumerable<DataEntryTask> GetAccessibleDataEntryTasks(
            Case firstAccessibleCase,
            out List<DataEntryTask>
                accessibleDataEntryTasksWithoutExtraTabs)
        {
            var accessibleDataEntryTasks =
                firstAccessibleCase.GetAccessibleDataEntryTasks(_securityContext.User, _dbContext).ToList();

            var dataEntryTaskSteps = _dbContext.Set<DataEntryTaskStep>();
            var accessibleDataEntryTasksWithExtraTabs = accessibleDataEntryTasks.Where(
                                                                                       adet =>
                                                                                           dataEntryTaskSteps.Any(
                                                                                                                  dets =>
                                                                                                                      dets
                                                                                                                          .CriteriaId ==
                                                                                                                      adet
                                                                                                                          .CriteriaId &&
                                                                                                                      dets
                                                                                                                          .DataEntryTaskId ==
                                                                                                                      adet.Id));
            accessibleDataEntryTasksWithoutExtraTabs =
                accessibleDataEntryTasks.Except(accessibleDataEntryTasksWithExtraTabs).ToList();
            return accessibleDataEntryTasks;
        }

        IEnumerable<dynamic> GetOpenActionCycles(Case firstAccessibleCase, string caseIds)
        {
            var caseIdsList = caseIds.Split(',').Select(int.Parse).Distinct().ToArray();
            var casesOpenActions = _dbContext.Set<OpenAction>().Where(_ => caseIdsList.Contains(_.CaseId) && _.PoliceEvents == 1M).ToArray();

            var cyclesList = from coa in firstAccessibleCase.OpenActions
                             join oa in casesOpenActions on coa.Action.Id equals oa.Action.Id
                             group oa by oa.Action.Id into oa1
                             select new
                             {
                                 ActionId = oa1.Key,
                                 Cycles = oa1.Select(_ => _.Cycle).Distinct().OrderBy(_ => _)
                             };

            return cyclesList.ToArray();
        }

        async Task<Case> GetFirstUpdatableCase(IEnumerable<Case> cases)
        {
            Case firstUpdatable = null;
            foreach (var @case in cases)
            {
                var r = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Update);
                if (r.Exists && !r.IsUnauthorized)
                {
                    firstUpdatable = @case;
                    break;
                }
            }

            if (firstUpdatable != null)
            {
                return firstUpdatable;
            }

            throw new HttpResponseException(
                                            new HttpResponseMessage(HttpStatusCode.NotFound)
                                            {
                                                ReasonPhrase = Resources.ErrorCasesOneOrMoreSpecifiedCasesNotFoundOrNotUpdatable
                                            });
        }

        [HttpPost]
        [NoEnrichment]
        public async Task<CycleSelectionModel> CycleSelection(CycleSelectionRequestModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            var caseIds = GetCaseIdsFromTempStorage(model.TempStorageId);
            var firstCase = await GetFirstUpdatableCase(LoadCasesInRequestedOrder(caseIds));
            if (firstCase == null)
            {
                throw Exceptions.NotFound(Resources.ErrorCasesCaseNotFound);
            }

            var dataEntryTask = firstCase
                                .GetAccessibleDataEntryTasks(_securityContext.User, _dbContext)
                                .SingleOrDefault(det => det.CriteriaId == model.CriteriaId && det.Id == model.DataEntryTaskId);

            if (dataEntryTask == null)
            {
                throw new HttpResponseException(
                                                new HttpResponseMessage(HttpStatusCode.NotFound)
                                                {
                                                    ReasonPhrase = Resources.ErrorDataEntryTaskDataEntryTaskNotFound
                                                });
            }

            return new CycleSelectionModel(firstCase, dataEntryTask);
        }

        [HttpPost]
        [NoEnrichment]
        public async Task<BatchEventsModel> Events(EventsRequestModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var caseIds = GetCaseIdsFromTempStorage(model.TempStorageId);
            if (string.IsNullOrEmpty(caseIds))
            {
                throw Exceptions.BadRequest("At least one case is required.");
            }

            var cases = LoadCasesInRequestedOrder(caseIds);

            var dataEntryTask = _dbContext.Set<DataEntryTask>()
                                          .Include(det => det.AvailableEvents.Select(ae => ae.Event))
                                          .Single(
                                                  det =>
                                                      det.CriteriaId == model.CriteriaId && det.Id == model.DataEntryTaskId);

            if (model.UseNextCycle == null && model.ActionCycle == null && _cycleSelection.IsRequired(dataEntryTask, await GetFirstUpdatableCase(cases)))
            {
                throw new HttpResponseException(HttpStatusCode.Ambiguous);
            }

            return await _batchEventsModelBuilder.Build(cases, dataEntryTask, model.UseNextCycle.GetValueOrDefault(), model.ActionCycle);
        }

        Case[] LoadCasesInRequestedOrder(string caseIds)
        {
            var a = caseIds.Split(',').Select(int.Parse).Distinct().ToArray();

            var cases = _dbContext.Set<Case>()
                                  .Include(c => c.Country)
                                  .Include(c => c.CaseEvents)
                                  .Include(c => c.CaseLocations)
                                  .Include(c => c.OpenActions)
                                  .Include(c => c.OfficialNumbers)
                                  .Where(c => a.Contains(c.Id))
                                  .ToDictionary(c => c.Id, c => c);

            return a.Where(cases.ContainsKey).Select(id => cases[id]).ToArray();
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.BatchEventUpdate)]
        public async Task<SingleCaseUpdatedResultModel[]> Save(SaveBatchEventsModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            if (!model.Cases.Any()) throw Exceptions.BadRequest("Nothing to update");

            var caseIds = model.Cases.Select(c => c.CaseId).ToArray();
            var cases = _dbContext.Set<Case>().Where(c => caseIds.Contains(c.Id)).AsNoTracking().ToArray();

            if (cases.Count() != caseIds.Length)
            {
                throw Exceptions.BadRequest("One or more cases for batch event update is invalid");
            }

            var dataEntryTask =
                _dbContext.Set<DataEntryTask>().AsNoTracking().SingleOrDefault(
                                                                               det =>
                                                                                   det.CriteriaId == model.CriteriaId &&
                                                                                   det.Id == model.DataEntryTaskId);

            if (dataEntryTask == null)
            {
                throw Exceptions.BadRequest("No such data entry task for the case");
            }

            var results = new List<SingleCaseUpdatedResultModel>();

            foreach (var caseUpdate in model.Cases)
            {
                var @case = cases.Single(c => c.Id == caseUpdate.CaseId);

                using (var lts = _lifetimeScope.BeginLifetimeScope())
                {
                    var scu = lts.Resolve<ISingleCaseUpdate>();

                    var r = await scu.Update(caseUpdate, @case, dataEntryTask, model.ActionCycle);

                    if (r.BatchNumberForImmediatePolicing.HasValue)
                    {
                        _policingEngine.PoliceAsync(r.BatchNumberForImmediatePolicing.Value);
                    }

                    results.Add(new SingleCaseUpdatedResultModel(@case, r.DataEntryTaskCompletionResult));
                }
            }

            return results.ToArray();
        }

        IEnumerable<int> GetReferencedCyclicalEvents(IEnumerable<DataEntryTask> dataEntryTasks)
        {
            var eventsReferenced = new List<int>();
            foreach (var dc in dataEntryTasks)
            {
                if (dc.DisplayEventNo.HasValue && !eventsReferenced.Contains(dc.DisplayEventNo.Value))
                {
                    eventsReferenced.Add(dc.DisplayEventNo.Value);
                }

                if (dc.HideEventNo.HasValue && !eventsReferenced.Contains(dc.HideEventNo.Value))
                {
                    eventsReferenced.Add(dc.HideEventNo.Value);
                }

                if (dc.DimEventNo.HasValue && !eventsReferenced.Contains(dc.DimEventNo.Value))
                {
                    eventsReferenced.Add(dc.DimEventNo.Value);
                }
            }

            if (eventsReferenced.Any())
            {
                return _dbContext.Set<Event>()
                                 .Where(e => eventsReferenced.Contains(e.Id) && e.NumberOfCyclesAllowed > 1)
                                 .Select(e => e.Id);
            }

            return eventsReferenced;
        }

        string GetCaseIdsFromTempStorage(long tempStorageId)
        {
            var tempData = _dbContext.Set<TempStorage>().FirstOrDefault(x => x.Id == tempStorageId);
            if (tempData == null || string.IsNullOrEmpty(tempData.Value))
            {
                throw new HttpResponseException(
                                                new HttpResponseMessage(HttpStatusCode.BadRequest)
                                                {
                                                    ReasonPhrase = Resources.ValidationAtLeastOneCaseIdMustBeSpecified
                                                });
            }

            return tempData.Value;
        }

        [HttpGet]
        [Route("api/BatchEventUpdate/resources")]
        [IncludeLocalisationResources("batchEventUpdate")]
        public dynamic ViewResources()
        {
            return null;
        }
    }
}