using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.Picklists
{
    public interface IChecklistPicklistMaintenance
    {
        dynamic Save(ChecklistMatcher checklist, Operation operation);
        dynamic Delete(short typeId);
        ChecklistMatcher Get(short checklistId);
    }
    public class ChecklistPickListMaintenance : IChecklistPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        public ChecklistPickListMaintenance(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            
            _dbContext = dbContext;
        }

        public dynamic Save(ChecklistMatcher checklist, Operation operation)
        {
            if (checklist == null) throw new ArgumentNullException(nameof(checklist));

            var validationErrors = Validate(checklist, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<CheckList>()
                                    .Single(_ => _.Id == checklist.Key)
                        : _dbContext.Set<CheckList>()
                                    .Add(new CheckList(Convert.ToInt16(_dbContext.Set<CheckList>().Max(st => st.Id) + 1), checklist.Value));

                    model.Description = checklist.Value;
                    model.ChecklistTypeFlag = Convert.ToDecimal(checklist.ChecklistType);

                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                               {
                                   Result = "success",
                                   Key= model.Id
                               };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        public dynamic Delete(short checklistId)
        {
            try
            {
                if (IsInUse(checklistId))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = _dbContext
                        .Set<CheckList>()
                        .Single(_ => _.Id == checklistId);
                    if (model == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ChecklistDoesNotExist.ToString());

                    _dbContext.Set<CheckList>().Remove(model);

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

        private bool IsInUse(short checkListType)
        {
            if (_dbContext.Set<Criteria>().Any(_ => _.ChecklistType == checkListType))
                return true;

            if (_dbContext.Set<ValidChecklist>().Any(_ => _.ChecklistType == checkListType))
                return true;

            return false;
        }

        public ChecklistMatcher Get(short checklistId)
        {
            var checklist = _dbContext.Set<CheckList>()
                                         .Single(_ => _.Id == checklistId);
            return new ChecklistMatcher
            {
                Value = checklist.Description,
                Code = checklist.Id,
                ChecklistTypeFlag = checklist.ChecklistTypeFlag
            };
        }

        IEnumerable<ValidationError> Validate(ChecklistMatcher checklist, Operation operation)
        {
            var all = _dbContext.Set<CheckList>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != checklist.Key))
            {
                throw new ArgumentException("Unable to retrieve checklist for update.");
            }

            foreach (var validationError in CommonValidations.Validate(checklist))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != checklist.Key).ToArray() : all;

            if (others.Any(_ => _.Description.IgnoreCaseEquals(checklist.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
