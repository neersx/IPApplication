using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Picklists
{

    public interface ISubTypesPicklistMaintenance
    {
        dynamic Save(SubType subType, Operation operation);
        dynamic Delete(int typeId);
        SubType Get(int subTypeId);
    }

    public class SubTypesPicklistMaintenance : ISubTypesPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public SubTypesPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public dynamic Save(SubType subType, Operation operation)
        {
            if (subType == null) throw new ArgumentNullException(nameof(subType));
          
            var validationErrors = Validate(subType, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.SubType>()
                                    .Single(_ => _.Id == subType.Key)
                        : _dbContext.Set<EntityModel.SubType>()
                                    .Add(new EntityModel.SubType(subType.Code, subType.Value));

                    model.Name = subType.Value;
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
                var subType = _dbContext.Set<EntityModel.SubType>().Single(_ => _.Id == typeId);

                if (_dbContext.Set<ValidSubType>().Any(vb => vb.SubtypeId == subType.Code))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = _dbContext
                        .Set<EntityModel.SubType>()
                        .Single(_ => _.Id == typeId);
                    if (model == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.SubTypeDoesNotExist.ToString());

                    _dbContext.Set<EntityModel.SubType>().Remove(model);

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

        public SubType Get(int subTypeId)
        {
            var subtype = _dbContext.Set<EntityModel.SubType>().Single(_=>_.Id == subTypeId);
            return new SubType(subtype.Id, subtype.Code, subtype.Name);
        }

        IEnumerable<ValidationError> Validate(SubType subType, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.SubType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != subType.Key))
            {
                throw new ArgumentException("Unable to retrieve subtype for update.");
            }

            foreach (var validationError in CommonValidations.Validate(subType))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != subType.Key).ToArray() : all;
            if (others.Any(_ => _.Code.IgnoreCaseEquals(subType.Code)))
            {
                yield return ValidationErrors.NotUnique("code");
            }

            if (others.Any(_ => _.Name.IgnoreCaseEquals(subType.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
