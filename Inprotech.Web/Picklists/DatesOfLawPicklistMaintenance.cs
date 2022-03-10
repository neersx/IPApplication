using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using EntityModel = InprotechKaizen.Model.ValidCombinations;
namespace Inprotech.Web.Picklists
{
    public interface IDateOfLawPicklistMaintenance
    {
        dynamic Save(DefaultDateOfLaw dateOfLaw, Delta<AffectedActions> affectedActions, Operation operation);
        dynamic Delete(int dateOfLawId);
    }

    public class DateOfLawPicklistMaintenance : IDateOfLawPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public DateOfLawPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        }

        public dynamic Save(DefaultDateOfLaw dateOfLaw, Delta<AffectedActions> affectedActions, Operation operation)
        {
            if (dateOfLaw == null) throw new ArgumentNullException(nameof(dateOfLaw));

            var validationErrors = Validate(dateOfLaw, affectedActions, operation).ToArray();
            if (validationErrors.Any())
            {
                return validationErrors.AsErrorResponse();
            }

            var result = Save(dateOfLaw, operation);
            if (affectedActions == null) return result;
            var errors = new List<ValidationError>();
            errors.AddRange(ValidateAffectedActions(dateOfLaw, affectedActions));
            if (errors.Any()) return errors;
            SaveAffectedActions(affectedActions);
            return new
            {
                Result = "success"
            };
        }

        public dynamic Delete(int dateOfLawId)
        {
            try
            {
                var dateOfLaw = _dbContext.Set<EntityModel.DateOfLaw>().Single(_ => _.Id == dateOfLawId);
                if (_dbContext.Set<Criteria>().Any(c => c.DateOfLaw == dateOfLaw.Date
                                                                         && c.PropertyTypeId == dateOfLaw.PropertyTypeId
                                                                         && c.CountryId == dateOfLaw.CountryId))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {
                    var dateOfLaws = _dbContext
                        .Set<EntityModel.DateOfLaw>()
                        .Where(_ => _.Date == dateOfLaw.Date && _.PropertyType.Code == dateOfLaw.PropertyTypeId && _.CountryId == dateOfLaw.CountryId);

                    _dbContext.RemoveRange(dateOfLaws);

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

        dynamic Save(DefaultDateOfLaw dateOfLaw, Operation operation)
        {
            using (var tcs = _dbContext.BeginTransaction())
            {
                short sequence = 0;
                if (operation == Operation.Add)
                {
                    var results = _dbContext.Set<EntityModel.DateOfLaw>().Where(_ => _.Date == dateOfLaw.Date && _.PropertyType.Code == dateOfLaw.PropertyType.Code
                                                                                     && _.CountryId == dateOfLaw.Jurisdiction.Code);
                    if (results.Any())
                    {
                        sequence = results.Max(_ => _.SequenceNo);
                        ++sequence;
                    }
                }

                var model = operation == Operation.Update
                    ? _dbContext.Set<EntityModel.DateOfLaw>()
                                .Single(_ => _.Id == dateOfLaw.Key && string.IsNullOrEmpty(_.RetroActionId))
                    : _dbContext.Set<EntityModel.DateOfLaw>()
                                .Add(new EntityModel.DateOfLaw{SequenceNo = sequence});

                if (operation == Operation.Add)
                {
                    model.CountryId = dateOfLaw.Jurisdiction.Code;
                    model.PropertyTypeId = dateOfLaw.PropertyType.Code;
                    model.Date = dateOfLaw.Date;
                }
                model.RetroEventId = dateOfLaw.DefaultRetrospectiveEvent?.Key;
                model.LawEventId = dateOfLaw.DefaultEventForLaw?.Key;

                _dbContext.SaveChanges();
                tcs.Complete();

                return new
                {
                    Result = "success",
                    Key = model.Id
                };
            }
        }

        void SaveAffectedActions(Delta<AffectedActions> affectedActions)
        {
            using (var tcs = _dbContext.BeginTransaction())
            {
                DeleteAffectedActions(affectedActions.Deleted);
                AddAffectedActions(affectedActions.Added);
                UpdateAffectedActions(affectedActions.Updated);
                _dbContext.SaveChanges();
                tcs.Complete();
            }
        }

        void DeleteAffectedActions(ICollection<AffectedActions> deleted)
        {
            if (!deleted.Any()) return;
            var dateOfLaws = deleted.Select(item => _dbContext.Set<EntityModel.DateOfLaw>().Single(_ => _.Id == item.Key));
            _dbContext.RemoveRange(dateOfLaws);
        }

        void AddAffectedActions(ICollection<AffectedActions> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<EntityModel.DateOfLaw>();
            var firstDateOfLaw = added.First();
            var sequence = all.Where(_ => _.Date == firstDateOfLaw.Date && _.PropertyType.Code == firstDateOfLaw.PropertyType.Code && _.CountryId == firstDateOfLaw.Jurisdiction.Code
            ).Max(_ => _.SequenceNo);
            foreach (var item in added)
            {
                sequence++;
                var countryGroupSaveModel = new EntityModel.DateOfLaw
                {
                    CountryId = item.Jurisdiction.Code,
                    PropertyTypeId = item.PropertyType.Code,
                    Date = item.Date,
                    SequenceNo = sequence,
                    RetroActionId = item.RetrospectiveAction?.Code,
                    RetroEventId = item.DefaultRetrospectiveEvent?.Key,
                    LawEventId = item.DefaultEventForLaw?.Key
                };
                all.Add(countryGroupSaveModel);
            }
        }

        void UpdateAffectedActions(ICollection<AffectedActions> updated)
        {
            if (!updated.Any()) return;

            foreach (var item in updated)
            {
                var data = _dbContext.Set<EntityModel.DateOfLaw>().SingleOrDefault(_ => _.Id == item.Key);
                if (data == null) throw new ArgumentException("Invalid Record");

                data.RetroActionId = item.RetrospectiveAction?.Code;
                data.RetroEventId = item.DefaultRetrospectiveEvent?.Key;
                data.LawEventId = item.DefaultEventForLaw?.Key;
            }
        }

        IEnumerable<ValidationError> Validate(DefaultDateOfLaw dateOfLaw, Delta<AffectedActions> affectedActions, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.DateOfLaw>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != dateOfLaw.Key))
            {
                throw new ArgumentException("Unable to retrieve Date of Law for update.");
            }

            if (affectedActions != null)
            {
                var allAffectedActions = affectedActions.Added.Union(affectedActions.Updated);
                if (allAffectedActions.Any(_ => _.Date.Equals(dateOfLaw.Date) && _.Jurisdiction.Code.IgnoreCaseEquals(dateOfLaw.Jurisdiction.Code)
                                       && _.PropertyType.Code.IgnoreCaseEquals(dateOfLaw.PropertyType.Code) && _.RetrospectiveAction == null
                                       && _.DefaultEventForLaw.Key == dateOfLaw.DefaultEventForLaw.Key))
                {
                    yield return ValidationErrors.SetCustomError("dateOfLaw", "field.errors.invaliddateoflaw", "field.errors.notunique", true);
                }
                var updatedArray = affectedActions.AllUpdatedAndDeletedDeltas().Select(_ => _.Key).ToArray();
                all = all.Where(_ => !updatedArray.Contains(_.Id)).ToArray();
            }

            foreach (var validationError in CommonValidations.Validate(dateOfLaw))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != dateOfLaw.Key).ToArray() : all;
            if (others.Any(_ => _.Date.Equals(dateOfLaw.Date) && _.CountryId.IgnoreCaseEquals(dateOfLaw.Jurisdiction.Code)
                && _.PropertyTypeId.IgnoreCaseEquals(dateOfLaw.PropertyType.Code) && _.RetroAction == null 
                && _.LawEvent.Id == dateOfLaw.DefaultEventForLaw.Key))
            {
                yield return ValidationErrors.SetCustomError("dateOfLaw", "field.errors.invaliddateoflaw", "field.errors.notunique", true);
            }
        }

        public IEnumerable<ValidationError> ValidateAffectedActions(DefaultDateOfLaw dateOfLaw, Delta<AffectedActions> affectedActions)
        {
            var errors = new List<ValidationError>();

            foreach (var added in affectedActions.Added)
            {
                errors.AddRange(ValidateAffectedActions(added, Operation.Add));
            }

            foreach (var updated in affectedActions.Updated)
            {
                errors.AddRange(ValidateAffectedActions(updated, Operation.Update));
            }

            return errors;
        }

        IEnumerable<ValidationError> ValidateAffectedActions(AffectedActions affectedAction, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(affectedAction))
                yield return validationError;

            if (IsDuplicate(affectedAction, operation))
            {
                yield return ValidationErrors.SetCustomError("dateOfLaw", "row.field.errors.notunique", null, true);
            }
        }

        bool IsDuplicate(AffectedActions affectedAction, Operation operation)
        {
            var all = operation == Operation.Add ? _dbContext.Set<EntityModel.DateOfLaw>() : _dbContext.Set<EntityModel.DateOfLaw>().Where(_ => _.Id != affectedAction.Key);

            if (affectedAction.DefaultEventForLaw == null) return false;

            var retroActionCode = affectedAction.RetrospectiveAction?.Code;

            return all.Any(_ => _.PropertyTypeId == affectedAction.PropertyType.Code && _.CountryId == affectedAction.Jurisdiction.Code && _.Date == affectedAction.Date
                                && ((_.RetroAction == null && retroActionCode == null) ||
                                    (_.RetroAction != null && _.RetroAction.Code == retroActionCode))
                                && _.LawEventId == affectedAction.DefaultEventForLaw.Key);
        }
    }
}
