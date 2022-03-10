using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class OtherDetailsTopicBuilder : ITopicBuilder
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDbContext _dbContext;

        public OtherDetailsTopicBuilder(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("otherDetails");
            var namesTopic = new OtherDetailsTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                FileLocationOperator = filterCriteria.GetAttributeOperatorValue("FileLocationKeys", "Operator"),
                FileLocation = GetFileLocations(filterCriteria),
                BayNoOperator = filterCriteria.GetAttributeOperatorValue("FileLocationBayNo", "Operator", Operators.StartsWith),
                BayNo = filterCriteria.GetStringValue("FileLocationBayNo"),
                IncludeInherited = filterCriteria.GetAttributeOperatorValue("StandingInstructions", "IncludeInherited") == "1",
                ForInstructionOperator = filterCriteria.GetAttributeOperatorValue("InstructionKey", "Operator"),
                Instruction = GetInstruction(filterCriteria),
                ForCharacteristicOperator = filterCriteria.GetAttributeOperatorValueForXPathElement("StandingInstructions/CharacteristicFlag","Operator", Operators.EqualTo),
                Characteristic = GetCharacteristic(filterCriteria),
                Letters = filterCriteria.GetXPathBooleanValue("QueueFlags/HasLettersOnQueue"),
                Charges = filterCriteria.GetXPathBooleanValue("QueueFlags/HasChargesOnQueue"),
                PolicingIncomplete = filterCriteria.GetStringValue("HasIncompletePolicing") == "1",
                GlobalNameChangeIncomplete = filterCriteria.GetStringValue("HasIncompleteNameChange") == "1",
                PurchaseOrderNoOperator = filterCriteria.GetAttributeOperatorValue("PurchaseOrderNo", "Operator", Operators.StartsWith),
                PurchaseOrderNo = filterCriteria.GetStringValue("PurchaseOrderNo"),
                EntitySize =GetEntitySize(filterCriteria.Element("EntitySize")?.GetIntegerNullableValue()),
                EntitySizeOperator=filterCriteria.GetAttributeOperatorValue("EntitySize", "Operator")
            };
            namesTopic.ForInstruction = namesTopic.Characteristic == null;
            topic.FormData = namesTopic;
            return topic;
        }

        IEnumerable<FileLocationPicklistController.FileLocationPicklistItem> GetFileLocations(XElement element)
        {
            var fileLocationKeys = element.GetStringValue("FileLocationKeys");
            if (string.IsNullOrEmpty(fileLocationKeys)) return null;

            var fileLocationArray = fileLocationKeys.StringToIntList(",");
            var culture = _preferredCultureResolver.Resolve();
            return _dbContext.Set<TableCode>()
                                    .Where(_ => _.TableTypeId == (short)TableTypes.FileLocation && fileLocationArray.Contains(_.Id))
                                    .Select(_ => new FileLocationPicklistController.FileLocationPicklistItem
                                    {
                                        Key =_.Id, 
                                        Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                                    });
        }

        Instruction GetInstruction(XElement filterCriteria)
        {
            var instruction = filterCriteria.GetStringValue("InstructionKey");
            if (string.IsNullOrEmpty(instruction)) return null;

            var culture = _preferredCultureResolver.Resolve();
            var result = _dbContext.Set<InprotechKaizen.Model.StandingInstructions.Instruction>().SingleOrDefault(_ => _.Id.ToString() == instruction);

            return result != null
                ? new Instruction
                {
                    Id = result.Id,
                    Description = DbFuncs.GetTranslation(result.Description, null, result.DescriptionTId, culture)
                }
                : null;
        }

        Characteristic GetCharacteristic(XElement filterCriteria)
        {
            var characteristic = filterCriteria.Element("StandingInstructions")?.GetStringValue("CharacteristicFlag");
            if (string.IsNullOrEmpty(characteristic)) return null;

            var culture = _preferredCultureResolver.Resolve();
            var result = _dbContext.Set<InprotechKaizen.Model.StandingInstructions.Characteristic>().SingleOrDefault(_ => _.Id.ToString() == characteristic);

            return result != null
                ? new Characteristic
                {
                    Id = result.Id,
                    Description = DbFuncs.GetTranslation(result.Description, null, result.DescriptionTId, culture)
                }
                : null;
        }

        KeyValuePair<int, string>? GetEntitySize(int? entitySize)
        {
            if (!entitySize.HasValue) return null;
            var es = _dbContext.Set<TableCode>().FirstOrDefault(_ => _.TableTypeId == (short)TableTypes.EntitySize && _.Id == entitySize.Value);

            if(es != null)
                return new KeyValuePair<int, string>(es.Id, DbFuncs.GetTranslation(es.Name, null, es.NameTId, _preferredCultureResolver.Resolve()));
            return null;
        }
    }

    public class OtherDetailsTopic
    {
        public int Id { get; set; }
        public string FileLocationOperator { get; set; }
        public IEnumerable<FileLocationPicklistController.FileLocationPicklistItem> FileLocation { get; set; }
        public string BayNoOperator { get; set; }
        public string BayNo { get; set; }
        public bool IncludeInherited { get; set; }
        public bool ForInstruction { get; set; }
        public string ForInstructionOperator { get; set; }
        public Instruction Instruction { get; set; }
        public string ForCharacteristicOperator { get; set; }
        public Characteristic Characteristic { get; set; }
        public bool Letters { get; set; }
        public bool Charges { get; set; }
        public bool PolicingIncomplete { get; set; }
        public bool GlobalNameChangeIncomplete { get; set; }
        public string PurchaseOrderNoOperator { get; set; }
        public string PurchaseOrderNo { get; set; }
        public string EntitySizeOperator { get; set; }
        public KeyValuePair<int, string>? EntitySize { get; set; }
    }
}
