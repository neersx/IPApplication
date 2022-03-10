using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using PropertyType = Inprotech.Web.Picklists.PropertyType;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface ITextsMaintenance
    {
        void Save(Delta<TextsModel> countryGroups);
        IEnumerable<ValidationError> Validate(Delta<TextsModel> jurisdictionTexts);

    }

    public class TextsMaintenance : ITextsMaintenance
    {
        readonly IDbContext _dbContext;

        public TextsMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Save(Delta<TextsModel> texts)
        {
            AddJurisdictionTexts(texts.Added);
            UpdateJurisdictionTexts(texts.Updated);
            DeleteJurisdictionTexts(texts.Deleted);
        }

        void AddJurisdictionTexts(ICollection<TextsModel> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<CountryText>();

            var count = 0;
            foreach (var item in added)
            {
                var textType = _dbContext.Set<TableCode>().SingleOrDefault(_ => _.Id == item.TextType.Key);

                var propertyType = item.PropertyType != null ? _dbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().SingleOrDefault(_ => _.Code == item.PropertyType.Code) : null;

                var existingJurisdictionText = _dbContext.Set<CountryText>().Where(_ => _.CountryId == item.CountryCode && _.TextId == item.TextType.Key);

                var newSequenceId = existingJurisdictionText.Any() ? existingJurisdictionText.Max(_ => _.SequenceId) + 1 : count;

                var jurisdictionTextsSaveModel = new CountryText(item.CountryCode, textType, propertyType)
                {
                    Text = item.Text,
                    TextId = item.TextType.TypeId,
                    SequenceId = (short)newSequenceId
                };
                count++;

                all.Add(jurisdictionTextsSaveModel);
            }
        }

        void UpdateJurisdictionTexts(ICollection<TextsModel> updated)
        {
            if (!updated.Any()) return;

            foreach (var item in updated)
            {
                var data = _dbContext.Set<CountryText>().SingleOrDefault(_ => _.CountryId == item.CountryCode && _.TextId == item.TextType.Key && _.SequenceId == item.SequenceId);
                if (data != null)
                {
                    data.Text = item.Text;
                    data.PropertyType = item.PropertyType?.Code;
                }
            }
        }

        void DeleteJurisdictionTexts(ICollection<TextsModel> deleted)
        {
            if (!deleted.Any()) return;
            var jurisdictionTexts = deleted.Select(item => _dbContext.Set<CountryText>().Single(_ => _.CountryId == item.CountryCode && _.TextId == item.TextType.Key && _.SequenceId == item.SequenceId));

            _dbContext.RemoveRange(jurisdictionTexts);
        }

        public IEnumerable<ValidationError> Validate(Delta<TextsModel> jurisdicitonTexts)
        {
            var errors = new List<ValidationError>();

            foreach (var added in jurisdicitonTexts.Added)
            {
                errors.AddRange(ValidateJurisdictionTexts(added, Operation.Add));
            }

            foreach (var updated in jurisdicitonTexts.Updated)
            {
                errors.AddRange(ValidateJurisdictionTexts(updated, Operation.Update));
            }

            return errors;
        }

        IEnumerable<ValidationError> ValidateJurisdictionTexts(TextsModel textsModel, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(textsModel))
                yield return validationError;

            if (textsModel.TextType == null)
                yield return ValidationErrors.TopicError("texts", ConfigurationResources.EmpltyJurisdictionTexts);

            if (textsModel.TextType != null && IsDuplicate(textsModel, operation))
                yield return ValidationErrors.TopicError("texts", ConfigurationResources.DuplicateJurisdictionTexts);
        }

        bool IsDuplicate(TextsModel textsModel, Operation operation)
        {
            var all = operation == Operation.Add ? _dbContext.Set<CountryText>() : _dbContext.Set<CountryText>().Where(_ => _.CountryId == textsModel.CountryCode && _.TextId == textsModel.TextType.Key && _.SequenceId != textsModel.SequenceId);

            var propertyTypeCode = textsModel.PropertyType != null ? textsModel.PropertyType.Code : string.Empty;
            if (operation == Operation.Add)
            {
                if (all.Any(_ => _.CountryId == textsModel.CountryCode && _.TextId == textsModel.TextType.Key && _.PropertyType == propertyTypeCode))
                {
                    return true;
                }
            }
            if (operation == Operation.Update)
            {
                if (all.Any(_ => _.PropertyType == propertyTypeCode))
                {
                    return true;
                }
            }
            return false;
        }
    }

    public class TextsModel
    {
        public string CountryCode { get; set; }
        public PropertyType PropertyType { get; set; }
        public TableCodePicklistController.TableCodePicklistItem TextType { get; set; }
        public string Text { get; set; }
        public short SequenceId { get; set; }
    }
}
