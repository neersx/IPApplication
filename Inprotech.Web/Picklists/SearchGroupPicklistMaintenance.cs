using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Picklists
{
    public interface ISearchGroupPicklistMaintenance
    {
        dynamic Save(QueryGroup searchGroup, Operation operation);
        dynamic Delete(int groupId);
    }
    public class SearchGroupPicklistMaintenance : ISearchGroupPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public SearchGroupPicklistMaintenance(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }
        public dynamic Save(QueryGroup searchGroup, Operation operation)
        {
            if (searchGroup == null) throw new ArgumentNullException("queryGroup");

            var validationErrors = Validate(searchGroup, operation).ToArray();

            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = operation == Operation.Update
                        ? _dbContext.Set<QueryGroup>().Single(_ => _.Id == searchGroup.Id)
                        : _dbContext.Set<QueryGroup>()
                                    .Add(new QueryGroup
                                    {
                                        GroupName = searchGroup.GroupName,
                                        DisplaySequence = searchGroup.DisplaySequence,
                                        ContextId = searchGroup.ContextId
                                    });

                    model.GroupName = searchGroup.GroupName;

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

        public dynamic Delete(int Id)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {

                    var model = _dbContext
                        .Set<QueryGroup>()
                        .Single(_ => _.Id == Id);

                    _dbContext.Set<QueryGroup>().Remove(model);

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

        IEnumerable<ValidationError> Validate(QueryGroup searchGroup, Operation operation)
        {
            var all = _dbContext.Set<QueryGroup>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != searchGroup.Id))
            {
                throw new ArgumentException("Unable to retrieve search group name for update.");
            }

            foreach (var validationError in CommonValidations.Validate(searchGroup))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != searchGroup.Id).ToArray() : all;

            if (others.Any(_ => _.GroupName.IgnoreCaseEquals(searchGroup.GroupName)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
