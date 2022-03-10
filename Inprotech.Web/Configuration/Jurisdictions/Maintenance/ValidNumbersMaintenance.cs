using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IValidNumbersMaintenance
    {
        void Save(Delta<ValidNumbersMaintenanceModel> validNumbersDelta);

        IEnumerable<ValidationError> Validate(Delta<ValidNumbersMaintenanceModel> delta);
    }

    public class ValidNumbersMaintenance : IValidNumbersMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public ValidNumbersMaintenance(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public void Save(Delta<ValidNumbersMaintenanceModel> validNumbersDelta)
        {
            DeleteValidNumbers(validNumbersDelta.Deleted);
            AddValidNumbers(validNumbersDelta.Added);
            UpdateValidNumbers(validNumbersDelta.Updated);
        }

        void AddValidNumbers(ICollection<ValidNumbersMaintenanceModel> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<CountryValidNumber>();

            foreach (var item in added)
            {
                var id = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.ValidateNumbers);
                var model = new CountryValidNumber(id, item.PropertyTypeCode, item.NumberTypeCode, item.CountryCode, item.Pattern, item.DisplayMessage)
                {
                    ValidFrom = item.ValidFrom,
                    AdditionalValidationId = item.AdditionalValidationId,
                    CaseTypeId = item.CaseTypeCode,
                    CaseCategoryId = item.CaseCategoryCode,
                    SubTypeId = item.SubTypeCode,
                    WarningFlag = item.WarningFlag ? 1 : 0
                };
                all.Add(model);
            }
        }

        void UpdateValidNumbers(ICollection<ValidNumbersMaintenanceModel> updated)
        {
            if (!updated.Any()) return;

            foreach (var item in updated)
            {
                var data = _dbContext.Set<CountryValidNumber>().SingleOrDefault(_ => _.Id == item.Id);
                if (data == null) continue;

                data.ValidFrom = item.ValidFrom;
                data.AdditionalValidationId = item.AdditionalValidationId;
                data.PropertyId = item.PropertyTypeCode;
                data.NumberTypeId = item.NumberTypeCode;
                data.Pattern = item.Pattern;
                data.ErrorMessage = item.DisplayMessage;
                data.AdditionalValidationId = item.AdditionalValidationId;
                data.CaseTypeId = item.CaseTypeCode;
                data.CaseCategoryId = item.CaseCategoryCode;
                data.SubTypeId = item.SubTypeCode;
                data.WarningFlag = item.WarningFlag ? 1 : 0;
            }
        }

        void DeleteValidNumbers(ICollection<ValidNumbersMaintenanceModel> deleted)
        {
            if (!deleted.Any()) return;

            var validNumbersToDelete = deleted.Select(item => _dbContext.Set<CountryValidNumber>().SingleOrDefault(_ => _.Id == item.Id)).Where(item => item != null);
            _dbContext.RemoveRange(validNumbersToDelete);
        }

        public IEnumerable<ValidationError> Validate(Delta<ValidNumbersMaintenanceModel> delta)
        {
            if (delta == null) throw new ArgumentNullException(nameof(delta));

            var errorsList = new List<ValidationError>();

            var combinedDelta = delta.Added.Union(delta.Updated).ToList();

            if (combinedDelta.Any(IsDuplicate))
            {
                errorsList.Add(ValidationErrors.TopicError("validNumbers", "Duplicate Valid Numbers."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.PropertyTypeCode)))
            {
                errorsList.Add(ValidationErrors.TopicError("validNumbers", "Mandatory field was empty."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.NumberTypeCode)))
            {
                errorsList.Add(ValidationErrors.TopicError("validNumbers", "Mandatory field was empty."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.DisplayMessage)))
            {
                errorsList.Add(ValidationErrors.TopicError("validNumbers", "Mandatory field was empty."));
            }
            if (combinedDelta.Any(_ => string.IsNullOrEmpty(_.Pattern)))
            {
                errorsList.Add(ValidationErrors.TopicError("validNumbers", "Mandatory field was empty."));
            }
            return errorsList;
        }

        bool IsDuplicate(ValidNumbersMaintenanceModel model)
        {
            return _dbContext.Set<CountryValidNumber>().Any(_ => _.NumberTypeId == model.NumberTypeCode && _.CountryId == model.CountryCode && _.PropertyId == model.PropertyTypeCode && _.ValidFrom == model.ValidFrom && _.Id != model.Id);
        }

    }

    public class ValidNumbersMaintenanceModel
    {
        public int Id { get; set; }
        public string NumberTypeCode { get; set; }
        public string PropertyTypeCode { get; set; }
        public string CaseTypeCode { get; set; }
        public string CaseCategoryCode { get; set; }
        public string SubTypeCode { get; set; }
        public string CountryCode { get; set; }
        public string Pattern { get; set; }
        public bool WarningFlag { get; set; }
        public string DisplayMessage { get; set; }
        public int? AdditionalValidationId { get; set; }
        public DateTime? ValidFrom { get; set; }
    }
}
