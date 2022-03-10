using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Picklists
{
    public interface ICaseCategoriesPicklistMaintenance
    {
        dynamic Save(CaseCategory caseCategory, Operation operation);
        dynamic Delete(int caseCategoryId);
    }

    public class CaseCategoriesPicklistMaintenance : ICaseCategoriesPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public CaseCategoriesPicklistMaintenance(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
        }

        public dynamic Save(CaseCategory caseCategory, Operation operation)
        {
            if (caseCategory == null) throw new ArgumentNullException("caseCategory");

            var validationErrors = Validate(caseCategory, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.CaseCategory>()
                                    .Single(_ => _.Id == caseCategory.Key)
                        : _dbContext.Set<EntityModel.CaseCategory>()
                                    .Add(new EntityModel.CaseCategory(caseCategory.CaseTypeId, caseCategory.Code, caseCategory.Value));
                    model.Name = caseCategory.Value;
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

        public dynamic Delete(int caseCategoryId)
        {
            try
            {
                var caseCategory = _dbContext.Set<EntityModel.CaseCategory>().Single(cc => cc.Id == caseCategoryId);

                if (IsInUse(caseCategory))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {

                    _dbContext.Set<EntityModel.CaseCategory>().Remove(caseCategory);

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

        private bool IsInUse(EntityModel.CaseCategory caseCategory)
        {

            if (_dbContext.Set<ValidBasisEx>().Any(_ => _.CaseCategoryId == caseCategory.CaseCategoryId && _.CaseTypeId == caseCategory.CaseTypeId))
                return true;

            if (_dbContext.Set<ValidCategory>().Any(_ => _.CaseCategoryId == caseCategory.CaseCategoryId && _.CaseTypeId == caseCategory.CaseTypeId))
                return true;

            if (_dbContext.Set<ValidSubType>().Any(_ => _.CaseCategoryId == caseCategory.CaseCategoryId && _.CaseTypeId == caseCategory.CaseTypeId))
                return true;

            if (_dbContext.Set<Criteria>().Any(_ => _.CaseCategoryId == caseCategory.CaseCategoryId && _.CaseTypeId == caseCategory.CaseTypeId))
                return true;

            return false;
        }

        IEnumerable<ValidationError> Validate(CaseCategory caseCategory, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.CaseCategory>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != caseCategory.Key))
            {
                throw new ArgumentException("Unable to retrieve application caseCategory for update.");
            }

            foreach (var validationError in CommonValidations.Validate(caseCategory))
            {
                yield return validationError;
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Id != caseCategory.Key).ToArray() : all;
            if (others.Any(_ => _.CaseCategoryId.IgnoreCaseEquals(caseCategory.Code) && _.CaseTypeId.IgnoreCaseEquals(caseCategory.CaseTypeId)))
            {
                yield return ValidationErrors.NotUnique("code");
            }
            if (others.Any(_ => _.Name.IgnoreCaseEquals(caseCategory.Value) && _.CaseTypeId.IgnoreCaseEquals(caseCategory.CaseTypeId)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}