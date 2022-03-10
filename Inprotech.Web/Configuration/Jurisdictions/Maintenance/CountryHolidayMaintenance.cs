using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface ICountryHolidayMaintenance
    {
        bool Save(CountryHolidayMaintenanceModel saveCountryHolidays);

        bool Delete(ICollection<CountryHolidayMaintenanceModel> deleted);
      
        IEnumerable<ValidationError> Validate(CountryHolidayMaintenanceModel model);

        bool IsDuplicate(CountryHolidayMaintenanceModel model);
    }

    public class CountryHolidayMaintenance : ICountryHolidayMaintenance
    {
        readonly IDbContext _dbContext;

        public CountryHolidayMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public bool Save(CountryHolidayMaintenanceModel saveCountryHolidays)
        {
            if (saveCountryHolidays == null) throw new ArgumentNullException(nameof(saveCountryHolidays));

            if (saveCountryHolidays.Id.HasValue)
            {
                Update(saveCountryHolidays);
            }
            else
            {
                Add(saveCountryHolidays);
            }
            _dbContext.SaveChanges();
            return true;
        }
        
        public bool Delete(ICollection<CountryHolidayMaintenanceModel> deleted)
        {
            if (!deleted.Any()) return false;

            var holidayToDelete = deleted.Select(item => _dbContext.Set<CountryHoliday>().SingleOrDefault(_ => _.Id == item.Id && _.CountryId == item.CountryId)).Where(item => item != null);
            _dbContext.RemoveRange(holidayToDelete);
            _dbContext.SaveChanges();
            return true;
        }
        
        void Add(CountryHolidayMaintenanceModel added)
        {
            var all = _dbContext.Set<CountryHoliday>();
            var countryHolidayModel = new CountryHoliday(added.CountryId, added.HolidayDate)
            {
                HolidayName = added.Holiday
            };
            all.Add(countryHolidayModel);
        }
        
        void Update(CountryHolidayMaintenanceModel updated)
        {
            var data = _dbContext.Set<CountryHoliday>().SingleOrDefault(_ => _.Id == updated.Id && _.CountryId == updated.CountryId);
            if (data == null) return;
            data.HolidayDate = updated.HolidayDate;
            data.HolidayName = updated.Holiday;
        }

        public IEnumerable<ValidationError> Validate(CountryHolidayMaintenanceModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var errorsList = new List<ValidationError>();
            
            if (IsDuplicate(model))
            {
                errorsList.Add(ValidationErrors.TopicError("businessDays", "Duplicate Holiday Date."));
            }
            if (string.IsNullOrEmpty(model.Holiday))
            {
                errorsList.Add(ValidationErrors.TopicError("businessDays", "Mandatory field Holiday was empty."));
            }
            return errorsList;
        }

        public bool IsDuplicate(CountryHolidayMaintenanceModel model)
        {
            return _dbContext.Set<CountryHoliday>().Any(_ => _.HolidayDate == model.HolidayDate && _.CountryId == model.CountryId && _.Id != model.Id);
        }
    }

    public class CountryHolidayMaintenanceModel
    {
        public int? Id { get; set; }

        public bool HasDateChanged { get; set; }

        public string CountryId { get; set; }

        public DateTime HolidayDate { get; set; }

        public string Holiday { get; set; }
    }
}
