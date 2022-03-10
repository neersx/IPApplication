using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    public interface IDataItemGroupPicklistMaintenance
    {
        dynamic Save(DataItemGroup dataItemGroup, Operation operation);
        dynamic Delete(int code);
    }

    public class DataItemGroupPicklistMaintenance : IDataItemGroupPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public DataItemGroupPicklistMaintenance(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public dynamic Save(DataItemGroup dataItemGroup, Operation operation)
        {
            if (dataItemGroup == null) throw new ArgumentNullException(nameof(dataItemGroup));

            var validationErrors = Validate(dataItemGroup, operation).ToArray();

            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    if (operation == Operation.Add)
                    {
                        var code = (short)_lastInternalCodeGenerator.GenerateLastInternalCode("GROUPS");
                        var model = _dbContext.Set<Group>()
                                              .Add(new Group(code, dataItemGroup.Value));

                        model.Name = dataItemGroup.Value;
                    }
                    else
                    {
                        var group = _dbContext.Set<Group>().Single(_ => _.Code == dataItemGroup.Code);
                        group.Name = dataItemGroup.Value;
                    }
                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                    {
                        Result = "success",
                        dataItemGroup.Value
                    };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        public dynamic Delete(int code)
        {
            try
            {
                var entry = _dbContext.Set<Group>().SingleOrDefault(_ => _.Code == code);

                if (entry == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.DataItemGroupDoesNotExist.ToString());

                if (_dbContext.Set<ItemGroup>().Any(t => t.Code == code))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {
                    _dbContext.Set<Group>().Remove(entry);
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

        IEnumerable<ValidationError> Validate(DataItemGroup dataItemGroup, Operation operation)
        {
            var all = _dbContext.Set<Group>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Code != dataItemGroup.Code))
            {
                throw new ArgumentException("Unable to retrieve subtype for update.");
            }

            foreach (var validationError in CommonValidations.Validate(dataItemGroup))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Code != dataItemGroup.Code).ToArray() : all;

            if (others.Any(_ => _.Name.IgnoreCaseEquals(dataItemGroup.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
