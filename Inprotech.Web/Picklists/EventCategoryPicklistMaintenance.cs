using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    public interface IEventCategoryPicklistMaintenance
    {
        dynamic Save(EventCategory saveEventEventCategory, Operation operation);
        dynamic Delete(int eventCategoryId);
    }

    public class EventCategoryPicklistMaintenance : IEventCategoryPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _internalCodeGenerator;

        public EventCategoryPicklistMaintenance(IDbContext dbContext, ILastInternalCodeGenerator internalCodeGenerator)
        {
            _dbContext = dbContext;
            _internalCodeGenerator = internalCodeGenerator;
        }

        public dynamic Save(EventCategory saveEventEventCategory, Operation operation)
        {
            var validationErrors = Validate(saveEventEventCategory, operation).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();

            if (saveEventEventCategory == null) throw new ArgumentNullException(nameof(saveEventEventCategory));

            using (var tcs = _dbContext.BeginTransaction())
            {
                var model = operation == Operation.Update
                    ? _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Single(_ => _.Id == saveEventEventCategory.Key)
                    : _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Add(new InprotechKaizen.Model.Cases.Events.EventCategory((short) _internalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.EventCategory)));

                model.Name = saveEventEventCategory.Name;
                model.Description = saveEventEventCategory.Description;
                model.ImageId = saveEventEventCategory.ImageData.Key;

                _dbContext.SaveChanges();
                tcs.Complete();

                return new
                           {
                               Result = "success",
                               Key = model.Id
                           };
            }
        }

        public dynamic Delete(int eventCategoryId)
        {
            try
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<InprotechKaizen.Model.Cases.Events.EventCategory>()
                        .SingleOrDefault(_ => _.Id == eventCategoryId);
                    if (model == null) throw Exceptions.NotFound("No matching item found");

                    _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Remove(model);

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
                {
                    throw;
                }

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }
        IEnumerable<ValidationError> Validate(EventCategory saveEventCategory, Operation operation)
        {
            if (!Enum.IsDefined(typeof(Operation), operation)) throw new InvalidEnumArgumentException(nameof(operation), (int) operation, typeof(Operation));

            var all = _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().ToArray();

            if (operation == Operation.Update && all.All(v => v.Id != saveEventCategory.Key)) throw new ArgumentException("Unable to retrieve event category for update.");

            var imageDetail = _dbContext.Set<ImageDetail>().Single(v => v.ImageId == saveEventCategory.ImageData.Key);
            if (imageDetail.ImageStatus == null || imageDetail.ImageStatus != ProtectedTableCode.EventCategoryImageStatus)
                yield return ValidationErrors.SetError("imageDescription", "picklist.eventCategory.invalidImage");

            if (all.Any(v => v.Name == saveEventCategory.Name && v.Id != saveEventCategory.Key))
            {
                yield return ValidationErrors.NotUnique("name");
            }

            foreach (var validationError in CommonValidations.Validate(saveEventCategory))
                yield return validationError;
        }
    }
}
