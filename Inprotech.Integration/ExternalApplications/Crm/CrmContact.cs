using System.Globalization;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    public class CrmContact
    {
        public CrmContact() { }

        public CrmContact(Name name, AssociatedName organisation, TableCode corresReceived, bool? correspondenceSent)
        {
            if (name != null)
            {
                NameId = name.Id;
                NameCode = name.NameCode;

                var nameStyle = name.NameStyle ?? (name.Nationality != null && name.Nationality.NameStyleId.HasValue ?
                    name.Nationality.NameStyleId.Value
                    : (int)NameStyles.FirstNameThenFamilyName);

                Name = name.Formatted((NameStyles)nameStyle);

                EmailAddress = name.MainEmail().FormattedOrNull();
                PhoneNumber = name.MainPhone().FormattedOrNull();
                Fax = name.MainFax().FormattedOrNull();
            }

            if (organisation != null)
            {
                OrganisationNameCode = organisation.Name.NameCode;
                OrganisationName = organisation.Name.FormattedNameOrNull();
                Department = organisation.PositionCategory != null ? organisation.PositionCategory.Name : string.Empty;
            }
            else
            {
                OrganisationNameCode = string.Empty;
                OrganisationName = string.Empty;
                Department = string.Empty;
            }

            if (corresReceived != null)
            {
                ResponseCode = corresReceived.Id.ToString(CultureInfo.InvariantCulture);
                ResponseDescription = corresReceived.Name;
            }
            else
            {
                ResponseCode = string.Empty;
                ResponseDescription = string.Empty;
            }

            CorrespondenceSent = correspondenceSent ?? false;
        }

        public int NameId { get; set; }
        public string NameCode { get; set; }
        public string Name { get; set; }
        public string OrganisationName { get; set; }
        public string OrganisationNameCode { get; set; }
        public string Department { get; set; }
        public string EmailAddress { get; set; }
        public string PhoneNumber { get; set; }
        public string Fax { get; set; }
        public bool CorrespondenceSent { get; set; }
        public string ResponseCode { get; set; }
        public string ResponseDescription { get; set; }
        public NameAttributes NameAttributes { get; set; }

    }
}
