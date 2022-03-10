using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Characteristics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/rules/characteristics")]
    public class CharacteristicsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IIndex<string, ICharacteristicsService> _characteristicsService;
        readonly IIndex<string, ICharacteristicsValidator> _characteristicsValidator;

        public CharacteristicsController(IDbContext dbContext,
                                         IIndex<string, ICharacteristicsService> characteristicsService,
                                         IIndex<string, ICharacteristicsValidator> characteristicsValidator)
        {
            _dbContext = dbContext;
            _characteristicsService = characteristicsService;
            _characteristicsValidator = characteristicsValidator;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [AuthorizeCriteriaPurposeCodeTaskSecurity]
        [Route("caseCharacteristics/{caseId}")]
        public dynamic GetCaseCharacteristics(int caseId, string purposeCode)
        {
            var @case = _dbContext.Set<Case>()
                                  .Include(_ => _.Office)
                                  .Include(_ => _.PropertyType)
                                  .Include(_ => _.Country)
                                  .Include(_ => _.SubType)
                                  .Include(_ => _.Property)
                                  .Single(_ => _.Id == caseId);

            var c = new WorkflowCharacteristics
            {
                Office = @case.Office?.Id,
                Jurisdiction = @case.Country?.Id,
                CaseType = @case.TypeId,
                PropertyType = @case.PropertyType?.Code,
                CaseCategory = @case.CategoryId,
                SubType = @case.SubType?.Code,
                Basis = @case.Property?.Basis
            };

            var vc = _characteristicsService[purposeCode].GetValidCharacteristics(c);

            return new
            {
                Office = GetOffice(@case.Office),
                Jurisdiction = GetJurisdiction(@case.Country),
                vc.CaseType,
                vc.PropertyType,
                vc.CaseCategory,
                vc.SubType,
                vc.Basis,
                vc.Program,
                ApplyTo = ClientFilterOptions.Convert(@case.LocalClientFlag)
            };

        }
        
        [HttpGet]
        [Route("validateCharacteristics")]
        [AuthorizeCriteriaPurposeCodeTaskSecurity]
        public dynamic ValidateSearchCriteria(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] WorkflowCharacteristics characteristics, string purposeCode)
        {
            var vc = _characteristicsValidator[purposeCode].Validate(characteristics);
            return new
            {
                vc.PropertyType,
                vc.CaseCategory,
                vc.SubType,
                vc.Basis,
                vc.Action,
                vc.Checklist
            };
        }

        ValidatedCharacteristic GetOffice(Office office)
        {
            return office == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(office.Id.ToString(), office.Name);
        }

        ValidatedCharacteristic GetJurisdiction(Country jurisdiction)
        {
            return jurisdiction == null
                ? new ValidatedCharacteristic()
                : new ValidatedCharacteristic(jurisdiction.Id, jurisdiction.Name);
        }

    }
}
