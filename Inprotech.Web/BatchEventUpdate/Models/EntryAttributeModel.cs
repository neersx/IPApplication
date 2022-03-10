using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class EntryAttributeModel
    {
        public EntryAttributeModel(short? entryAttributeValue)
        {
            var entryAttribute = entryAttributeValue.AsEntryAttribute();

            IsVisible = entryAttribute != EntryAttribute.Hide;
            IsMandatory = entryAttribute == EntryAttribute.EntryMandatory;
            IsOptional = entryAttribute == EntryAttribute.EntryOptional;
            IsDisplayOnly = entryAttribute == EntryAttribute.DisplayOnly;

            ShouldDefaultToSystemDate = entryAttributeValue.HasValue
                                        && entryAttribute == EntryAttribute.DefaultToSystemDate;
        }

        public bool IsVisible { get; set; }

        public bool IsOptional { get; set; }

        public bool IsMandatory { get; set; }

        public bool IsDisplayOnly { get; set; }

        public bool ShouldDefaultToSystemDate { get; set; }
    }
}