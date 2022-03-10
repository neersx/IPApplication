using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class StatusListItemBuilder : IBuilder<ValidStatusListItem>
    {
        public short StatusKey { get; set; }

        public string StatusDescription { get; set; }

        public bool? IsRenewal { get; set; }

        public bool? IsPending { get; set; }

        public bool? IsDead { get; set; }

        public bool? IsRegistered { get; set; }

        public string CountryKey { get; set; }

        public bool IsDefaultCountry { get; set; }

        public string PropertyTypeKey { get; set; }

        public string CaseTypeKey { get; set; }

        public ValidStatusListItem Build()
        {
            return new ValidStatusListItem
            {
                StatusKey = StatusKey,
                CountryKey = CountryKey,
                CaseTypeKey = CaseTypeKey,
                PropertyTypeKey = PropertyTypeKey,
                IsDefaultCountry = IsDefaultCountry,
                IsDead = IsDead,
                IsRenewal = IsRenewal
            };
        }
    }
}