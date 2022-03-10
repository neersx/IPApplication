using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IStatusFlagsMaintenance
    {
        void Save(Delta<StatusFlagsMaintenanceModel> statusFlagsDelta);

        IEnumerable<ValidationError> Validate(Delta<StatusFlagsMaintenanceModel> delta);
    }

    public class StatusFlagsMaintenance : IStatusFlagsMaintenance
    {
        readonly IDbContext _dbContext;

        public StatusFlagsMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Save(Delta<StatusFlagsMaintenanceModel> statusFlagsDelta)
        {
            AddStatusFlags(statusFlagsDelta.Added);
            UpdateStatusFlags(statusFlagsDelta.Updated);
            DeleteStatusFlags(statusFlagsDelta.Deleted);
        }

        void AddStatusFlags(ICollection<StatusFlagsMaintenanceModel> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<CountryFlag>();
            var countryCode = added.First().CountryId;
            var existingStatusFlags = _dbContext.Set<CountryFlag>().Where(_ => _.CountryId == countryCode).ToArray();
            var count = 1;

            foreach (var item in added)
            {
                var flagNumber = existingStatusFlags.Any() ? existingStatusFlags.Max(_ => _.FlagNumber) * (int)Math.Pow(2, count) : (int)Math.Pow(2, count-1);

                var model = new CountryFlag(item.CountryId, flagNumber, item.Name)
                {
                    AllowNationalPhase = item.AllowNationalPhase ? 1m : 0m,
                    RestrictRemoval = item.RestrictRemoval ? 1m : 0m,
                    Status = item.Status,
                    ProfileName = item.ProfileName
                };
                all.Add(model);
                count++;
            }
        }

        void UpdateStatusFlags(ICollection<StatusFlagsMaintenanceModel> updated)
        {
            if(!updated.Any()) return;

            foreach (var item in updated)
            {
                var data = _dbContext.Set<CountryFlag>().SingleOrDefault(_ => _.FlagNumber == item.Id && _.CountryId == item.CountryId);
                if (data == null) continue;
                data.Status = item.Status;
                data.Name = item.Name;
                data.ProfileName = item.ProfileName;
                data.AllowNationalPhase = item.AllowNationalPhase ? 1m : 0m;
                data.RestrictRemoval = item.RestrictRemoval ? 1m : 0m;
            }
        }

        void DeleteStatusFlags(ICollection<StatusFlagsMaintenanceModel> deleted)
        {
            if (!deleted.Any()) return;

            var statusFlagsToDelete = deleted.Select(item => _dbContext.Set<CountryFlag>().SingleOrDefault(_ => _.FlagNumber == item.Id && _.CountryId == item.CountryId)).Where(item => item != null);
            _dbContext.RemoveRange(statusFlagsToDelete);
        }

        public IEnumerable<ValidationError> Validate(Delta<StatusFlagsMaintenanceModel> delta)
        {
            if (delta == null) throw new ArgumentNullException(nameof(delta));

            var errorsList = new List<ValidationError>();

            var combinedDelta = delta.Added.Union(delta.Updated).ToList();
            if (combinedDelta.Any(IsDuplicate))
            {
                errorsList.Add(ValidationErrors.TopicError("statusflags", "Duplicate Designation Stage."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.Name)))
            {
                errorsList.Add(ValidationErrors.TopicError("statusflags", "Mandatory field was empty."));
            }
            if (combinedDelta.Any(_ => !Enum.IsDefined(typeof(KnownRegistrationStatus), _.Status)))
            {
                errorsList.Add(ValidationErrors.TopicError("statusflags", "Invalid Status value."));
            }
            return errorsList;
        }

        bool IsDuplicate(StatusFlagsMaintenanceModel model)
        {
            return _dbContext.Set<CountryFlag>().Any(_ => _.Name == model.Name && _.CountryId == model.CountryId && _.FlagNumber != model.Id);
        }

    }

    public class StatusFlagsMaintenanceModel
    {
        public int? Id { get; set; }

        public string CountryId { get; set; }

        public string Name { get; set; }

        public bool RestrictRemoval { get; set; }

        public bool AllowNationalPhase { get; set; }

        public string ProfileName { get; set; }

        public int Status { get; set; }
    }
}
