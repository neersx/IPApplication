using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;
using Status = InprotechKaizen.Model.Cases.Status;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    public class StatusMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IStatusSupport _statusSupport;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public StatusMaintenanceController(IDbContext dbContext, IStatusSupport statusSupport, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (statusSupport == null) throw new ArgumentNullException("statusSupport");
            if (lastInternalCodeGenerator == null) throw new ArgumentNullException("lastInternalCodeGenerator");

            _dbContext = dbContext;
            _statusSupport = statusSupport;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        [HttpGet]
        [Route("api/configuration/status/supportdata")]
        [NoEnrichment]
        public dynamic GetSupportData()
        {
            var stopPayReasons =
                _statusSupport.StopPayReasons();
            var permissions = _statusSupport.Permissions();
            return new
            {
                stopPayReasons,
                permissions
            };
        }

        [HttpGet]
        [Route("api/configuration/status")]
        [RequiresAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.None)]
        [NoEnrichment]
        public dynamic Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] StatusSearchOptions searchOptions)
        {
            var renewalFlag = Convert.ToDecimal(searchOptions.IsRenewal);

            var results = _dbContext.Set<Status>().Where(_ => _.RenewalFlag == renewalFlag && (_.Name.Contains(searchOptions.Text)
                                         || _.ExternalName.Contains(searchOptions.Text)));

            var response = results.AsEnumerable().OrderBy(_ => _.Name).Select(status =>
                StatusTranslator.ConvertToSaveStatusModel(status, _statusSupport.StopPayReasonFor(status.StopPayReason),
                                                            !status.RenewalFlag.ToBoolean() ? _dbContext.Set<Case>().Count(_ => _.CaseStatus.Id == status.Id)
                                                                                           : _dbContext.Set<CaseProperty>().Count(_ => _.RenewalStatus.Id == status.Id)));

            return response;
        }

        [HttpGet]
        [Route("api/configuration/status/{id}")]
        [NoEnrichment]
        public dynamic Get(short id)
        {
            var status = _dbContext.Set<Status>().Single(_ => _.Id == id);
            return StatusTranslator.ConvertToSaveStatusModel(status, _statusSupport.StopPayReasonFor(status.StopPayReason));
        }

        [HttpPost]
        [Route("api/configuration/status")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Create)]
        public dynamic Save(SaveStatusModel saveModel)
        {
            if (saveModel == null) throw new ArgumentNullException("saveModel");

            var validationErrors = Validate(saveModel, Operation.Add).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();

            var statusCode = (short)_lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Status);
            saveModel.ExternalName = string.IsNullOrEmpty(saveModel.ExternalName) ? saveModel.Name : saveModel.ExternalName;
            var entity = StatusTranslator.ConvertToStatusModel(saveModel, statusCode);

            _dbContext.Set<Status>().Add(entity);
            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedId = entity.Id
            };
        }

        [HttpPut]
        [Route("api/configuration/status/{id}")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Modify)]
        public dynamic Update(short id, SaveStatusModel saveModel)
        {
            if (saveModel == null) throw new ArgumentNullException("saveModel");

            var validationErrors = Validate(saveModel, Operation.Update).ToArray();

            if (!validationErrors.Any())
            {
                var entityToUpdate = _dbContext.Set<Status>().Single(_ => _.Id == saveModel.Id);
                entityToUpdate = StatusTranslator.SetStatusFromSaveStatusModel(entityToUpdate, saveModel);

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entityToUpdate.Id
                };
            }
            return validationErrors.AsErrorResponse();
        }

        [HttpPost]
        [Route("api/configuration/status/delete")]
        [RequiresAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Delete)]
        [NoEnrichment]
        public DeleteResponseModel Delete(DeleteRequestModel deleteStatusModel)
        {
            if (deleteStatusModel == null) throw new ArgumentNullException("deleteStatusModel");

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var statusList = _dbContext.Set<Status>().
                                            Where(_ => deleteStatusModel.Ids.Contains(_.Id)).ToList();

                response.InUseIds = new List<int>();

                foreach (var status in statusList)
                {
                    try
                    {
                        _dbContext.Set<Status>().Remove(status);
                        _dbContext.SaveChanges();

                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(status.Id);
                        }
                        _dbContext.Detach(status);
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }

            return response;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> Validate(SaveStatusModel saveModel, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(saveModel))
                yield return validationError;

            foreach (var vr in CheckForErrors(saveModel.Id, saveModel.Name, saveModel.StatusType, operation)) yield return vr;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> CheckForErrors(short id, string name, StatusType renewalType, Operation operation)
        {
            var all = _dbContext.Set<Status>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != id))
            {
                throw new HttpResponseException(System.Net.HttpStatusCode.NotFound);
            }

            var renewalFlag = renewalType == StatusType.Renewal ? 1 : 0;

            var others = operation == Operation.Update ? all.Where(_ => _.Name == name && _.Id != id).ToArray() : all;
            if (others.Any(_ => _.Name.IgnoreCaseEquals(name) && _.RenewalFlag == renewalFlag))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateStatusDescription,name), "internalName");
            }
        }
    }

    public class StatusSearchOptions : SearchOptions
    {
        public bool IsRenewal { get; set; }
    }
}
