using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.Picklists
{
    public interface IRelationshipPicklistMaintenance
    {
        dynamic Save(Relationship relationship, Operation operation);
        dynamic Delete(string relationshipId);
    }
    public class RelationshipPicklistMaintenance : IRelationshipPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public RelationshipPicklistMaintenance(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));

            _dbContext = dbContext;
        }

        public dynamic Save(Relationship relationship, Operation operation)
        {
            if (relationship == null) throw new ArgumentNullException(nameof(relationship));

            var validationErrors = Validate(relationship, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<CaseRelation>()
                                    .Single(_ => _.Relationship == relationship.Key)
                        : _dbContext.Set<CaseRelation>()
                                    .Add(new CaseRelation(relationship.Key, null));

                    model.SetNotes(relationship.Value, relationship.Notes);
                    model.SetFlags(relationship.EarliestDateFlag, relationship.ShowFlag, relationship.PointsToParent, relationship.PriorArtFlag);
                    model.SetEvents(relationship.FromEvent?.Key, relationship.ToEvent?.Key, relationship.DisplayEvent?.Key);

                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                               {
                                   Result = "success",
                                   Key = model.Relationship
                               };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        IEnumerable<ValidationError> Validate(Relationship relationship, Operation operation)
        {
            var all = _dbContext.Set<CaseRelation>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Relationship != relationship.Key))
            {
                throw new ArgumentException("Unable to retrieve propertyType type for update.");
            }

            foreach (var validationError in CommonValidations.Validate(relationship))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Relationship != relationship.Key).ToArray() : all;
            if (others.Any(_ => _.Relationship.IgnoreCaseEquals(relationship.Code)))
            {
                yield return ValidationErrors.NotUnique("code");
            }

            if (others.Any(_ => _.Description.IgnoreCaseEquals(relationship.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }

            if ((relationship.FromEvent != null && relationship.ToEvent == null)
                || (relationship.FromEvent == null && relationship.ToEvent != null))
            {
                if(relationship.FromEvent == null)
                    yield return new ValidationError("fromEvent", "Both 'To Event' and 'From Event' fields must either be entered or left blank.");

                if (relationship.ToEvent == null)
                    yield return new ValidationError("toEvent", "Both 'To Event' and 'From Event' fields must either be entered or left blank.");
            }
        }

        public dynamic Delete(string relationshipId)
        {
            try
            {
                if (_dbContext.Set<ValidRelationship>().Any(vr => vr.RelationshipCode == relationshipId || vr.ReciprocalRelationshipCode == relationshipId))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                if (_dbContext.Set<RelatedCase>().Any(rc => rc.Relationship == relationshipId))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<CaseRelation>()
                        .Single(_ => _.Relationship == relationshipId);

                    _dbContext.Set<CaseRelation>().Remove(model);

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
    }

}
