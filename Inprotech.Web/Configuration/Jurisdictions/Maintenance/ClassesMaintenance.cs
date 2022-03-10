using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IClassesMaintenance
    {
        void Save(Delta<ClassesMaintenanceModel> statusFlagsDelta);

        IEnumerable<ValidationError> Validate(Delta<ClassesMaintenanceModel> delta);
    }

    public class ClassesMaintenance : IClassesMaintenance
    {
        readonly IDbContext _dbContext;

        public ClassesMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Save(Delta<ClassesMaintenanceModel> classesDelta)
        {
            HasClassOrPropertyChanged(classesDelta.Updated);
            UpdateSequence(classesDelta);
            DeleteClasses(classesDelta.Deleted.Union(classesDelta.Updated.Where(_ => _.IsPrimaryChanged)).ToList());
            AddClasses(classesDelta.Added.Union(classesDelta.Updated.Where(_ => _.IsPrimaryChanged)).ToList());
            UpdateClasses(classesDelta.Updated.Where(_ => !_.IsPrimaryChanged).ToList());
        }

        void HasClassOrPropertyChanged(ICollection<ClassesMaintenanceModel> updatedClasses)
        {
            if (!updatedClasses.Any())
                return;

            foreach (var item in updatedClasses)
            {
                var tmclass = _dbContext.Set<TmClass>().First(_ => _.Id == item.Id);
                if (tmclass.PropertyType == item.PropertyType && tmclass.Class == item.Class) continue;
                item.IsPrimaryChanged = true;
            }
        }

        void UpdateSequence(Delta<ClassesMaintenanceModel> classesDelta)
        {
            var combinedDelta = classesDelta.Added.Union(classesDelta.Updated.Where(_ => _.IsPrimaryChanged)).ToList();
            if (combinedDelta.Count == 0)
                return;

            var groupedClasses = combinedDelta.GroupBy(_ => $"{_.Class}_{_.PropertyType}").ToDictionary(_ => _.Key, _ => _.ToList());

            foreach (var kvp in groupedClasses)
            {
                var item = kvp.Value[0];
                var existingClasses = _dbContext.Set<TmClass>().Where(_ => _.CountryCode == item.CountryId && _.Class == item.Class && _.PropertyType == item.PropertyType).ToArray();
                var sequence = existingClasses.Any() ? existingClasses.Max(_ => _.SequenceNo) : -1;

                foreach (var a in kvp.Value)
                {
                    a.SequenceNo = ++sequence;
                }
            }
        }

        void AddClasses(ICollection<ClassesMaintenanceModel> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<TmClass>();

            foreach (var item in added)
            {
                var model = new TmClass(item.CountryId, item.Class, item.PropertyType, item.SequenceNo)
                {
                    IntClass = item.IntClasses.Sort(),
                    SubClass = string.IsNullOrEmpty(item.SubClass) ? null : item.SubClass,
                    Notes = item.Notes,
                    Heading = item.Description,
                    EffectiveDate = item.EffectiveDate
                };
                all.Add(model);
            }
        }

        void UpdateClasses(ICollection<ClassesMaintenanceModel> updated)
        {
            if (!updated.Any()) return;

            foreach (var item in updated)
            {
                var data = _dbContext.Set<TmClass>().SingleOrDefault(_ => _.Id == item.Id);
                if (data == null) continue;

                data.SubClass = string.IsNullOrEmpty(item.SubClass) ? null : item.SubClass;
                data.IntClass = item.IntClasses.Sort();
                data.EffectiveDate = item.EffectiveDate;
                data.Notes = item.Notes;
                data.Heading = item.Description;
            }
        }

        void DeleteClasses(ICollection<ClassesMaintenanceModel> deleted)
        {
            if (!deleted.Any()) return;

            var classesToDelete = deleted.Select(item => _dbContext.Set<TmClass>().SingleOrDefault(_ => _.Id == item.Id)).Where(item => item != null);
            _dbContext.RemoveRange(classesToDelete);
        }

        public IEnumerable<ValidationError> Validate(Delta<ClassesMaintenanceModel> delta)
        {
            if (delta == null) throw new ArgumentNullException(nameof(delta));

            var errorsList = new List<ValidationError>();

            var combinedDelta = delta.Added.Union(delta.Updated).ToList();

            if (combinedDelta.Any(IsDuplicate))
            {
                errorsList.Add(ValidationErrors.TopicError("classes", "Duplicate Class."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.Class)))
            {
                errorsList.Add(ValidationErrors.TopicError("classes", "Mandatory field was empty."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.PropertyType)))
            {
                errorsList.Add(ValidationErrors.TopicError("classes", "Mandatory field was empty."));
            }
            return errorsList;
        }

        bool IsDuplicate(ClassesMaintenanceModel model)
        {
            return _dbContext.Set<TmClass>().Any(_ => _.Class == model.Class && _.CountryCode == model.CountryId && _.PropertyType == model.PropertyType && _.SubClass == model.SubClass && _.Id != model.Id);
        }

    }

    public class ClassesMaintenanceModel
    {
        public int Id { get; set; }
        public bool IsPrimaryChanged { get; set; }
        public string Class { get; set; }
        public string PropertyType { get; set; }
        public string CountryId { get; set; }
        public string Description { get; set; }
        public int SequenceNo { get; set; }
        public string SubClass { get; set; }
        public string IntClasses { get; set; }
        public string Notes { get; set; }
        public DateTime? EffectiveDate { get; set; }
    }
}
