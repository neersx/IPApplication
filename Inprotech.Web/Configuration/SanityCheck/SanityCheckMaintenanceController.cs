using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Autofac.Features.AttributeFilters;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Rules;
using InprotechKaizen.Model.DataValidation;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.SanityCheck
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/sanity-check/maintenance")]
    public class SanityCheckMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISanityCheckService _sanityCheckService;
        readonly ICharacteristicsValidator _validCombinationValidator;

        public SanityCheckMaintenanceController(IDbContext dbContext,
                                                [KeyFilter(CriteriaPurposeCodes.SanityCheck)]
                                                ICharacteristicsValidator validCombinationValidator,
                                                ISanityCheckService sanityCheckService)
        {
            _dbContext = dbContext;
            _validCombinationValidator = validCombinationValidator;
            _sanityCheckService = sanityCheckService;
        }

        [HttpPost]
        [Route("case")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> SaveCaseRule(SanityCheckCaseViewModel model)
        {
            if (!model.IsValid()) throw new HttpResponseException(HttpStatusCode.BadRequest);

            VerifyValidCombinations(model.CaseCharacteristics);
            var addedRecord = _dbContext.Set<DataValidation>().Add(model.ToDataValidation().ForCase());

            await _dbContext.SaveChangesAsync();

            return new { addedRecord.Id };
        }

        void VerifyValidCombinations(CaseCharacteristicsModel data)
        {
            var result = _validCombinationValidator.Validate(data.ToWorkflowCharacteristics());

            if (!result.IsValidCombination)
            {
                throw new Exception("Invalid valid combination selected");
            }
        }

        [HttpGet]
        [Route("case/{validationId}")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Delete)]
        public async Task<CaseSanityCheckRuleModel> GetViewDataCase(int? validationId)
        {
            if (!validationId.HasValue)
            {
                return null;
            }

            var data = await _sanityCheckService.GetCaseValidationRule(validationId.Value);

            return data;
        }

        [HttpPut]
        [Route("case")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> UpdateCaseRule(SanityCheckCaseViewUpdateModel model)
        {
            if (!model.IsValid()) throw new HttpResponseException(HttpStatusCode.BadRequest);
            VerifyValidCombinations(model.CaseCharacteristics);

            var entityToUpdate = await _dbContext.Set<DataValidation>()
                                                 .Where(_ => _.Id == model.ValidationId)
                                                 .SingleOrDefaultAsync();

            if (entityToUpdate == null)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            model.ToDataValidation(entityToUpdate).ForCase();
            await _dbContext.SaveChangesAsync();

            return new { Id = model.ValidationId };
        }

        [HttpDelete]
        [Route("case")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Delete)]
        public async Task<bool> DeleteCaseSanityCheckForCase([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "ids")] int[] ids)
        {
            if (ids?.Length == 0) throw new HttpResponseException(HttpStatusCode.BadRequest);
            await DeleteDataValidation(ids);
            return true;
        }
        
        [HttpGet]
        [Route("name/{validationId}")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Delete)]
        public async Task<NameSanityCheckRuleModel> GetViewDataName(int? validationId)
        {
            if (!validationId.HasValue)
            {
                return null;
            }

            var data = await _sanityCheckService.GetNameValidationRule(validationId.Value);

            return data;
        }

        [HttpPost]
        [Route("name")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> SaveNameRule(SanityCheckNameViewModel model)
        {
            if (!model.IsValid()) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var addedRecord = _dbContext.Set<DataValidation>().Add(model.ToDataValidation().ForName());

            await _dbContext.SaveChangesAsync();

            return new { addedRecord.Id };
        }

        [HttpPut]
        [Route("name")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> UpdateNameRule(SanityCheckNameViewUpdateModel model)
        {
            if (!model.IsValid()) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var entityToUpdate = await _dbContext.Set<DataValidation>()
                                                 .Where(_ => _.Id == model.ValidationId)
                                                 .SingleOrDefaultAsync();

            if (entityToUpdate == null)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            model.ToDataValidation(entityToUpdate).ForName();
            await _dbContext.SaveChangesAsync();

            return new { Id = model.ValidationId };
        }

        [HttpDelete]
        [Route("name")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Delete)]
        public async Task<bool> DeleteCaseSanityCheckForNames([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "ids")] int[] ids)
        {
            if (ids?.Length == 0) throw new HttpResponseException(HttpStatusCode.BadRequest);
            await DeleteDataValidation(ids);
            return true;
        }

        async Task DeleteDataValidation(int[] ids)
        {
            await _dbContext.DeleteAsync(_dbContext.Set<DataValidation>().Where(_ => ids.Contains(_.Id)));
        }
    }
}