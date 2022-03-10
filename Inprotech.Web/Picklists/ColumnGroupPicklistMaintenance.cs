using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Picklists
{
    public interface IColumnGroupPicklistMaintenance
    {
        dynamic Save(QueryColumnGroupPayload columnGroup, Operation operation);
        dynamic Delete(int groupId);
    }

    public class ColumnGroupPicklistMaintenance : IColumnGroupPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public ColumnGroupPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public dynamic Save(QueryColumnGroupPayload columnGroup, Operation operation)
        {
            if (columnGroup == null) throw new ArgumentNullException(nameof(columnGroup));

            var validationErrors = Validate(columnGroup, operation).ToArray();

            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<QueryColumnGroup>().Single(_ => _.Id == columnGroup.Key)
                        : _dbContext.Set<QueryColumnGroup>()
                                    .Add(new QueryColumnGroup
                                    {
                                        GroupName = columnGroup.Value,
                                        DisplaySequence = (short) (_dbContext.Set<QueryColumnGroup>().Max(_ => _.DisplaySequence) + 1),
                                        ContextId = columnGroup.ContextId
                                    });

                    model.GroupName = columnGroup.Value;

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

        public dynamic Delete(int groupId)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = _dbContext
                                .Set<QueryColumnGroup>()
                                .Single(_ => _.Id == groupId);

                    _dbContext.Set<QueryColumnGroup>().Remove(model);

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

        IEnumerable<ValidationError> Validate(QueryColumnGroupPayload columnGroup, Operation operation)
        {
            var all = _dbContext.Set<QueryColumnGroup>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != columnGroup.Key))
            {
                throw new ArgumentException("Unable to retrieve column group name for update.");
            }

            foreach (var validationError in CommonValidations.Validate(columnGroup))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != columnGroup.Key).ToArray() : all;

            if (others.Any(_ => _.ContextId == columnGroup.ContextId && _.GroupName.IgnoreCaseEquals(columnGroup.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
