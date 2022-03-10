namespace InprotechKaizen.Model.Components.Cases
{
    public class StatusListItem
    {
        public short StatusKey { get; set; }

        public string StatusDescription { get; set; }

        public bool? IsRenewal { get; set; }

        public bool? IsPending { get; set; }

        public bool? IsDead { get; set; }

        public bool? IsRegistered { get; set; }

        public bool IsConfirmationRequired { get; set; }
    }

    public class ValidStatusListItem : StatusListItem
    {
        public string CountryKey { get; set; }

        public bool IsDefaultCountry { get; set; }

        public string PropertyTypeKey { get; set; }

        public string CaseTypeKey { get; set; }
    }
}