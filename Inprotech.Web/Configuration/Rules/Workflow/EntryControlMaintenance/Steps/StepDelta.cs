using System;
using System.Linq;
using InprotechKaizen.Model.Configuration.Screens;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class StepDelta : IFlattenTopic, ICloneable
    {
        public StepDelta()
        {
            Categories = new StepCategory[0];
        }

        public StepDelta(string name, string type)
        {
            Name = name;
            ScreenType = type;
            Categories = new StepCategory[0];
        }

        public StepDelta(string name, string type, string categoryCode, dynamic categoryValue)
        {
            Name = name;
            ScreenType = type;
            Categories = new[]
                         {
                             new StepCategory(categoryCode, categoryValue)
                         };
        }

        public StepDelta(string name, string type, string categoryCode1, dynamic categoryValue1, string categoryCode2, dynamic categoryValue2)
        {
            Name = name;
            ScreenType = type;
            Categories = new[]
                         {
                             new StepCategory(categoryCode1, categoryValue1),
                             new StepCategory(categoryCode2, categoryValue2)
                         };
        }

        public int? Id { get; set; }

        [JsonProperty(PropertyName = "ScreenName")]
        public string Name { get; set; }

        public string ScreenType { get; set; }

        public string Title { get; set; }

        public string ScreenTip { get; set; }

        public bool IsMandatory { get; set; }

        public string RelativeId { get; set; }

        public string NewItemId { get; set; }

        public short? OverrideRowPosition { get; set; }

        public StepCategory[] Categories { get; set; }

        [JsonIgnore]
        public string Filter1Name => Categories.ElementAtOrDefault(0)?.FilterName();

        [JsonIgnore]
        public string Filter2Name => Categories.ElementAtOrDefault(1)?.FilterName();

        [JsonIgnore]
        public string Filter1Value => Categories.ElementAtOrDefault(0)?.FilterValue();

        [JsonIgnore]
        public string Filter2Value => Categories.ElementAtOrDefault(1)?.FilterValue();

        public object Clone()
        {
            var newObject = (StepDelta) MemberwiseClone();
            newObject.Categories = Categories.Select(_ => (StepCategory)_.Clone()).ToArray();

            return newObject;
        }
    }
}