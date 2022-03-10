using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;
using EntityModel = InprotechKaizen.Model.Cases;
namespace Inprotech.Web.Picklists
{
    public interface ICaseTypesPicklistMaintenance
    {
        dynamic Save(CaseType caseType, Operation operation);
        dynamic Delete(int typeId);
    }

    public class CaseTypesPicklistMaintenance : ICaseTypesPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public CaseTypesPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public dynamic Save(CaseType caseType, Operation operation)
        {
            if (caseType == null) throw new ArgumentNullException(nameof(caseType));

            var validationErrors = Validate(caseType, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.CaseType>()
                                    .Single(_ => _.Code == caseType.Code)
                        : _dbContext.Set<EntityModel.CaseType>()
                                    .Add(new EntityModel.CaseType(caseType.Code, caseType.Value));

                    model.Name = caseType.Value;
                    model.ActualCaseTypeId = caseType.ActualCaseType?.Code;
                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                               {
                                   Result = "success",
                                   Key = model.Id
                               };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        public dynamic Delete(int typeId)
        {
            try
            {
                if (IsInUse(typeId))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = _dbContext
                        .Set<EntityModel.CaseType>()
                        .Single(_ => _.Id == typeId);

                    if (model == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.CaseTypeDoesNotExist.ToString());

                    if (model != null && model.Code.ToUpper() == "A") return KnownSqlErrors.CannotDeleteProtectedCaseType.AsHandled();

                    _dbContext.Set<EntityModel.CaseType>().Remove(model);

                    _dbContext.SaveChanges();
                    tcs.Complete();
                }

                return new
                {
                    Result = "success"
                };
            }
            catch (Exception ex)
            {
                if (!ex.IsForeignKeyConstraintViolation())
                    throw;

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }

        bool IsInUse(int typeId)
        {
            if (_dbContext.Set<EntityModel.ValidAction>().Any(_ => _.CaseType.Id == typeId))
                    return true;

            if (_dbContext.Set<ValidBasisEx>().Any(_ => _.CaseType.Id == typeId))
                return true;

            if (_dbContext.Set<ValidCategory>().Any(_ => _.CaseType.Id == typeId))
                return true;

            if (_dbContext.Set<ValidChecklist>().Any(_ => _.CaseType.Id == typeId))
                return true;

            if (_dbContext.Set<ValidStatus>().Any(_ => _.CaseType.Id == typeId))
                return true;

            if (_dbContext.Set<ValidSubType>().Any(_ => _.CaseType.Id == typeId))
                return true;

            if(_dbContext.Set<Criteria>().Any(_=>_.CaseType.Id == typeId))
                return true;

            return false;
        }

        IEnumerable<ValidationError> Validate(CaseType caseType, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.CaseType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Code != caseType.Code))
            {
                throw new ArgumentException("Unable to retrieve caseType for update.");
            }

            foreach (var validationError in CommonValidations.Validate(caseType))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Code != caseType.Code).ToArray() : all;
            if (others.Any(_ => _.Code.IgnoreCaseEquals(caseType.Code)))
            {
                yield return ValidationErrors.NotUnique("code");
            }

            if (others.Any(_ => _.Name.IgnoreCaseEquals(caseType.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }

            var originalCaseType = all.FirstOrDefault(_ => _.Code == caseType.Code);

            if (operation == Operation.Update && ( (caseType.ActualCaseType!=null && originalCaseType.ActualCaseTypeId != caseType.ActualCaseType.Code) || (caseType.ActualCaseType ==null && !string.IsNullOrEmpty(originalCaseType.ActualCaseTypeId))))
            {
               if(_dbContext.Set<EntityModel.Case>().Any(_=>_.TypeId == caseType.Code))
                    yield return new ValidationError("pkActualCaseType", "entity.cannotchangeactualcasetype");
            }

            if (caseType.ActualCaseType!=null && all.Any(_=>_.Code != caseType.Code && _.ActualCaseTypeId ==caseType.ActualCaseType.Code ))
            {
                yield return new ValidationError("pkActualCaseType", "entity.actualcasetypenotUnique");
            }

        }
    }
}
