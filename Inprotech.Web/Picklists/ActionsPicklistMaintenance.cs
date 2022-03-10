using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Linq;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Picklists
{
    public interface IActionsPicklistMaintenance
    {
        dynamic Save(Action action, Operation operation);
        dynamic Delete(int actionId);
        ActionData Get(int actionId);
    }

    public class ActionsPicklistMaintenance : IActionsPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        public ActionsPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public dynamic Save(Action action, Operation operation)
        {
            if (action == null) throw new ArgumentNullException(nameof(action));

            var validationErrors = Validate(action, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.Action>()
                                    .Single(_ => _.Id == action.Key)
                        : _dbContext.Set<EntityModel.Action>()
                                    .Add(new EntityModel.Action(action.Code));

                    model.Name = action.Value;
                    model.NumberOfCyclesAllowed = action.Cycles;
                    model.Code = action.Code;
                    model.ActionType = (short) action.ActionType;
                    model.ImportanceLevel = action.ImportanceLevel;

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

        public dynamic Delete(int actionId)
        {
            try
            {
                if (_dbContext.Set<ValidAction>().Any(vb => vb.Action.Id == actionId))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = _dbContext
                        .Set<EntityModel.Action>()
                        .Single(_ => _.Id == actionId);

                    if (model == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ActionDoesNotExist.ToString());

                    _dbContext.Set<EntityModel.Action>().Remove(model);

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

        public ActionData Get(int actionId)
        {
            var action = _dbContext.Set<EntityModel.Action>()
                                         .Single(_ => _.Id == actionId);
            return new ActionData
            {
                Id = action.Id,
                Name = action.Name,
                Code = action.Code,
                Cycles = action.NumberOfCyclesAllowed,
                ActionType = action.ActionType,
                ImportanceLevel = action.ImportanceLevel
            };
        }

        IEnumerable<ValidationError> Validate(Action action, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.Action>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != action.Key))
            {
                throw new ArgumentException("Unable to retrieve action for update.");
            }

            foreach (var validationError in CommonValidations.Validate(action))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != action.Key).ToArray() : all;
            if (others.Any(_ => _.Code.IgnoreCaseEquals(action.Code)))
            {
                yield return ValidationErrors.NotUnique("code");
            }

            if (others.Any(_ => _.Name.IgnoreCaseEquals(action.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
