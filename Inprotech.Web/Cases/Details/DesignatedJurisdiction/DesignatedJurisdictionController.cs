using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Linq.Expressions;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.IPPlatform.FileApp;
using InprotechKaizen.Model.Components.Cases.CriticalDates;

namespace Inprotech.Web.Cases.Details.DesignatedJurisdiction
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class DesignatedJurisdictionController : ApiController
    {
        readonly IDesignatedJurisdictions _designatedJurisdictions;
        readonly ICaseView _caseView;
        readonly ICriticalDatesResolver _criticalDatesResolver;
        readonly ICaseTextSection _caseTextSection;
        readonly IFileInstructInterface _fileInstructInterface;
        readonly IAuthSettings _settings;

        readonly Dictionary<string, Expression<Func<DesignatedJurisdictionData, CodeDescription>>> _filterables
            = new Dictionary<string, Expression<Func<DesignatedJurisdictionData, CodeDescription>>>
            {
                {"jurisdiction", x => new CodeDescription {Code = x.Jurisdiction, Description = x.Jurisdiction}},
                {"designatedStatus", x => new CodeDescription {Code = x.DesignatedStatus, Description = x.DesignatedStatus}},
                {"caseStatus", x => new CodeDescription {Code = x.CaseStatus, Description = x.CaseStatus}},
            };

        public DesignatedJurisdictionController(IDesignatedJurisdictions designatedJurisdictions, 
                                                ICaseView caseView, 
                                                ICriticalDatesResolver criticalDatesResolver, 
                                                ICaseTextSection caseTextSection,
                                                IFileInstructInterface fileInstructInterface,
                                                IAuthSettings settings)
        {
            _designatedJurisdictions = designatedJurisdictions;
            _caseView = caseView;
            _criticalDatesResolver = criticalDatesResolver;
            _caseTextSection = caseTextSection;
            _fileInstructInterface = fileInstructInterface;
            _settings = settings;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/designatedjurisdiction")]
        public async Task<PagedResults> DesignatedJurisdiction(int caseKey,
                                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                               CommonQueryParameters qp)
        {
            var designations = await _designatedJurisdictions.Get(caseKey);

            var result = designations.Filter(qp)
                               .OrderByProperty(qp)
                               .AsPagedResults(qp);

            var filedCases = _settings.SsoEnabled
                ? await _fileInstructInterface.GetFiledCaseIdsFor(Request, caseKey)
                : new FiledCases();
            
            foreach (var i in result.Items<DesignatedJurisdictionData>())
            {
                if (i.CaseKey == null) continue;

                i.IsFiled = filedCases.FiledCaseIds.Contains(i.CaseKey.Value);
                i.CanViewInFile = i.CanView && filedCases.CanView;
            }
            
            return result;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/designatedjurisdiction/filterData/{field}")]
        public async Task<IEnumerable<CodeDescription>> GetFilterDataForColumn(int caseKey, string field,
                                                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "columnFilters")]
                                                                               IEnumerable<CommonQueryParameters.FilterValue> columnFilters)
        {
            var qp = new CommonQueryParameters { Filters = columnFilters };
            if (!_filterables.TryGetValue(field, out var filterable))
                throw new NotSupportedException("field=" + field);
            var designations = await _designatedJurisdictions.Get(caseKey);
            return designations
                   .Filter(qp)
                   .Select(filterable)
                   .Distinct();
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/designationdetails")]
        public async Task<OverviewSummary> DesignationDetails(int caseKey)
        {
            var data = await _caseView.GetSummary(caseKey).FirstAsync();
            data.Names = (await _caseView.GetNames(caseKey)).ToArray();
            data.CriticalDates = await _criticalDatesResolver.Resolve(caseKey);
            data.Classes= await _caseTextSection.GetClassAndText(caseKey);
            return data;
        }
    }
}