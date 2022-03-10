
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Integration.Trinogy.Crm
{
    public class CrmContactName
    {
        public CrmContactName() {}

        public CrmContactName(Name name, AssociatedName organisation, TableCode corresReceived)
        {
            if (name != null)
            {
                NameKey = name.Id;
                NameCode = name.NameCode;
                Name = name.FormattedName;
            }
            if (organisation != null)
            {
                OrganisationNameCode = organisation.Name.NameCode;
                OrganisationName = organisation.Name.FormattedName;
                Department = organisation.PositionCategory != null ? organisation.PositionCategory.Name : null;
            }

            if (corresReceived != null)
            {
                ResponseCode = corresReceived.Id;
                ResponseDescription = corresReceived.Name;
            }
        }
        public int NameKey { get; set; }
        public string NameCode { get; set; }
        public string Name { get; set; }
        public string OrganisationName { get; set; }
        public string OrganisationNameCode { get; set; }
        public string Department { get; set; }
        public string EmailAddress { get; set; }
        public string PhoneNumber { get; set; }
        public bool CorrespondenceSent { get; set; }
        public int? ResponseCode { get; set; }
        public string ResponseDescription { get; set; }
    }
}
