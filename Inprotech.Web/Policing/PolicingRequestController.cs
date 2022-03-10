using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Forecast;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Web.Policing
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPolicingRequest)]
    [RoutePrefix("api/policing/requests")]
    public class PolicingRequestController : ApiController
    {
        public enum PolicingRequestRunType
        {
            OneRequest = 1,
            SeparateCases = 2
        }

        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IPolicingCharacteristicsService _policingCharacteristicsService;
        readonly IPolicingEngine _policingEngine;
        readonly IPolicingRequestDateCalculator _policingRequestDateCalculator;
        readonly IPolicingRequestReader _policingRequestReader;
        readonly IPolicingRequestSps _policingRequestSps;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Title",
                SortDir = "asc"
            });

        public PolicingRequestController(IDbContext dbContext,
                                         IPreferredCultureResolver preferredCultureResolver,
                                         Func<DateTime> now, IPolicingEngine policingEngine,
                                         IPolicingRequestReader policingRequestReader,
                                         IPolicingRequestSps policingRequestSps,
                                         IPolicingRequestDateCalculator policingRequestDateCalculator,
                                         IPolicingCharacteristicsService policingCharacteristicsService)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _now = now;
            _policingEngine = policingEngine;
            _policingRequestReader = policingRequestReader;
            _policingRequestSps = policingRequestSps;
            _policingRequestDateCalculator = policingRequestDateCalculator;
            _policingCharacteristicsService = policingCharacteristicsService;
        }

        [HttpGet]
        [Route("view")]
        public dynamic Retrieve()
        {
            var canCalculateAffectedCases = GetAffectedCases(0, true);
            return new
            {
                CanCalculateAffectedCases = canCalculateAffectedCases?.IsSupported ?? false
            };
        }

        [HttpGet]
        [Route("")]
        [NoEnrichment]
        public PagedResults PolicingRequests([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);

            var culture = _preferredCultureResolver.Resolve();

            var requests = _policingRequestReader.FetchAll();
            var count = requests.Count();

            var orderedResults = requests.OrderByProperty(MapColumnName(queryParameters.SortBy), queryParameters.SortDir)
                                                 .Skip(queryParameters.Skip.GetValueOrDefault())
                                                 .Take(queryParameters.Take.GetValueOrDefault());

            var dataset = orderedResults.Select(r => new
            {
                Title = DbFuncs.GetTranslation(r.Name, null, r.PolicingNameTId, culture),
                Notes = DbFuncs.GetTranslation(r.Notes, null, r.NotesTId, culture),
                Id = r.RequestId
            }).ToArray();

            return new PagedResults(dataset, requests.Count());
        }

        static string MapColumnName(string column)
        {
            switch (column?.ToLower())
            {
                case "title":
                    return "Name";
                case "notes":
                    return "Notes";
                default:
                    return column;
            }
        }

        [HttpGet]
        [Route("{requestId:int}")]
        public PolicingRequestItem Get(int requestId)
        {
            return _policingRequestReader.FetchAndConvert(requestId);
        }

        [HttpGet]
        [Route("validateCharacteristics")]
        public dynamic ValidateCharacteristics([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "characteristics")]
                                               InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics characteristics)
        {
            if (characteristics == null) throw new ArgumentNullException(nameof(characteristics));

            return _policingCharacteristicsService.ValidateCharacteristics(characteristics);
        }

        [HttpPut]
        [Route("{requestId:int}")]
        [AppliesToComponent(KnownComponents.Policing)]
        public dynamic Update(int requestId, PolicingRequestItem request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var titleError = ValidateTitle(request.Title, request.RequestId);
            if (titleError != null)
            {
                return titleError;
            }

            var requestToUpdate = _policingRequestReader.Fetch(requestId);
            if (requestToUpdate == null)
            {
                throw new ArgumentException("Unable to retrieve policing request for update.");
            }

            requestToUpdate.UpdateFrom(request);
            var charError = AreCharacteristicsValid(requestToUpdate);
            if (charError != null)
            {
                return charError;
            }

            _dbContext.SaveChanges();

            return new
            {
                Status = "success",
                requestToUpdate.RequestId
            };
        }

        [HttpPost]
        [Route("")]
        [AppliesToComponent(KnownComponents.Policing)]
        public dynamic SaveRequest(PolicingRequestItem model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            var request = model.ToPolicingRequest(new SqlDateTime(_now()).Value);

            var validationError = ValidateTitle(model.Title, model.RequestId) ?? AreCharacteristicsValid(request);
            if (validationError != null)
            {
                return validationError;
            }

            _dbContext.Set<PolicingRequest>().Add(request);
            _dbContext.SaveChanges();
            return new
            {
                Status = "success",
                request.RequestId
            };
        }

        [HttpPost]
        [Route("Delete")]
        [AppliesToComponent(KnownComponents.Policing)]
        public dynamic DeleteRequests(int[] requestIds)
        {
            var request = _policingRequestReader.FetchAll(requestIds);
            var requestLog = _dbContext.Set<PolicingLog>().Where(_ => string.IsNullOrEmpty(_.FailMessage) && _.FinishDateTime == null);

            var deletableRequests = (from r in request
                                     join l in requestLog on r.Name equals l.PolicingName into logs
                                     from log in logs.DefaultIfEmpty()
                                     where log == null
                                     select r).ToList();

            var ids = deletableRequests.Select(_ => _.RequestId);
            var nonDeletableIds = requestIds.Where(_ => !ids.Contains(_)).ToArray();

            deletableRequests.ForEach(_ => _dbContext.Set<PolicingRequest>().Remove(_));
            _dbContext.SaveChanges();

            if (!deletableRequests.Any())
            {
                return new
                {
                    Status = "error",
                    NotDeletedIds = nonDeletableIds,
                    Error = "alreadyInUse"
                };
            }

            return new
            {
                Status = nonDeletableIds.Any() ? "partialSuccess" : "success",
                NotDeletedIds = nonDeletableIds.Any() ? nonDeletableIds : Enumerable.Empty<int>(),
                Error = nonDeletableIds.Any() ? "alreadyInUse" : null
            };
        }

        [HttpPost]
        [Route("RunNow/{requestId:int}")]
        [AppliesToComponent(KnownComponents.Policing)]
        public async Task RunNow(int requestId, PolicingRequestRunType runType)
        {
            var request = _policingRequestReader.Fetch(requestId);
            if (request == null)
            {
                throw new ArgumentException("Unable to retrieve policing request for update.");
            }

            var result = runType == PolicingRequestRunType.OneRequest
                ? _policingEngine.PoliceAsync(request.DateEntered, request.SequenceNo)
                : await _policingRequestSps.CreatePolicingForCasesFromRequest(requestId);

            if (result.HasError)
            {
                throw new Exception(result.ErrorReason);
            }
        }

        PolicingRequestAffectedCases GetAffectedCases(int requestId, bool onlyCheckFeatureAvailability)
        {
            return _policingRequestSps.GetNoOfAffectedCases(requestId, onlyCheckFeatureAvailability);
        }

        [HttpGet]
        [Route("lettersdate")]
        public DateTime GetLettersDate(DateTime startDate)
        {
            var date = new DateTime(startDate.Year, startDate.Month, startDate.Day);
            return _policingRequestDateCalculator.GetLettersDate(date);
        }

        dynamic Error(string field, string errorKey)
        {
            return new
            {
                Status = "error",
                Error = new KeyValuePair<string, string>(field, errorKey)
            };
        }

        dynamic ValidateTitle(string title, int? requestId)
        {
            if (string.IsNullOrWhiteSpace(title))
            {
                return Error("title", "required");
            }

            if (title.Length > 40)
            {
                return Error("title", "maxlength");
            }

            if (!_policingRequestReader.IsTitleUnique(title, requestId))
            {
                return Error("title", "notunique");
            }

            return null;
        }

        dynamic AreCharacteristicsValid(PolicingRequest request)
        {
            var characteristics = request.ToCharacteristics();
            var validated = _policingCharacteristicsService.ValidateCharacteristics(characteristics);
            var result = validated.PropertyType.IsValid && validated.CaseCategory.IsValid && validated.SubType.IsValid && validated.Action.IsValid;

            return result
                ? null
                : new
                {
                    Status = "error",
                    Error = new KeyValuePair<string, string>("characteristics", "invalid"),
                    ValidationResult = validated
                };
        }
    }
}