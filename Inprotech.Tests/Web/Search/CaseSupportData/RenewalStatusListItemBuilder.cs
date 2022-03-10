using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Tests.Web.Search.CaseSupportData
{
    public class RenewalStatusListItemBuilder : IBuilder<ExternalRenewalStatusListItem>
    {
        public int StatusKey { get; set; }

        public string StatusDescription { get; set; }

        public bool? LiveFlag { get; set; }

        public bool? RegisteredFlag { get; set; }

        public ExternalRenewalStatusListItem Build()
        {
            return new ExternalRenewalStatusListItem
            {
                StatusKey = StatusKey,
                StatusDescription = StatusDescription ?? string.Empty,
                LiveFlag = LiveFlag,
                RegisteredFlag = RegisteredFlag
            };
        }
    }
}