using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class CaseTypeListItemBuilder : IBuilder<CaseTypeListItem>
    {
        public string CaseTypeKey { get; set; }

        public string CaseTypeDescription { get; set; }

        public CaseTypeListItem Build()
        {
            return new CaseTypeListItem
            {
                CaseTypeKey = CaseTypeKey,
                CaseTypeDescription = CaseTypeDescription
            };
        }
    }
}