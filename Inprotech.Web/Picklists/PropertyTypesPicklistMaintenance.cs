using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Picklists
{
    public interface IPropertyTypesPicklistMaintenance
    {
        dynamic Save(PropertyType propertyType, Operation operation);
        dynamic Delete(int propertyTypeId);
    }

    public class PropertyTypesPicklistMaintenance : IPropertyTypesPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public PropertyTypesPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public dynamic Save(PropertyType propertyType, Operation operation)
        {
            if (propertyType == null) throw new ArgumentNullException(nameof(propertyType));

            var validationErrors = Validate(propertyType, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.PropertyType>()
                                    .Single(_ => _.Id == propertyType.Key)
                        : _dbContext.Set<EntityModel.PropertyType>()
                                    .Add(new EntityModel.PropertyType(propertyType.Code, propertyType.Value));

                    model.Name = propertyType.Value;
                    model.AllowSubClass = propertyType.AllowSubClass;
                    model.ImageId = propertyType.ImageData?.Key;

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

        public dynamic Delete(int propertyTypeId)
        {
            try
            {
                var propertyType = _dbContext.Set<EntityModel.PropertyType>().Single(_ => _.Id == propertyTypeId);
                if (_dbContext.Set<ValidProperty>().Any(vp => vp.PropertyTypeId == propertyType.Code))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<EntityModel.PropertyType>()
                        .Single(_ => _.Id == propertyTypeId);

                    _dbContext.Set<EntityModel.PropertyType>().Remove(model);

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

        IEnumerable<ValidationError> Validate(PropertyType propertyType, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.PropertyType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != propertyType.Key))
            {
                throw new ArgumentException("Unable to retrieve propertyType type for update.");
            }

            foreach (var validationError in CommonValidations.Validate(propertyType))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != propertyType.Key).ToArray() : all;
            if (others.Any(_ => _.Code.IgnoreCaseEquals(propertyType.Code)))
            {
                yield return ValidationErrors.NotUnique("code");
            }

            if (others.Any(_ => _.Name.IgnoreCaseEquals(propertyType.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
