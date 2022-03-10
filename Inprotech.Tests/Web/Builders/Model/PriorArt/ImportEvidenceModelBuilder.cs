using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Components.Cases.PriorArt;

namespace Inprotech.Tests.Web.Builders.Model.PriorArt
{
    public class ImportEvidenceModelBuilder : IBuilder<ImportEvidenceModel>
    {
        public bool? IsComplete { get; set; }

        public ImportEvidenceModel Build()
        {
            return new ImportEvidenceModel
            {
                Evidence = new Match {IsComplete = IsComplete ?? true}
            };
        }
    }
}