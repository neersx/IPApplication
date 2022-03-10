using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IStateMaintenance
    {
        JurisdictionSaveResponseModel Save(Delta<StateMaintenanceModel> stateDelta);

        IEnumerable<ValidationError> Validate(Delta<StateMaintenanceModel> delta);
    }

    public class StateMaintenance : IStateMaintenance
    {
        readonly IDbContext _dbContext;

        public StateMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public JurisdictionSaveResponseModel Save(Delta<StateMaintenanceModel> stateDelta)
        {
            var response = new JurisdictionSaveResponseModel { TopicName = "states" };
            response.InUseItems = InUseEntities(stateDelta.Deleted);
            DeleteState(stateDelta.Deleted.RemoveInUseItems((List<StateMaintenanceModel>)response.InUseItems));
            AddState(stateDelta.Added);
            UpdateState(stateDelta.Updated);

            return response;
        }

        List<StateMaintenanceModel> InUseEntities(ICollection<StateMaintenanceModel> deleted)
        {
            var inUseCollection = new List<StateMaintenanceModel>();
            if (!deleted.Any()) return inUseCollection;

            inUseCollection.AddRange(deleted.Where(item => _dbContext.Set<Address>().Any(_ => _.State == item.Code)));
            return inUseCollection;
        }

        void AddState(ICollection<StateMaintenanceModel> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<State>();

            foreach (var item in added)
            {
                var model = new State(item.Code, item.Name, item.CountryId);
                all.Add(model);
            }
        }

        void UpdateState(ICollection<StateMaintenanceModel> updated)
        {
            if (!updated.Any()) return;

            foreach (var item in updated)
            {
                var data = _dbContext.Set<State>().SingleOrDefault(_ => _.Id == item.Id && _.CountryCode == item.CountryId);
                if (data == null) continue;
                data.Code = item.Code;
                data.Name = item.Name;
            }
        }

        void DeleteState(ICollection<StateMaintenanceModel> deleted)
        {
            if (!deleted.Any()) return;

            var stateToDelete = deleted.Select(item => _dbContext.Set<State>().SingleOrDefault(_ => _.Id == item.Id && _.CountryCode == item.CountryId)).Where(item => item != null);
            _dbContext.RemoveRange(stateToDelete);
        }

        public IEnumerable<ValidationError> Validate(Delta<StateMaintenanceModel> delta)
        {
            if (delta == null) throw new ArgumentNullException(nameof(delta));

            var errorsList = new List<ValidationError>();

            var combinedDelta = delta.Added.Union(delta.Updated).ToList();
            if (combinedDelta.Any(IsDuplicate))
            {
                errorsList.Add(ValidationErrors.TopicError("states", "Duplicate State Code."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.Name)))
            {
                errorsList.Add(ValidationErrors.TopicError("states", "Mandatory field State Name was empty."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.Code)))
            {
                errorsList.Add(ValidationErrors.TopicError("states", "Mandatory field State Code was empty."));
            }
            return errorsList;
        }

        bool IsDuplicate(StateMaintenanceModel model)
        {
            return _dbContext.Set<State>().Any(_ => _.Code == model.Code && _.CountryCode == model.CountryId && _.Id != model.Id);
        }

    }

    public class StateMaintenanceModel
    {
        public int? Id { get; set; }

        public string CountryId { get; set; }

        public string Code { get; set; }

        public string Name { get; set; }

        public string TranslatedName { get; set; }
    }

    public static class StateItemExtension
    {
        public static ICollection<StateMaintenanceModel> RemoveInUseItems(this ICollection<StateMaintenanceModel> deleted, List<StateMaintenanceModel> inUseItems)
        {
            foreach (var item in inUseItems)
            {
                deleted.Remove(item);
            }
            return deleted;
        }
    }
}
