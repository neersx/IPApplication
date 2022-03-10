using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Extentions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainImportanceLevel)]
    [RoutePrefix("api/configuration/importancelevel")]
    public class ImportanceLevelMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;

        static readonly CommonQueryParameters DefaultQueryParameters =
           CommonQueryParameters.Default.Extend(new CommonQueryParameters
           {
               SortBy = "Level",
               SortDir = "asc"
           });

        public ImportanceLevelMaintenanceController(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));

            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return null;
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public dynamic Search()
        {
            var results = _dbContext.Set<Importance>().Select(_ => new
            {
                _.Level,
                _.Description
            }).AsEnumerable();

            return results.OrderByProperty(DefaultQueryParameters.SortBy, DefaultQueryParameters.SortDir);
        }

        [HttpPost]
        [Route("")]
        [NoEnrichment]
        public dynamic Save(Delta<Importance> importanceDelta)
        {
            var validationResult = new InlineValidationResult("success");

            ApplyDelete(importanceDelta.Deleted, ref validationResult);

            ApplyUpdates(importanceDelta.Updated, ref validationResult);

            ApplyAdditions(importanceDelta.Added, ref validationResult);

            return validationResult;
        }

        void ApplyDelete(ICollection<Importance> deleted, ref InlineValidationResult validationResult)
        {
            if (!deleted.Any()) return;

            var error = new InlineValidationError();
            using (var txScope = _dbContext.BeginTransaction())
            {
                var all = _dbContext.Set<Importance>();

                foreach (var item in deleted)
                {
                    var dbRecord = all.Single(_ => _.Level == item.Level);
                    try
                    {
                        all.Remove(dbRecord);
                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            error.InUseIds.Add(dbRecord.Level);
                        }
                        _dbContext.Detach(dbRecord);
                    }
                }

                txScope.Complete();

                if (error.InUseIds.Any())
                {
                    validationResult.ValidationErrors.Add(error);
                    validationResult.Result = "error";
                }
            }
        }

        void ApplyUpdates(ICollection<Importance> updated, ref InlineValidationResult validationResult)
        {
            if (!updated.Any()) return;

            var all = _dbContext.Set<Importance>();
            
            foreach (var item in updated)
            {
                var dbRecord = all.SingleOrDefault(_ => _.Level == item.Level);
                if (dbRecord != null)
                {
                    var errors = Validate(item, Operation.Update);
                    var validationErrors = errors as InlineValidationError[] ?? errors.ToArray();
                    if (validationErrors.Any())
                    {
                        validationResult.ValidationErrors.AddRange(validationErrors);
                        continue;
                    }

                    dbRecord.Level = item.Level;
                    dbRecord.Description = item.Description;
                }
            }

            if (validationResult.ValidationErrors.Any()) validationResult.Result = "error";

            _dbContext.SaveChanges();
        }

        void ApplyAdditions(ICollection<Importance> added, ref InlineValidationResult validationResult)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<Importance>();

            foreach (var item in added)
            {
                var errors = Validate(item, Operation.Add);
                var validationErrors = errors as InlineValidationError[] ?? errors.ToArray();
                if (validationErrors.Any())
                {
                    validationResult.ValidationErrors.AddRange(validationErrors);
                    continue;
                }
                all.Add(item);
            }

            if (validationResult.ValidationErrors.Any()) validationResult.Result = "error";

            _dbContext.SaveChanges();
        }

        IEnumerable<InlineValidationError> Validate(Importance importance, Operation operation)
        {
            foreach (var validationError in Map(CommonValidations.Validate(importance)))
                yield return validationError;

            var all = _dbContext.Set<Importance>().ToArray();

            var others = operation == Operation.Update ? all.Where(_ => _.Level != importance.Level).ToArray() : all;
            if (others.Any(_ => _.Level.IgnoreCaseEquals(importance.Level)))
            {
                var error = ValidationErrors.NotUnique(string.Empty, "level", importance.Level);
                yield return new InlineValidationError(error.Field, error.Message, error.Id);
            }

            if (others.Any(_ => _.Description.IgnoreCaseEquals(importance.Description)))
            {
                var error = ValidationErrors.NotUnique(string.Empty, "description", importance.Level);
                yield return new InlineValidationError(error.Field, error.Message, error.Id);
            }
        }

        static IEnumerable<InlineValidationError> Map(IEnumerable<Infrastructure.Validations.ValidationError> validationErrors)
        {
            return validationErrors.Select(_ => new InlineValidationError(_.Field, _.Message, _.Id)).AsEnumerable();
        }
    }
}
